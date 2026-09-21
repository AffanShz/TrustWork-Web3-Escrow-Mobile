import 'package:flutter_test/flutter_test.dart';
import 'package:trustwork_mobile/domain/entities/entities.dart';
import 'package:trustwork_mobile/data/models/models.dart';

void main() {
  test('MilestoneModel serialization and entity test', () {
    const milestone = MilestoneModel(
      id: 'm1',
      projectId: 'p1',
      milestoneIndex: 0,
      title: 'UI Design',
      description: 'Design UI',
      percentage: 30,
      state: MilestoneState.pending,
    );

    expect(milestone.percentage, 30);
    final json = milestone.toJson();
    expect(json['percentage'], 30);
    expect(json['status'], 'PENDING');

    final fromJson = MilestoneModel.fromJson({
      'id': 'm1',
      'project_id': 'p1',
      'milestone_index': 0,
      'title': 'UI Design',
      'description': 'Design UI',
      'percentage': 30,
      'status': 'SUBMITTED',
      'deliverable_cid': 'QmTest123',
    });
    expect(fromJson.percentage, 30);
    expect(fromJson.state, MilestoneState.submitted);
    expect(fromJson.deliverableCid, 'QmTest123');
  });

  test('ProjectModel status parsing test', () {
    final project = ProjectModel.fromJson({
      'id': 'proj1',
      'contract_project_id': 0,
      'title': 'Test Project',
      'description': 'Test Desc',
      'client_address': '0xClient',
      'freelancer_address': '0xWorker',
      'total_amount': 100,
      'status': 'ACTIVE',
      'created_at': DateTime.now().toIso8601String(),
    });

    expect(project.status, ProjectStatus.funded);
    expect(project.status.label, 'ACTIVE');
  });
}
