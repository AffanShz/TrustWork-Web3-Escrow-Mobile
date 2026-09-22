import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reown_appkit/reown_appkit.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/env.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../blocs/wallet/wallet_bloc.dart';
import '../../core/di/injection_container.dart';
import '../../data/datasources/datasources.dart';
import 'projects/project_list_screen.dart';

class ConnectWalletScreen extends StatefulWidget {
  const ConnectWalletScreen({super.key});

  @override
  State<ConnectWalletScreen> createState() => _ConnectWalletScreenState();
}

class _ConnectWalletScreenState extends State<ConnectWalletScreen> {
  final TextEditingController _devAddressController = TextEditingController();
  bool _appKitInitialized = false;
  bool _isCheckingSession = true;
  ReownAppKitModal? _appKitModal;

  @override
  void initState() {
    super.initState();
    _initWalletConnect();
  }

  Future<void> _initWalletConnect() async {
    _appKitModal = ReownAppKitModal(
      context: context,
      projectId: Env.walletConnectProjectId,
      metadata: const PairingMetadata(
        name: 'TrustWork Escrow',
        description: 'Decentralized Escrow with Milestone Payment',
        url: 'https://trustwork.app',
        icons: ['https://trustwork.app/logo.png'],
        redirect: Redirect(
          native: 'trustwork://',
          universal: 'https://trustwork.app',
        ),
      ),
    );

    await _appKitModal!.init();
    
    // Inject _appKitModal to data source
    sl<WalletConnectDataSource>().setModal(_appKitModal!);

    // Listen to connection events
    _appKitModal!.onModalConnect.subscribe((ModalConnect? args) {
      if (mounted) {
        context.read<WalletBloc>().add(WalletCheckStatusEvent());
      }
    });

    _appKitModal!.onModalDisconnect.subscribe((ModalDisconnect? args) {
      if (mounted) {
        context.read<WalletBloc>().add(WalletDisconnectEvent());
      }
    });

    if (mounted) {
      // Recheck the status now that AppKit and SharedPreferences are loaded
      context.read<WalletBloc>().add(WalletCheckStatusEvent());
      
      setState(() {
        _appKitInitialized = true;
        _isCheckingSession = false;
      });
    }
  }

  @override
  void dispose() {
    _appKitModal?.onModalConnect.unsubscribeAll();
    _appKitModal?.onModalDisconnect.unsubscribeAll();
    _devAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        if (state is WalletConnectedState) {
          return const ProjectListScreen();
        }

        if (_isCheckingSession) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [TrustWorkTheme.accent, Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: TrustWorkTheme.accentGlow,
                          blurRadius: 20,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.flash_on_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: TrustWorkTheme.accent,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 80,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 50),
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [TrustWorkTheme.accent, Color(0xFF3B82F6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: TrustWorkTheme.accentGlow,
                                  blurRadius: 24,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.flash_on_rounded,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 100),
                          child: const Text(
                            'TrustWork Escrow',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              color: TrustWorkTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 150),
                          child: const Text(
                            'Decentralized Milestone Escrow Platform.\nLock project funds upfront, trigger instant automated payouts with 0 platform fees.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: TrustWorkTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: TrustWorkTheme.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: TrustWorkTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'CONNECT WALLET',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: TrustWorkTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_appKitInitialized && _appKitModal != null)
                                  AppKitModalConnectButton(
                                    appKit: _appKitModal!,
                                  )
                                else
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: TrustWorkTheme.accent,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 250),
                          child: Row(
                            children: const [
                              Expanded(child: Divider(color: TrustWorkTheme.borderSubtle)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'OR DEV TESTNET LOGIN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: TrustWorkTheme.textMuted,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: TrustWorkTheme.borderSubtle)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 300),
                          child: Container(
                            decoration: BoxDecoration(
                              color: TrustWorkTheme.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: TrustWorkTheme.border),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _devAddressController,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter 0x address for testing...',
                                    prefixIcon: Icon(Icons.code_rounded, color: TrustWorkTheme.textMuted, size: 20),
                                  ),
                                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                                ),
                                const SizedBox(height: 12),
                                PressableScale(
                                  onPressed: () {
                                    final text = _devAddressController.text.trim();
                                    if (text.isNotEmpty && text.startsWith('0x') && text.length == 42) {
                                      context.read<WalletBloc>().add(WalletSetManualAddressEvent(text));
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Masukkan alamat Ethereum valid 42 karakter (0x...)'),
                                          backgroundColor: TrustWorkTheme.danger,
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: TrustWorkTheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: TrustWorkTheme.border),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Connect with Address (Demo Mode)',
                                        style: TextStyle(
                                          color: TrustWorkTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
