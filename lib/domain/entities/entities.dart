enum ProjectStatus { pending, funded, disputed, completed, unknown }

extension ProjectStatusX on ProjectStatus {
  String get label {
    switch (this) {
      case ProjectStatus.pending:
        return 'PENDING';
      case ProjectStatus.funded:
        return 'ACTIVE';
      case ProjectStatus.disputed:
        return 'DISPUTED';
      case ProjectStatus.completed:
        return 'COMPLETED';
      case ProjectStatus.unknown:
        return 'UNKNOWN';
    }
  }

  static ProjectStatus fromOnChainCode(int code) {
    switch (code) {
      case 0:
        return ProjectStatus.pending;
      case 1:
        return ProjectStatus.funded;
      case 2:
        return ProjectStatus.disputed;
      case 3:
        return ProjectStatus.completed;
      default:
        return ProjectStatus.unknown;
    }
  }
}

enum MilestoneState { pending, inProgress, submitted, approved }

class MilestoneEntity {
  final String id;
  final String projectId;
  final int milestoneIndex;
  final String title;
  final String description;
  final int percentage;
  final MilestoneState state;
  final String? deliverableCid;

  const MilestoneEntity({
    required this.id,
    required this.projectId,
    required this.milestoneIndex,
    required this.title,
    required this.description,
    required this.percentage,
    required this.state,
    this.deliverableCid,
  });

  MilestoneEntity copyWith({
    String? id,
    String? projectId,
    int? milestoneIndex,
    String? title,
    String? description,
    int? percentage,
    MilestoneState? state,
    String? deliverableCid,
  }) {
    return MilestoneEntity(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      milestoneIndex: milestoneIndex ?? this.milestoneIndex,
      title: title ?? this.title,
      description: description ?? this.description,
      percentage: percentage ?? this.percentage,
      state: state ?? this.state,
      deliverableCid: deliverableCid ?? this.deliverableCid,
    );
  }
}

class ProjectEntity {
  final String id;
  final int? contractProjectId;
  final String title;
  final String description;
  final String clientAddress;
  final String workerAddress;
  final double totalAmount;
  final ProjectStatus status;
  final DateTime createdAt;

  const ProjectEntity({
    required this.id,
    this.contractProjectId,
    required this.title,
    required this.description,
    required this.clientAddress,
    required this.workerAddress,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  ProjectEntity copyWith({
    String? id,
    int? contractProjectId,
    String? title,
    String? description,
    String? clientAddress,
    String? workerAddress,
    double? totalAmount,
    ProjectStatus? status,
    DateTime? createdAt,
  }) {
    return ProjectEntity(
      id: id ?? this.id,
      contractProjectId: contractProjectId ?? this.contractProjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      clientAddress: clientAddress ?? this.clientAddress,
      workerAddress: workerAddress ?? this.workerAddress,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class OnChainProjectEntity {
  final String clientAddress;
  final String workerAddress;
  final BigInt totalAmountRaw;
  final String tokenAddress;
  final ProjectStatus status;
  final int currentMilestone;
  final String arbiterAddress;

  const OnChainProjectEntity({
    required this.clientAddress,
    required this.workerAddress,
    required this.totalAmountRaw,
    required this.tokenAddress,
    required this.status,
    required this.currentMilestone,
    required this.arbiterAddress,
  });

  double get totalAmount => totalAmountRaw / BigInt.from(10).pow(18);
}

class OnChainMilestoneEntity {
  final int percentage;
  final bool isApproved;

  const OnChainMilestoneEntity({required this.percentage, required this.isApproved});
}

class WalletInfo {
  final String address;
  final double usdcBalance;
  final bool isConnected;

  const WalletInfo({
    required this.address,
    required this.usdcBalance,
    required this.isConnected,
  });

  WalletInfo copyWith({String? address, double? usdcBalance, bool? isConnected}) {
    return WalletInfo(
      address: address ?? this.address,
      usdcBalance: usdcBalance ?? this.usdcBalance,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
