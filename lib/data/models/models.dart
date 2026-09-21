import 'package:trustwork_mobile/domain/entities/entities.dart';

class ProjectModel extends ProjectEntity {
  const ProjectModel({
    required super.id,
    super.contractProjectId,
    required super.title,
    required super.description,
    required super.clientAddress,
    required super.workerAddress,
    required super.totalAmount,
    required super.status,
    required super.createdAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    ProjectStatus status = ProjectStatus.pending;
    final statusStr = (json['status'] as String? ?? '').toUpperCase();
    if (statusStr == 'ACTIVE' || statusStr == 'FUNDED') {
      status = ProjectStatus.funded;
    } else if (statusStr == 'DISPUTED') {
      status = ProjectStatus.disputed;
    } else if (statusStr == 'COMPLETED') {
      status = ProjectStatus.completed;
    }

    return ProjectModel(
      id: json['id'] ?? '',
      contractProjectId: json['contract_project_id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      clientAddress: json['client_address'] ?? '',
      workerAddress: json['freelancer_address'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: status,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  factory ProjectModel.fromEntity(ProjectEntity entity) {
    return ProjectModel(
      id: entity.id,
      contractProjectId: entity.contractProjectId,
      title: entity.title,
      description: entity.description,
      clientAddress: entity.clientAddress,
      workerAddress: entity.workerAddress,
      totalAmount: entity.totalAmount,
      status: entity.status,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contract_project_id': contractProjectId,
      'title': title,
      'description': description,
      'client_address': clientAddress,
      'freelancer_address': workerAddress,
      'total_amount': totalAmount,
      'status': status.label,
    };
  }
}

class MilestoneModel extends MilestoneEntity {
  const MilestoneModel({
    required super.id,
    required super.projectId,
    required super.milestoneIndex,
    required super.title,
    required super.description,
    required super.percentage,
    required super.state,
    super.deliverableCid,
  });

  factory MilestoneModel.fromJson(Map<String, dynamic> json) {
    MilestoneState state = MilestoneState.pending;
    final statusStr = (json['status'] as String? ?? '').toUpperCase();
    if (statusStr == 'SUBMITTED') {
      state = MilestoneState.submitted;
    } else if (statusStr == 'APPROVED') {
      state = MilestoneState.approved;
    } else if (statusStr == 'IN_PROGRESS') {
      state = MilestoneState.inProgress;
    }

    return MilestoneModel(
      id: json['id'] ?? '',
      projectId: json['project_id'] ?? '',
      milestoneIndex: json['milestone_index'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      percentage: (json['percentage'] ?? 0).toInt(),
      state: state,
      deliverableCid: json['deliverable_cid'],
    );
  }

  factory MilestoneModel.fromEntity(MilestoneEntity entity) {
    return MilestoneModel(
      id: entity.id,
      projectId: entity.projectId,
      milestoneIndex: entity.milestoneIndex,
      title: entity.title,
      description: entity.description,
      percentage: entity.percentage,
      state: entity.state,
      deliverableCid: entity.deliverableCid,
    );
  }

  Map<String, dynamic> toJson() {
    String status = 'PENDING';
    if (state == MilestoneState.submitted) status = 'SUBMITTED';
    if (state == MilestoneState.approved) status = 'APPROVED';
    if (state == MilestoneState.inProgress) status = 'IN_PROGRESS';

    return {
      'project_id': projectId,
      'milestone_index': milestoneIndex,
      'title': title,
      'description': description,
      'percentage': percentage,
      'status': status,
      'deliverable_cid': deliverableCid,
    };
  }
}
