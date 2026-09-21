import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../domain/entities/entities.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../blocs/projects/projects_bloc.dart';
import '../../blocs/create_project/create_project_bloc.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _freelancerController = TextEditingController();
  final _amountController = TextEditingController();
  final List<Map<String, TextEditingController>> _milestones = [];

  @override
  void initState() {
    super.initState();
    _milestones.add({
      'description': TextEditingController(text: 'Desain UI/UX Selesai'),
      'percentage': TextEditingController(text: '30'),
    });
    _milestones.add({
      'description': TextEditingController(text: 'Testing & Deployment Selesai'),
      'percentage': TextEditingController(text: '70'),
    });
  }

  int get _totalPercentage {
    return _milestones.fold(0, (sum, m) {
      return sum + (int.tryParse(m['percentage']!.text) ?? 0);
    });
  }

  bool get _validPercentage => _totalPercentage == 100;

  void _addMilestone() {
    if (_milestones.length >= 5) return;
    setState(() {
      _milestones.add({
        'description': TextEditingController(),
        'percentage': TextEditingController(),
      });
    });
  }

  void _removeMilestone(int index) {
    if (_milestones.length <= 1) return;
    setState(() {
      _milestones[index]['description']?.dispose();
      _milestones[index]['percentage']?.dispose();
      _milestones.removeAt(index);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_validPercentage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total persentase milestone harus tepat 100%'),
          backgroundColor: TrustWorkTheme.danger,
        ),
      );
      return;
    }

    final walletState = context.read<WalletBloc>().state;
    if (walletState is! WalletConnectedState) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap hubungkan dompet terlebih dahulu'),
          backgroundColor: TrustWorkTheme.danger,
        ),
      );
      return;
    }

    final clientAddress = walletState.walletInfo.address;
    final milestones = _milestones.asMap().entries.map((e) {
      final desc = e.value['description']!.text.trim();
      return MilestoneEntity(
        id: '',
        projectId: '',
        milestoneIndex: e.key,
        title: desc,
        description: desc,
        percentage: int.parse(e.value['percentage']!.text),
        state: e.key == 0 ? MilestoneState.inProgress : MilestoneState.pending,
      );
    }).toList();

    context.read<CreateProjectBloc>().add(
          SubmitCreateProjectEvent(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            clientAddress: clientAddress,
            workerAddress: _freelancerController.text.trim(),
            totalAmount: double.parse(_amountController.text.trim()),
            milestones: milestones,
          ),
        );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _freelancerController.dispose();
    _amountController.dispose();
    for (final m in _milestones) {
      m['description']?.dispose();
      m['percentage']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateProjectBloc, CreateProjectState>(
      listener: (context, state) {
        if (state is CreateProjectSuccessState) {
          final walletState = context.read<WalletBloc>().state;
          if (walletState is WalletConnectedState) {
            context.read<ProjectsBloc>().add(RefreshProjectsEvent(walletState.walletInfo.address));
            context.read<WalletBloc>().add(WalletRefreshBalanceEvent());
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Escrow berhasil dideploy dan dana terkunci!'),
              backgroundColor: TrustWorkTheme.success,
            ),
          );
          Navigator.pop(context);
        } else if (state is CreateProjectErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: TrustWorkTheme.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state is CreateProjectSubmittingState;
        final stepMessage = isSubmitting ? state.stepMessage : '';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Deploy Escrow'),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                FadeSlideIn(
                  delay: const Duration(milliseconds: 40),
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
                        const Text(
                          'PROJECT DETAILS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: TrustWorkTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Project Name',
                            hintText: 'e.g. Mobile App MVP',
                            prefixIcon: Icon(Icons.drive_file_rename_outline_rounded, size: 20, color: TrustWorkTheme.textMuted),
                          ),
                          style: const TextStyle(color: TrustWorkTheme.textPrimary, fontWeight: FontWeight.w500),
                          maxLength: 40,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Brief project deliverables summary',
                            alignLabelWithHint: true,
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 40),
                              child: Icon(Icons.notes_rounded, size: 20, color: TrustWorkTheme.textMuted),
                            ),
                          ),
                          style: const TextStyle(color: TrustWorkTheme.textPrimary),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _freelancerController,
                          decoration: const InputDecoration(
                            labelText: 'Worker Address (0x...)',
                            hintText: '0x...',
                            prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: TrustWorkTheme.textMuted),
                          ),
                          style: const TextStyle(
                            color: TrustWorkTheme.textPrimary,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                          validator: (v) {
                            if (v == null || !v.startsWith('0x') || v.length != 42) {
                              return 'Enter valid 42-char Ethereum address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Total Value',
                            hintText: '100',
                            suffixText: 'mUSDC',
                            prefixIcon: Icon(Icons.attach_money_rounded, size: 20, color: TrustWorkTheme.textMuted),
                          ),
                          style: const TextStyle(
                            color: TrustWorkTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || (double.tryParse(v) ?? 0) <= 0
                              ? 'Enter valid amount'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
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
                            const Text(
                              'CUSTOM MILESTONES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: TrustWorkTheme.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (_validPercentage
                                        ? TrustWorkTheme.success
                                        : TrustWorkTheme.danger)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (_validPercentage
                                          ? TrustWorkTheme.success
                                          : TrustWorkTheme.danger)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                'Total: $_totalPercentage%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _validPercentage
                                      ? TrustWorkTheme.success
                                      : TrustWorkTheme.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_totalPercentage / 100.0).clamp(0.0, 1.0),
                            backgroundColor: TrustWorkTheme.surface,
                            color: _validPercentage
                                ? TrustWorkTheme.success
                                : TrustWorkTheme.danger,
                            minHeight: 5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._milestones.asMap().entries.map((e) {
                          final i = e.key;
                          final m = e.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: TrustWorkTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: TrustWorkTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Stage #${i + 1}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: TrustWorkTheme.accentLight,
                                      ),
                                    ),
                                    if (_milestones.length > 1)
                                      GestureDetector(
                                        onTap: () => _removeMilestone(i),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: TrustWorkTheme.danger.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: TrustWorkTheme.danger,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: m['description']!,
                                  decoration: const InputDecoration(
                                    hintText: 'Stage deliverable (e.g. Design Finished)',
                                    isDense: true,
                                  ),
                                  style: const TextStyle(
                                    color: TrustWorkTheme.textPrimary,
                                    fontSize: 13,
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: m['percentage']!,
                                  decoration: const InputDecoration(
                                    hintText: 'Percentage',
                                    suffixText: '%',
                                    isDense: true,
                                  ),
                                  style: const TextStyle(
                                    color: TrustWorkTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) {
                                    final pct = int.tryParse(v ?? '');
                                    if (pct == null || pct <= 0 || pct > 100) {
                                      return '1-100';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        if (_milestones.length < 5)
                          PressableScale(
                            onPressed: _addMilestone,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: TrustWorkTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: TrustWorkTheme.accent.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_rounded, size: 16, color: TrustWorkTheme.accentLight),
                                  SizedBox(width: 6),
                                  Text(
                                    'Add Milestone Stage',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: TrustWorkTheme.accentLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: PressableScale(
                    onPressed: (isSubmitting || !_validPercentage) ? null : _submit,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: _validPercentage && !isSubmitting
                            ? const LinearGradient(
                                colors: [TrustWorkTheme.accent, Color(0xFF4F46E5)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        color: !_validPercentage || isSubmitting
                            ? TrustWorkTheme.surface
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _validPercentage && !isSubmitting
                              ? Colors.transparent
                              : TrustWorkTheme.border,
                        ),
                        boxShadow: _validPercentage && !isSubmitting
                            ? const [
                                BoxShadow(
                                  color: TrustWorkTheme.accentGlow,
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isSubmitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    stepMessage,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Lock Funds & Deploy Escrow',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: -0.2,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
