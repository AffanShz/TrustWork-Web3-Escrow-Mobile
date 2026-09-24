import 'package:trustwork_mobile/core/constants/contracts.dart';
import 'package:trustwork_mobile/core/errors/failures.dart';
import 'package:trustwork_mobile/data/datasources/datasources.dart';
import 'package:trustwork_mobile/data/models/models.dart';
import 'package:trustwork_mobile/domain/entities/entities.dart';
import 'package:trustwork_mobile/domain/repositories/repositories.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletConnectDataSource walletDataSource;
  final Web3RemoteDataSource web3DataSource;

  WalletRepositoryImpl({
    required this.walletDataSource,
    required this.web3DataSource,
  });

  @override
  Future<Either<Failure, WalletInfo>> connect() async {
    // In actual implementation, connection is triggered by UI (AppKitModalConnectButton)
    // Here we just return the current status
    return getCurrentInfo();
  }

  Future<Either<Failure, WalletInfo>> getCurrentInfo() async {
    final address = walletDataSource.currentAddress;
    if (address == null || address.isEmpty) {
      return const Left(WalletNotConnectedFailure());
    }
    double balance = 0;
    try {
      balance = await web3DataSource.getUsdcBalance(address);
    } catch (_) {
      // Balance fetch failure should not disconnect the wallet
    }
    return Right(WalletInfo(
      address: address,
      usdcBalance: balance,
      isConnected: true,
    ));
  }

  @override
  Future<WalletInfo> get currentInfo async {
    final result = await getCurrentInfo();
    return result.fold(
      (l) => const WalletInfo(address: '', usdcBalance: 0, isConnected: false),
      (r) => r,
    );
  }

  @override
  Future<void> disconnect() async {
    await walletDataSource.disconnect();
  }

  @override
  Future<Either<Failure, String>> sendTransaction({required String to, required String data}) async {
    try {
      final hash = await walletDataSource.sendTransaction(to, data);
      return Right(hash);
    } catch (e) {
      return Left(BlockchainFailure(message: e.toString()));
    }
  }

  @override
  Future<void> initialize() async {
    // No-op here, initialization happens in main or DI
  }
}

class ProjectRepositoryImpl implements ProjectRepository {
  final SupabaseRemoteDataSource supabaseDataSource;
  final Web3RemoteDataSource web3DataSource;
  final WalletConnectDataSource walletDataSource;

  ProjectRepositoryImpl({
    required this.supabaseDataSource,
    required this.web3DataSource,
    required this.walletDataSource,
  });

  @override
  Future<Either<Failure, List<ProjectEntity>>> getProjectsForAddress(String address) async {
    try {
      final models = await supabaseDataSource.getProjects(address);
      return Right(models);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProjectEntity>> createProject(ProjectEntity project) async {
    try {
      final model = ProjectModel.fromEntity(project);
      final result = await supabaseDataSource.createProject(model);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProjectStatus(String projectId, ProjectStatus status) async {
    try {
      await supabaseDataSource.updateProjectStatus(projectId, status.label);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, OnChainProjectEntity>> getOnChainProject(int contractProjectId) async {
    try {
      final result = await web3DataSource.getOnChainProject(contractProjectId);
      if (result == null) return const Left(BlockchainFailure(message: 'Project not found on-chain'));
      return Right(result);
    } catch (e) {
      return Left(BlockchainFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getProjectCount() async {
    try {
      final count = await web3DataSource.getProjectCount();
      return Right(count);
    } catch (e) {
      return Left(BlockchainFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> approveUsdc(BigInt amount) async {
    try {
      final data = web3DataSource.encodeApproveUsdc(amount);
      final hash = await walletDataSource.sendTransaction(mockUsdcAddress, data);
      return Right(hash);
    } catch (e) {
      return Left(BlockchainFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createProjectOnChain({
    required String workerAddress,
    required BigInt amount,
    required List<BigInt> milestonePercentages,
  }) async {
    try {
      final data = web3DataSource.encodeCreateProject(workerAddress, amount, milestonePercentages);
      final hash = await walletDataSource.sendTransaction(trustWorkAddress, data);
      return Right(hash);
    } catch (e) {
      return Left(BlockchainFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> approveMilestone(int contractProjectId) async {
    try {
      final data = web3DataSource.encodeApproveMilestone(contractProjectId);
      final hash = await walletDataSource.sendTransaction(trustWorkAddress, data);
      return Right(hash);
    } catch (e) {
      return Left(BlockchainFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> triggerDispute(int contractProjectId) async {
    try {
      final data = web3DataSource.encodeTriggerDispute(contractProjectId);
      final hash = await walletDataSource.sendTransaction(trustWorkAddress, data);
      return Right(hash);
    } catch (e) {
      return Left(BlockchainFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> resolveDispute({
    required int contractProjectId,
    required int clientPct,
    required int workerPct,
  }) async {
    try {
      final data = web3DataSource.encodeResolveDispute(contractProjectId, clientPct, workerPct);
      final hash = await walletDataSource.sendTransaction(trustWorkAddress, data);
      return Right(hash);
    } catch (e) {
      return Left(BlockchainFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> waitForTransaction(String txHash) async {
    try {
      if (txHash.startsWith('0xsimulated')) {
        await Future.delayed(const Duration(seconds: 1)); // Simulate wait
        return const Right(null);
      }
      await web3DataSource.waitForTransaction(txHash);
      return const Right(null);
    } catch (e) {
      return Left(BlockchainFailure(message: e.toString()));
    }
  }
}

class MilestoneRepositoryImpl implements MilestoneRepository {
  final SupabaseRemoteDataSource supabaseDataSource;
  final IpfsRemoteDataSource ipfsDataSource;

  MilestoneRepositoryImpl({
    required this.supabaseDataSource,
    required this.ipfsDataSource,
  });

  @override
  Future<Either<Failure, List<MilestoneEntity>>> getMilestonesForProject(String projectId) async {
    try {
      final models = await supabaseDataSource.getMilestones(projectId);
      return Right(models);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createMilestones(List<MilestoneEntity> milestones) async {
    try {
      final models = milestones.map((e) => MilestoneModel.fromEntity(e)).toList();
      await supabaseDataSource.createMilestones(models);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMilestoneState({
    required String milestoneId,
    required MilestoneState state,
    String? cid,
  }) async {
    try {
      String status = 'PENDING';
      if (state == MilestoneState.submitted) status = 'SUBMITTED';
      if (state == MilestoneState.approved) status = 'APPROVED';
      if (state == MilestoneState.inProgress) status = 'IN_PROGRESS';

      await supabaseDataSource.updateMilestoneStatus(milestoneId, status, cid: cid);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadDeliverableEvidence(String filePath) async {
    try {
      final cid = await ipfsDataSource.uploadToPinata(filePath);
      return Right(cid);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
