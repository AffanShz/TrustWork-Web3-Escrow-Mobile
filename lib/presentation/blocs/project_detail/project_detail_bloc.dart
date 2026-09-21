import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trustwork_mobile/domain/entities/entities.dart';
import 'package:trustwork_mobile/domain/repositories/repositories.dart';
import 'package:trustwork_mobile/domain/usecases/usecases.dart';

// --- Events ---
abstract class ProjectDetailEvent extends Equatable {
  const ProjectDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadProjectDetailEvent extends ProjectDetailEvent {
  final ProjectEntity project;
  const LoadProjectDetailEvent(this.project);

  @override
  List<Object?> get props => [project];
}

class ApproveMilestoneEvent extends ProjectDetailEvent {
  final String milestoneDbId;
  final bool isLast;
  const ApproveMilestoneEvent({required this.milestoneDbId, required this.isLast});

  @override
  List<Object?> get props => [milestoneDbId, isLast];
}

class TriggerDisputeEvent extends ProjectDetailEvent {}

class ResolveDisputeEvent extends ProjectDetailEvent {
  final int clientPct;
  final int workerPct;
  const ResolveDisputeEvent({required this.clientPct, required this.workerPct});

  @override
  List<Object?> get props => [clientPct, workerPct];
}

class SubmitEvidenceEvent extends ProjectDetailEvent {
  final String milestoneDbId;
  final String filePath;
  const SubmitEvidenceEvent({required this.milestoneDbId, required this.filePath});

  @override
  List<Object?> get props => [milestoneDbId, filePath];
}

// --- States ---
abstract class ProjectDetailState extends Equatable {
  const ProjectDetailState();

  @override
  List<Object?> get props => [];
}

class ProjectDetailInitialState extends ProjectDetailState {}

class ProjectDetailLoadingState extends ProjectDetailState {}

class ProjectDetailLoadedState extends ProjectDetailState {
  final ProjectEntity project;
  final List<MilestoneEntity> milestones;
  final OnChainProjectEntity? onChainProject;
  final bool isActionLoading;
  final String? actionFeedbackMessage;

  const ProjectDetailLoadedState({
    required this.project,
    required this.milestones,
    this.onChainProject,
    this.isActionLoading = false,
    this.actionFeedbackMessage,
  });

  ProjectDetailLoadedState copyWith({
    ProjectEntity? project,
    List<MilestoneEntity>? milestones,
    OnChainProjectEntity? onChainProject,
    bool? isActionLoading,
    String? actionFeedbackMessage,
  }) {
    return ProjectDetailLoadedState(
      project: project ?? this.project,
      milestones: milestones ?? this.milestones,
      onChainProject: onChainProject ?? this.onChainProject,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      actionFeedbackMessage: actionFeedbackMessage,
    );
  }

