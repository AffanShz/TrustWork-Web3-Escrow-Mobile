import 'package:get_it/get_it.dart';
import 'package:trustwork_mobile/data/datasources/datasources.dart';
import 'package:trustwork_mobile/data/repositories/repositories_impl.dart';
import 'package:trustwork_mobile/domain/repositories/repositories.dart';
import 'package:trustwork_mobile/domain/usecases/usecases.dart';
import 'package:trustwork_mobile/presentation/blocs/create_project/create_project_bloc.dart';
import 'package:trustwork_mobile/presentation/blocs/project_detail/project_detail_bloc.dart';
import 'package:trustwork_mobile/presentation/blocs/projects/projects_bloc.dart';
import 'package:trustwork_mobile/presentation/blocs/wallet/wallet_bloc.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  // Data sources
  sl.registerLazySingleton(() => Web3RemoteDataSource());
  sl.registerLazySingleton(() => SupabaseRemoteDataSource());
  sl.registerLazySingleton(() => IpfsRemoteDataSource());
  
  final walletDataSource = WalletConnectDataSource();
  await walletDataSource.init();
  sl.registerLazySingleton(() => walletDataSource);

  // Repositories
  sl.registerLazySingleton<WalletRepository>(() => WalletRepositoryImpl(
        walletDataSource: sl(),
        web3DataSource: sl(),
      ));
  sl.registerLazySingleton<ProjectRepository>(() => ProjectRepositoryImpl(
        supabaseDataSource: sl(),
        web3DataSource: sl(),
        walletDataSource: sl(),
      ));
  sl.registerLazySingleton<MilestoneRepository>(() => MilestoneRepositoryImpl(
        supabaseDataSource: sl(),
        ipfsDataSource: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => GetProjectsForAddressUseCase(sl()));
  sl.registerLazySingleton(() => CreateEscrowProjectUseCase(
        projectRepository: sl(),
        milestoneRepository: sl(),
      ));
  sl.registerLazySingleton(() => ApproveMilestoneUseCase(
        projectRepository: sl(),
        milestoneRepository: sl(),
      ));
  sl.registerLazySingleton(() => TriggerDisputeUseCase(sl()));
  sl.registerLazySingleton(() => ResolveDisputeUseCase(sl()));
  sl.registerLazySingleton(() => SubmitEvidenceUseCase(sl()));

  // Blocs
  sl.registerFactory(() => WalletBloc(
        walletRepository: sl(),
        walletConnectDataSource: sl(),
      ));
  sl.registerFactory(() => ProjectsBloc(
        getProjectsUseCase: sl(),
      ));
  sl.registerFactory(() => CreateProjectBloc(
        createEscrowUseCase: sl(),
      ));
  sl.registerFactory(() => ProjectDetailBloc(
        projectRepository: sl(),
        milestoneRepository: sl(),
        approveMilestoneUseCase: sl(),
        triggerDisputeUseCase: sl(),
        resolveDisputeUseCase: sl(),
        submitEvidenceUseCase: sl(),
      ));
}
