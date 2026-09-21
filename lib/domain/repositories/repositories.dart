import 'package:trustwork_mobile/core/errors/failures.dart';
import 'package:trustwork_mobile/domain/entities/entities.dart';

abstract class WalletRepository {
  Future<Either<Failure, WalletInfo>> connect();
  Future<void> disconnect();
  Future<WalletInfo> get currentInfo;
  Future<Either<Failure, String>> sendTransaction({
    required String to,
    required String data,
  });
  Future<void> initialize();
}

abstract class ProjectRepository {
  Future<Either<Failure, List<ProjectEntity>>> getProjectsForAddress(String address);
  Future<Either<Failure, ProjectEntity>> createProject(ProjectEntity project);
  Future<Either<Failure, void>> updateProjectStatus(String projectId, ProjectStatus status);
  Future<Either<Failure, OnChainProjectEntity>> getOnChainProject(int contractProjectId);
  Future<Either<Failure, int>> getProjectCount();
  Future<Either<Failure, String>> approveUsdc(BigInt amount);
  Future<Either<Failure, String>> createProjectOnChain({
    required String workerAddress,
    required BigInt amount,
    required List<BigInt> milestonePercentages,
  });
  Future<Either<Failure, String>> approveMilestone(int contractProjectId);
  Future<Either<Failure, String>> triggerDispute(int contractProjectId);
  Future<Either<Failure, String>> resolveDispute({
    required int contractProjectId,
    required int clientPct,
    required int workerPct,
  });
  Future<Either<Failure, void>> waitForTransaction(String txHash);
}

abstract class MilestoneRepository {
  Future<Either<Failure, List<MilestoneEntity>>> getMilestonesForProject(String projectId);
  Future<Either<Failure, void>> createMilestones(List<MilestoneEntity> milestones);
  Future<Either<Failure, void>> updateMilestoneState({
    required String milestoneId,
    required MilestoneState state,
    String? cid,
  });
  Future<Either<Failure, String>> uploadDeliverableEvidence(String filePath);
}
