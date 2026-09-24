import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trustwork_mobile/domain/entities/entities.dart';
import 'package:trustwork_mobile/domain/usecases/usecases.dart';

// --- Events ---
abstract class ProjectsEvent extends Equatable {
  const ProjectsEvent();

  @override
  List<Object?> get props => [];
}

class FetchProjectsEvent extends ProjectsEvent {
  final String address;
  const FetchProjectsEvent(this.address);

  @override
  List<Object?> get props => [address];
}

class RefreshProjectsEvent extends ProjectsEvent {
  final String address;
  const RefreshProjectsEvent(this.address);

  @override
  List<Object?> get props => [address];
}

class ResetProjectsEvent extends ProjectsEvent {}

// --- States ---
abstract class ProjectsState extends Equatable {
  const ProjectsState();

  @override
  List<Object?> get props => [];
}

class ProjectsInitialState extends ProjectsState {}

class ProjectsLoadingState extends ProjectsState {}

class ProjectsLoadedState extends ProjectsState {
  final List<ProjectEntity> projects;
  const ProjectsLoadedState(this.projects);

  @override
  List<Object?> get props => [projects];
}

class ProjectsErrorState extends ProjectsState {
  final String message;
  const ProjectsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class ProjectsBloc extends Bloc<ProjectsEvent, ProjectsState> {
  final GetProjectsForAddressUseCase getProjectsUseCase;

  ProjectsBloc({required this.getProjectsUseCase}) : super(ProjectsInitialState()) {
    on<FetchProjectsEvent>(_onFetchProjects);
    on<RefreshProjectsEvent>(_onRefreshProjects);
    on<ResetProjectsEvent>((event, emit) => emit(ProjectsInitialState()));
  }

  Future<void> _onFetchProjects(
    FetchProjectsEvent event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(ProjectsLoadingState());
    final result = await getProjectsUseCase(event.address);
    result.fold(
      (failure) => emit(ProjectsErrorState(failure.message)),
      (projects) => emit(ProjectsLoadedState(projects)),
    );
  }

  Future<void> _onRefreshProjects(
    RefreshProjectsEvent event,
    Emitter<ProjectsState> emit,
  ) async {
    final result = await getProjectsUseCase(event.address);
    result.fold(
      (failure) => emit(ProjectsErrorState(failure.message)),
      (projects) => emit(ProjectsLoadedState(projects)),
    );
  }
}
