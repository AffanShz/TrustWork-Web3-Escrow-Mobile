import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/contracts.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../domain/entities/entities.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../blocs/projects/projects_bloc.dart';
import '../create_project/create_project_screen.dart';
import '../project_detail/milestone_detail_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  @override
  void initState() {
    super.initState();
    final walletState = context.read<WalletBloc>().state;
    if (walletState is WalletConnectedState) {
      context.read<ProjectsBloc>().add(FetchProjectsEvent(walletState.walletInfo.address));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, walletState) {
        final address = walletState is WalletConnectedState ? walletState.walletInfo.address : '';
        final balance = walletState is WalletConnectedState ? walletState.walletInfo.usdcBalance : 0.0;
        final shortAddress = address.length > 10
            ? '${address.substring(0, 6)}...${address.substring(address.length - 4)}'
            : address;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [TrustWorkTheme.accent, Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x337C3AED),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.flash_on_rounded, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text(
                  'TrustWork',
                  style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: TrustWorkTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TrustWorkTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: TrustWorkTheme.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: TrustWorkTheme.successGlow,
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      shortAddress,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: TrustWorkTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        context.read<WalletBloc>().add(WalletDisconnectEvent());
                      },
                      child: const Icon(Icons.logout_rounded, size: 15, color: TrustWorkTheme.textMuted),
                    ),
                  ],
                ),
              )
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<WalletBloc>().add(WalletRefreshBalanceEvent());
              context.read<ProjectsBloc>().add(RefreshProjectsEvent(address));
            },
            color: TrustWorkTheme.accent,
            backgroundColor: TrustWorkTheme.surface,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                FadeSlideIn(
                  delay: const Duration(milliseconds: 40),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF141423), Color(0xFF0F0F18)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: TrustWorkTheme.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'MY WALLET BALANCE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: TrustWorkTheme.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: TrustWorkTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: TrustWorkTheme.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.token_rounded, size: 13, color: TrustWorkTheme.accentLight),
                                  SizedBox(width: 4),
                                  Text(
                                    'Sepolia USDC',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: TrustWorkTheme.accentLight,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: Text(
                                balance.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                  color: TrustWorkTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'mUSDC',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: TrustWorkTheme.accentLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        PressableScale(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateProjectScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [TrustWorkTheme.accent, Color(0xFF4F46E5)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: TrustWorkTheme.accentGlow,
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_circle_outline_rounded, size: 18, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Deploy New Escrow',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: TrustWorkTheme.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Sepolia Network',
                              style: TextStyle(fontSize: 11, color: TrustWorkTheme.textSecondary),
                            ),
                            const Spacer(),
                            Text(
                              'Contract: ${trustWorkAddress.substring(0, 6)}...${trustWorkAddress.substring(trustWorkAddress.length - 4)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: TrustWorkTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Escrows',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: TrustWorkTheme.textPrimary,
                        ),
                      ),
                      BlocBuilder<ProjectsBloc, ProjectsState>(
                        builder: (context, state) {
                          final count = state is ProjectsLoadedState ? state.projects.length : 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: TrustWorkTheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: TrustWorkTheme.border),
                            ),
                            child: Text(
                              '$count Total',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: TrustWorkTheme.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                BlocBuilder<ProjectsBloc, ProjectsState>(
                  builder: (context, state) {
                    if (state is ProjectsLoadingState) {
                      return Column(
                        children: const [
                          SkeletonProjectCard(),
                          SkeletonProjectCard(),
                        ],
                      );
                    } else if (state is ProjectsLoadedState) {
                      if (state.projects.isEmpty) {
                        return FadeSlideIn(
                          delay: const Duration(milliseconds: 100),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                            decoration: BoxDecoration(
                              color: TrustWorkTheme.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: TrustWorkTheme.border,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: TrustWorkTheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: TrustWorkTheme.border),
                                  ),
                                  child: const Icon(
                                    Icons.inbox_outlined,
                                    size: 28,
                                    color: TrustWorkTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'No active escrows found',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: TrustWorkTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Deploy an escrow contract above to lock funds and collaborate safely.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: TrustWorkTheme.textSecondary, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: state.projects.asMap().entries.map(
                          (entry) => FadeSlideIn(
                            delay: Duration(milliseconds: 100 + (entry.key * 50)),
                            child: _ProjectCard(
                              project: entry.value,
                              currentAddress: address,
                            ),
                          ),
                        ).toList(),
                      );
                    } else if (state is ProjectsErrorState) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: TrustWorkTheme.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: TrustWorkTheme.danger),
                        ),
                        child: Text(
                          'Error loading projects: ${state.message}',
                          style: const TextStyle(color: TrustWorkTheme.danger),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectEntity project;
  final String currentAddress;

  const _ProjectCard({
    required this.project,
    required this.currentAddress,
  });

  @override
  Widget build(BuildContext context) {
    final isClient = currentAddress.toLowerCase() == project.clientAddress.toLowerCase();
    final isCompleted = project.status == ProjectStatus.completed;
    final isDisputed = project.status == ProjectStatus.disputed;

    final Color statusColor = isCompleted
        ? TrustWorkTheme.success
        : isDisputed
            ? TrustWorkTheme.danger
            : TrustWorkTheme.accentLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: PressableScale(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, animation, secondaryAnimation) =>
                  MilestoneDetailScreen(project: project),
              transitionsBuilder: (_, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TrustWorkTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? TrustWorkTheme.success.withValues(alpha: 0.3)
                  : isDisputed
                      ? TrustWorkTheme.danger.withValues(alpha: 0.3)
                      : TrustWorkTheme.border,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isClient ? TrustWorkTheme.accent : TrustWorkTheme.warning)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (isClient ? TrustWorkTheme.accent : TrustWorkTheme.warning)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      isClient ? 'CLIENT' : 'WORKER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isClient ? TrustWorkTheme.accentLight : TrustWorkTheme.warning,
                      ),
                    ),
                  ),
                  Text(
                    '${project.totalAmount.toStringAsFixed(0)} USDC',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: TrustWorkTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                project.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: TrustWorkTheme.textPrimary,
                ),
              ),
              if (project.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  project.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: TrustWorkTheme.textSecondary, height: 1.3),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          project.status.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: const [
                      Text(
                        'Details',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TrustWorkTheme.textMuted),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 11, color: TrustWorkTheme.textMuted),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