  @override
  List<Object?> get props => [
        project,
        milestones,
        onChainProject,
        isActionLoading,
        actionFeedbackMessage,
      ];
}

class ProjectDetailErrorState extends ProjectDetailState {
  final String message;
  const ProjectDetailErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class ProjectDetailBloc extends Bloc<ProjectDetailEvent, ProjectDetailState> {
  final ProjectRepository projectRepository;
  final MilestoneRepository milestoneRepository;
  final ApproveMilestoneUseCase approveMilestoneUseCase;
  final TriggerDisputeUseCase triggerDisputeUseCase;
  final ResolveDisputeUseCase resolveDisputeUseCase;
  final SubmitEvidenceUseCase submitEvidenceUseCase;

  ProjectDetailBloc({
    required this.projectRepository,
    required this.milestoneRepository,
    required this.approveMilestoneUseCase,
    required this.triggerDisputeUseCase,
    required this.resolveDisputeUseCase,
    required this.submitEvidenceUseCase,
  }) : super(ProjectDetailInitialState()) {
    on<LoadProjectDetailEvent>(_onLoadDetail);
    on<ApproveMilestoneEvent>(_onApproveMilestone);
    on<TriggerDisputeEvent>(_onTriggerDispute);
    on<ResolveDisputeEvent>(_onResolveDispute);
    on<SubmitEvidenceEvent>(_onSubmitEvidence);
  }

  Future<void> _onLoadDetail(
    LoadProjectDetailEvent event,
    Emitter<ProjectDetailState> emit,
  ) async {
    emit(ProjectDetailLoadingState());
    final milestonesResult = await milestoneRepository.getMilestonesForProject(event.project.id);
    final milestones = milestonesResult.fold((l) => <MilestoneEntity>[], (r) => r);

    OnChainProjectEntity? onChainProject;
    if (event.project.contractProjectId != null) {
      final onChainResult = await projectRepository.getOnChainProject(event.project.contractProjectId!);
      onChainProject = onChainResult.fold((l) => null, (r) => r);
    }

    emit(ProjectDetailLoadedState(
      project: event.project,
      milestones: milestones,
      onChainProject: onChainProject,
    ));
  }

  Future<void> _onApproveMilestone(
    ApproveMilestoneEvent event,
    Emitter<ProjectDetailState> emit,
  ) async {
    final current = state;
    if (current is! ProjectDetailLoadedState) return;

    if (current.project.contractProjectId == null) return;
    emit(current.copyWith(isActionLoading: true));

    final result = await approveMilestoneUseCase(
      projectDbId: current.project.id,
      contractProjectId: current.project.contractProjectId!,
      milestoneDbId: event.milestoneDbId,
      isLastMilestone: event.isLast,
    );

    await _reloadWithResult(emit, current, result, 'Milestone berhasil diapprove & dana dicairkan!');
  }

  Future<void> _onTriggerDispute(
    TriggerDisputeEvent event,
    Emitter<ProjectDetailState> emit,
  ) async {
    final current = state;
    if (current is! ProjectDetailLoadedState) return;

    if (current.project.contractProjectId == null) return;
    emit(current.copyWith(isActionLoading: true));

    final result = await triggerDisputeUseCase(
      projectDbId: current.project.id,
      contractProjectId: current.project.contractProjectId!,
    );

    await _reloadWithResult(emit, current, result, 'Dispute diaktifkan! Dana dibekukan.');
  }

  Future<void> _onResolveDispute(
    ResolveDisputeEvent event,
    Emitter<ProjectDetailState> emit,
  ) async {
    final current = state;
    if (current is! ProjectDetailLoadedState) return;

    if (current.project.contractProjectId == null) return;
    emit(current.copyWith(isActionLoading: true));

    final result = await resolveDisputeUseCase(
      projectDbId: current.project.id,
      contractProjectId: current.project.contractProjectId!,
      clientPct: event.clientPct,
      workerPct: event.workerPct,
    );

    await _reloadWithResult(emit, current, result, 'Dispute berhasil diselesaikan!');
  }

  Future<void> _onSubmitEvidence(
    SubmitEvidenceEvent event,
    Emitter<ProjectDetailState> emit,
  ) async {
    final current = state;
    if (current is! ProjectDetailLoadedState) return;

    emit(current.copyWith(isActionLoading: true));

    final result = await submitEvidenceUseCase(
      milestoneDbId: event.milestoneDbId,
      filePath: event.filePath,
    );

    await _reloadWithResult(emit, current, result, 'Bukti tugas berhasil diupload ke IPFS!');
  }

  Future<void> _reloadWithResult(
    Emitter<ProjectDetailState> emit,
    ProjectDetailLoadedState current,
    dynamic result,
    String successMsg,
  ) async {
    final milestonesResult = await milestoneRepository.getMilestonesForProject(current.project.id);
    final milestones = milestonesResult.fold((l) => current.milestones, (r) => r);

    OnChainProjectEntity? onChainProject;
    if (current.project.contractProjectId != null) {
      final onChainResult = await projectRepository.getOnChainProject(current.project.contractProjectId!);
      onChainProject = onChainResult.fold((l) => current.onChainProject, (r) => r);
    }

    if (result.isLeft) {
      emit(current.copyWith(
        isActionLoading: false,
        actionFeedbackMessage: 'Error: ${result.left?.message}',
      ));
    } else {
      emit(current.copyWith(
        milestones: milestones,
        onChainProject: onChainProject,
        isActionLoading: false,
        actionFeedbackMessage: successMsg,
      ));
    }
  }
}
