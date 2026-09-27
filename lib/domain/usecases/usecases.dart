import 'package:trustwork_mobile/core/errors/failures.dart';
import 'package:trustwork_mobile/domain/entities/entities.dart';
import 'package:trustwork_mobile/domain/repositories/repositories.dart';

class GetProjectsForAddressUseCase {
  final ProjectRepository repository;
  GetProjectsForAddressUseCase(this.repository);

  Future<Either<Failure, List<ProjectEntity>>> call(String address) {
    return repository.getProjectsForAddress(address);
  }
}

class CreateEscrowProjectUseCase {
  final ProjectRepository projectRepository;
  final MilestoneRepository milestoneRepository;

  CreateEscrowProjectUseCase({
    required this.projectRepository,
    required this.milestoneRepository,
  });

  Future<Either<Failure, ProjectEntity>> call({
    required String title,
    required String description,
    required String clientAddress,
    required String workerAddress,
    required double totalAmount,
    required List<MilestoneEntity> milestones,
  }) async {
    // 1. Validate percentages
    final totalPct = milestones.fold<int>(0, (sum, m) => sum + m.percentage);
    if (totalPct != 100) {
      return const Left(ValidationFailure(message: 'Total milestone percentages must be exactly 100%'));
    }

    // 2. Approve USDC token
    final amountBigInt = _toWei18(totalAmount.toString());
    final approveResult = await projectRepository.approveUsdc(amountBigInt);
    if (approveResult.isLeft) return Left(approveResult.left!);
    await projectRepository.waitForTransaction(approveResult.right!);

    // 3. Create Project on-chain
    final pctBigIntList = milestones.map((m) => BigInt.from(m.percentage)).toList();
    final createResult = await projectRepository.createProjectOnChain(
      workerAddress: workerAddress,
      amount: amountBigInt,
      milestonePercentages: pctBigIntList,
    );
    if (createResult.isLeft) return Left(createResult.left!);
    final txHash = createResult.right!;
    await projectRepository.waitForTransaction(txHash);

    // 4. Resolve exact on-chain project ID from the transaction receipt
    // to prevent race conditions when multiple projects are created simultaneously.
    final idResult = await projectRepository.getCreatedProjectIdFromReceipt(txHash);
    if (idResult.isLeft) return Left(idResult.left!);
    final newProjectId = idResult.right!;

    // 5. Store Project in Supabase
    final newProject = ProjectEntity(
      id: '',
      contractProjectId: newProjectId,
      title: title,
      description: description,
      clientAddress: clientAddress,
      workerAddress: workerAddress,
      totalAmount: totalAmount,
      status: ProjectStatus.funded,
      createdAt: DateTime.now(),
    );

    final savedResult = await projectRepository.createProject(newProject);
    if (savedResult.isLeft) return Left(savedResult.left!);
    final savedProject = savedResult.right!;

    // 6. Store Milestones in Supabase
    final milestonesToSave = milestones.map((m) {
      return m.copyWith(projectId: savedProject.id);
    }).toList();

    final milestonesResult = await milestoneRepository.createMilestones(milestonesToSave);
    if (milestonesResult.isLeft) return Left(milestonesResult.left!);

    return Right(savedProject);
  }

  /// Converts a token amount to raw wei (18 decimals) using string math only.
  ///
  /// [M-5] Previously this took a [double] and went through
  /// `amount.toStringAsFixed(6)`, which risks binary floating-point rounding
  /// (e.g. 1.005 -> "1.004999...") and therefore a wrong wei amount. Working
  /// from a decimal string keeps the exact human-typed value intact end to end.
  BigInt _toWei18(String amount) {
    final trimmed = amount.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Nilai amount tidak boleh kosong.');
    }

    final parts = trimmed.split('.');
    final wholePart = parts[0];
    String decPart = parts.length > 1 ? parts[1] : '';

    if (wholePart.isEmpty && decPart.isEmpty) {
      throw FormatException('Nilai amount tidak valid: "$trimmed".');
    }
    if (int.tryParse(wholePart) == null && wholePart.isNotEmpty) {
      throw FormatException('Nilai amount tidak valid: "$trimmed".');
    }

    final whole = wholePart.isEmpty ? BigInt.zero : BigInt.parse(wholePart);
    // Pad/truncate the fractional part to exactly 18 decimals.
    if (decPart.length > 18) {
      decPart = decPart.substring(0, 18);
    }
    decPart = decPart.padRight(18, '0');
    final dec = decPart.isEmpty ? BigInt.zero : BigInt.parse(decPart);

    return whole * BigInt.from(10).pow(18) + dec;
  }
}

class ApproveMilestoneUseCase {
  final ProjectRepository projectRepository;
  final MilestoneRepository milestoneRepository;

  ApproveMilestoneUseCase({
    required this.projectRepository,
    required this.milestoneRepository,
  });

  Future<Either<Failure, void>> call({
    required String projectDbId,
    required int contractProjectId,
    required String milestoneDbId,
    required bool isLastMilestone,
  }) async {
    final approveResult = await projectRepository.approveMilestone(contractProjectId);
    if (approveResult.isLeft) return Left(approveResult.left!);
    await projectRepository.waitForTransaction(approveResult.right!);

    // Update milestone state in database
    await milestoneRepository.updateMilestoneState(
      milestoneId: milestoneDbId,
      state: MilestoneState.approved,
    );

    if (isLastMilestone) {
      await projectRepository.updateProjectStatus(projectDbId, ProjectStatus.completed);
    }

    return const Right(null);
  }
}

class TriggerDisputeUseCase {
  final ProjectRepository projectRepository;

  TriggerDisputeUseCase(this.projectRepository);

  Future<Either<Failure, void>> call({
    required String projectDbId,
    required int contractProjectId,
  }) async {
    final disputeResult = await projectRepository.triggerDispute(contractProjectId);
    if (disputeResult.isLeft) return Left(disputeResult.left!);
    await projectRepository.waitForTransaction(disputeResult.right!);

    await projectRepository.updateProjectStatus(projectDbId, ProjectStatus.disputed);
    return const Right(null);
  }
}

class ResolveDisputeUseCase {
  final ProjectRepository projectRepository;

  ResolveDisputeUseCase(this.projectRepository);

  Future<Either<Failure, void>> call({
    required String projectDbId,
    required int contractProjectId,
    required int clientPct,
    required int workerPct,
  }) async {
    if (clientPct + workerPct != 100) {
      return const Left(ValidationFailure(message: 'Percentages must total 100%'));
    }

    final resolveResult = await projectRepository.resolveDispute(
      contractProjectId: contractProjectId,
      clientPct: clientPct,
      workerPct: workerPct,
    );
    if (resolveResult.isLeft) return Left(resolveResult.left!);
    await projectRepository.waitForTransaction(resolveResult.right!);

    await projectRepository.updateProjectStatus(projectDbId, ProjectStatus.completed);
    return const Right(null);
  }
}

class SubmitEvidenceUseCase {
  final MilestoneRepository milestoneRepository;

  SubmitEvidenceUseCase(this.milestoneRepository);

  Future<Either<Failure, String>> call({
    required String milestoneDbId,
    required String filePath,
  }) async {
    final uploadResult = await milestoneRepository.uploadDeliverableEvidence(filePath);
    if (uploadResult.isLeft) return Left(uploadResult.left!);
    final cid = uploadResult.right!;

    final updateResult = await milestoneRepository.updateMilestoneState(
      milestoneId: milestoneDbId,
      state: MilestoneState.submitted,
      cid: cid,
    );
    if (updateResult.isLeft) return Left(updateResult.left!);

    return Right(cid);
  }
}
