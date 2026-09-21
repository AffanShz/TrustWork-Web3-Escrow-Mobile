import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../domain/entities/entities.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../blocs/projects/projects_bloc.dart';
import '../../blocs/project_detail/project_detail_bloc.dart';

class MilestoneDetailScreen extends StatefulWidget {
  final ProjectEntity project;
  const MilestoneDetailScreen({super.key, required this.project});

  @override
  State<MilestoneDetailScreen> createState() => _MilestoneDetailScreenState();
}

class _MilestoneDetailScreenState extends State<MilestoneDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProjectDetailBloc>().add(LoadProjectDetailEvent(widget.project));
  }

  bool _isClient(String currentAddress) {
    return currentAddress.toLowerCase() == widget.project.clientAddress.toLowerCase();
  }

  bool _isWorker(String currentAddress) {
    return currentAddress.toLowerCase() == widget.project.workerAddress.toLowerCase();
  }

  bool _isArbiter(String currentAddress, OnChainProjectEntity? onChainProject) {
    if (onChainProject == null) return false;
    return currentAddress.toLowerCase() == onChainProject.arbiterAddress.toLowerCase();
  }

  Future<void> _pickAndSubmitEvidence(String milestoneId) async {
    final result = await FilePicker.pickFiles();
    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;

    context.read<ProjectDetailBloc>().add(
          SubmitEvidenceEvent(
            milestoneDbId: milestoneId,
            filePath: result.files.single.path!,
          ),
        );
  }

  Future<void> _showResolveDialog() async {
    final clientPctController = TextEditingController(text: '50');
    final workerPctController = TextEditingController(text: '50');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TrustWorkTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: TrustWorkTheme.border),
        ),
        title: const Text(
          'Resolve Dispute',
          style: TextStyle(color: TrustWorkTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tentukan persentase penyelesaian dana yang tersisa (Total harus 100%):',
              style: TextStyle(color: TrustWorkTheme.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: clientPctController,
              decoration: const InputDecoration(labelText: 'Client Share (%)', isDense: true),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: TrustWorkTheme.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: workerPctController,
              decoration: const InputDecoration(labelText: 'Worker Share (%)', isDense: true),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: TrustWorkTheme.textPrimary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: TrustWorkTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final cPct = int.tryParse(clientPctController.text) ?? -1;
              final wPct = int.tryParse(workerPctController.text) ?? -1;
              if (cPct + wPct != 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Total persentase harus 100%'),
                    backgroundColor: TrustWorkTheme.danger,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              context.read<ProjectDetailBloc>().add(
                    ResolveDisputeEvent(clientPct: cPct, workerPct: wPct),
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: TrustWorkTheme.success),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = context.watch<WalletBloc>().state;
    final currentAddress = walletState is WalletConnectedState ? walletState.walletInfo.address : '';

    return BlocConsumer<ProjectDetailBloc, ProjectDetailState>(
      listener: (context, state) {
        if (state is ProjectDetailLoadedState && state.actionFeedbackMessage != null) {
          final isError = state.actionFeedbackMessage!.startsWith('Error:');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionFeedbackMessage!),
              backgroundColor: isError ? TrustWorkTheme.danger : TrustWorkTheme.success,
            ),
          );

          if (!isError) {
            context.read<ProjectsBloc>().add(RefreshProjectsEvent(currentAddress));
            context.read<WalletBloc>().add(WalletRefreshBalanceEvent());
          }
        }
      },
      builder: (context, state) {
        if (state is ProjectDetailLoadingState) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: TrustWorkTheme.accent),
            ),
          );
        }

        if (state is! ProjectDetailLoadedState) {
          return const Scaffold(
            body: Center(
              child: Text('Terjadi kesalahan memuat proyek'),
            ),
          );
        }

        final p = state.project;
        final milestones = state.milestones;
        final onChain = state.onChainProject;
        final currentMilestone = onChain?.currentMilestone ?? 0;
        final totalMilestones = milestones.isNotEmpty ? milestones.length : 1;
        final isCompleted = onChain?.status == ProjectStatus.completed || p.status == ProjectStatus.completed;
        final isDisputed = onChain?.status == ProjectStatus.disputed || p.status == ProjectStatus.disputed;
        final isFunded = onChain?.status == ProjectStatus.funded || p.status == ProjectStatus.funded;

        return Scaffold(
          appBar: AppBar(title: const Text('Escrow Details')),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<ProjectDetailBloc>().add(LoadProjectDetailEvent(p));
            },
            color: TrustWorkTheme.accent,
            backgroundColor: TrustWorkTheme.surface,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                FadeSlideIn(
                  delay: const Duration(milliseconds: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: TrustWorkTheme.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: TrustWorkTheme.border),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                p.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: TrustWorkTheme.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isCompleted
                                        ? TrustWorkTheme.success
                                        : isDisputed
                                            ? TrustWorkTheme.danger
                                            : TrustWorkTheme.accentLight)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (isCompleted
                                          ? TrustWorkTheme.success
                                          : isDisputed
                                              ? TrustWorkTheme.danger
                                              : TrustWorkTheme.accentLight)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                onChain?.status.label ?? p.status.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isCompleted
                                      ? TrustWorkTheme.success
                                      : isDisputed
                                          ? TrustWorkTheme.danger
                                          : TrustWorkTheme.accentLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          label: 'Total Escrow Locked',
                          value: '${p.totalAmount.toStringAsFixed(2)} USDC',
                          isHighlight: true,
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Client (Depositor)',
                          value: '${p.clientAddress.substring(0, 6)}...${p.clientAddress.substring(p.clientAddress.length - 4)}',
                        ),
                        _InfoRow(
                          label: 'Worker (Receiver)',
                          value: '${p.workerAddress.substring(0, 6)}...${p.workerAddress.substring(p.workerAddress.length - 4)}',
                        ),
                        if (onChain != null)
                          _InfoRow(
                            label: 'Neutral Arbiter',
                            value: '${onChain.arbiterAddress.substring(0, 6)}...${onChain.arbiterAddress.substring(onChain.arbiterAddress.length - 4)}',
                          ),
                        const SizedBox(height: 20),
                        const Divider(color: TrustWorkTheme.border, height: 1),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Milestone Progress',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TrustWorkTheme.textMuted),
                            ),
                            Text(
                              '${isCompleted ? totalMilestones : currentMilestone} of $totalMilestones Completed',
                              style: const TextStyle(fontSize: 12, color: TrustWorkTheme.textPrimary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: isCompleted ? 1.0 : (currentMilestone / totalMilestones),
                            backgroundColor: TrustWorkTheme.surface,
                            color: isCompleted ? TrustWorkTheme.success : TrustWorkTheme.accent,
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (isDisputed)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 40),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: TrustWorkTheme.danger.withValues(alpha: 0.1),
                        border: Border.all(color: TrustWorkTheme.danger.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.gavel_rounded, color: TrustWorkTheme.danger),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Proyek ini dalam status DISPUTE. Dana dibekukan hingga Arbiter mengambil keputusan.',
                              style: TextStyle(color: TrustWorkTheme.danger, fontWeight: FontWeight.w600, fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: const Text(
                    'Tasks & Deliverables',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: TrustWorkTheme.textPrimary),
                  ),
                ),
                const SizedBox(height: 12),
                ...milestones.asMap().entries.map((e) {
                  final idx = e.key;
                  final m = e.value;
                  final isCurrent = idx == currentMilestone && !isCompleted && !isDisputed;
                  final isPast = idx < currentMilestone || isCompleted;

                  return FadeSlideIn(
                    delay: Duration(milliseconds: 80 + (idx * 30)),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: TrustWorkTheme.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPast
                              ? TrustWorkTheme.success.withValues(alpha: 0.3)
                              : isCurrent
                                  ? TrustWorkTheme.accent.withValues(alpha: 0.4)
                                  : TrustWorkTheme.border,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Task ${idx + 1}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: TrustWorkTheme.textSecondary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isPast ? TrustWorkTheme.success : isCurrent ? TrustWorkTheme.accent : TrustWorkTheme.textMuted).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isPast
                                      ? 'APPROVED'
                                      : isCurrent
                                          ? (m.state == MilestoneState.submitted ? 'IN REVIEW' : 'IN PROGRESS')
                                          : 'LOCKED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: isPast ? TrustWorkTheme.success : isCurrent ? TrustWorkTheme.accentLight : TrustWorkTheme.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            m.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: TrustWorkTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${m.percentage}% Release • \$${(m.percentage / 100 * p.totalAmount).toStringAsFixed(2)} USDC',
                            style: const TextStyle(fontSize: 13, color: TrustWorkTheme.accentLight, fontWeight: FontWeight.w600),
                          ),
                          if (m.deliverableCid != null && m.deliverableCid!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(color: TrustWorkTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: TrustWorkTheme.border)),
                              child: Row(
                                children: [
                                  const Icon(Icons.verified_rounded, size: 16, color: TrustWorkTheme.success),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'IPFS Proof: ${m.deliverableCid!.substring(0, 20)}...',
                                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: TrustWorkTheme.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_isWorker(currentAddress) && isCurrent && (m.deliverableCid == null || m.deliverableCid!.isEmpty)) ...[
                            const SizedBox(height: 16),
                            PressableScale(
                              onPressed: state.isActionLoading ? null : () => _pickAndSubmitEvidence(m.id),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: TrustWorkTheme.surface,
                                  border: Border.all(color: TrustWorkTheme.accent.withValues(alpha: 0.5)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.cloud_upload_rounded, size: 16, color: TrustWorkTheme.accentLight),
                                    SizedBox(width: 8),
                                    Text(
                                      'Submit Evidence (IPFS)',
                                      style: TextStyle(fontWeight: FontWeight.w600, color: TrustWorkTheme.accentLight, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                if (_isClient(currentAddress) && isFunded && state.isActionLoading)
                  const Center(child: CircularProgressIndicator(color: TrustWorkTheme.success)),
                if (_isClient(currentAddress) && isFunded && !state.isActionLoading)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: PressableScale(
                      onPressed: () {
                        if (currentMilestone < milestones.length) {
                          context.read<ProjectDetailBloc>().add(
                                ApproveMilestoneEvent(
                                  milestoneDbId: milestones[currentMilestone].id,
                                  isLast: currentMilestone + 1 >= milestones.length,
                                ),
                              );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: TrustWorkTheme.success,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: TrustWorkTheme.successGlow, blurRadius: 16, offset: Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle_outline_rounded, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Approve & Release Funds', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ),
                if ((_isClient(currentAddress) || _isWorker(currentAddress)) && isFunded && !state.isActionLoading) ...[
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 250),
                    child: PressableScale(
                      onPressed: () {
                        context.read<ProjectDetailBloc>().add(TriggerDisputeEvent());
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: TrustWorkTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: TrustWorkTheme.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.gavel_rounded, size: 16, color: TrustWorkTheme.danger),
                            SizedBox(width: 8),
                            Text('Halt & Trigger Dispute', style: TextStyle(color: TrustWorkTheme.danger, fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                if (_isArbiter(currentAddress, onChain) && isDisputed && !state.isActionLoading) ...[
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: PressableScale(
                      onPressed: _showResolveDialog,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: TrustWorkTheme.accent,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: TrustWorkTheme.accentGlow, blurRadius: 16, offset: Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.balance_rounded, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Resolve Dispute (Arbiter)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _InfoRow({required this.label, required this.value, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: TrustWorkTheme.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 16 : 13,
              fontFamily: !isHighlight && value.startsWith('0x') ? 'monospace' : null,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight ? TrustWorkTheme.accentLight : TrustWorkTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
