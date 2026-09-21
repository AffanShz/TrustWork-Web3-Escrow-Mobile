import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trustwork_mobile/domain/entities/entities.dart';
import 'package:trustwork_mobile/domain/usecases/usecases.dart';

// --- Events ---
abstract class CreateProjectEvent extends Equatable {
  const CreateProjectEvent();

  @override
  List<Object?> get props => [];
}

class SubmitCreateProjectEvent extends CreateProjectEvent {
  final String title;
  final String description;
  final String clientAddress;
  final String workerAddress;
  final double totalAmount;
  final List<MilestoneEntity> milestones;

  const SubmitCreateProjectEvent({
    required this.title,
    required this.description,
    required this.clientAddress,
    required this.workerAddress,
    required this.totalAmount,
    required this.milestones,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        clientAddress,
        workerAddress,
        totalAmount,
        milestones,
      ];
}

// --- States ---
abstract class CreateProjectState extends Equatable {
  const CreateProjectState();

  @override
  List<Object?> get props => [];
}

class CreateProjectInitialState extends CreateProjectState {}

class CreateProjectSubmittingState extends CreateProjectState {
  final String stepMessage;
  const CreateProjectSubmittingState(this.stepMessage);

  @override
  List<Object?> get props => [stepMessage];
}

class CreateProjectSuccessState extends CreateProjectState {
  final ProjectEntity project;
  const CreateProjectSuccessState(this.project);

  @override
  List<Object?> get props => [project];
}

class CreateProjectErrorState extends CreateProjectState {
  final String message;
  const CreateProjectErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class CreateProjectBloc extends Bloc<CreateProjectEvent, CreateProjectState> {
  final CreateEscrowProjectUseCase createEscrowUseCase;

  CreateProjectBloc({required this.createEscrowUseCase})
      : super(CreateProjectInitialState()) {
    on<SubmitCreateProjectEvent>(_onSubmitCreateProject);
  }

  Future<void> _onSubmitCreateProject(
    SubmitCreateProjectEvent event,
    Emitter<CreateProjectState> emit,
  ) async {
    emit(const CreateProjectSubmittingState('Memproses Transaksi On-Chain...'));

    final result = await createEscrowUseCase(
      title: event.title,
      description: event.description,
      clientAddress: event.clientAddress,
      workerAddress: event.workerAddress,
      totalAmount: event.totalAmount,
      milestones: event.milestones,
    );

    result.fold(
      (failure) => emit(CreateProjectErrorState(failure.message)),
      (project) => emit(CreateProjectSuccessState(project)),
    );
  }
}
