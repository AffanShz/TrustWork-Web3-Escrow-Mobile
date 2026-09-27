import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/env.dart';
import 'core/theme/app_theme.dart';
import 'core/di/injection_container.dart';
import 'presentation/blocs/wallet/wallet_bloc.dart';
import 'presentation/blocs/projects/projects_bloc.dart';
import 'presentation/blocs/create_project/create_project_bloc.dart';
import 'presentation/blocs/project_detail/project_detail_bloc.dart';
import 'presentation/screens/connect_wallet_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // [H-4] Fail-fast configuration loading.
  // Debug mode: allow .env.example fallback for local development convenience.
  // Release mode: hard fail if .env or critical keys are missing — a silently
  // misconfigured escrow app is far more dangerous than a crash on startup.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ .env gagal dimuat, mencoba .env.example (khusus debug): $e');
      try {
        await dotenv.load(fileName: '.env.example');
      } catch (_) {}
    } else {
      throw StateError(
        'Konfigurasi aplikasi tidak ditemukan: file .env gagal dimuat. '
        'Build release memerlukan file .env yang valid.',
      );
    }
  }

  if (!kDebugMode) {
    final missingKeys = <String>[
      if (Env.supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (Env.supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
      if (Env.walletConnectProjectId.isEmpty) 'WALLETCONNECT_PROJECT_ID',
      if (Env.trustWorkAddress.isEmpty) 'TRUSTWORK_ADDRESS',
      if (Env.mockUsdcAddress.isEmpty) 'MOCKUSDC_ADDRESS',
    ];
    if (missingKeys.isNotEmpty) {
      throw StateError(
        'Konfigurasi wajib hilang dari .env: ${missingKeys.join(', ')}. '
        'Isi semua variabel sebelum build release.',
      );
    }
  }

  if (Env.supabaseUrl.isNotEmpty && Env.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: Env.supabaseAnonKey,
    );
  }

  await initDI();

  runApp(const TrustWorkApp());
}

class TrustWorkApp extends StatelessWidget {
  const TrustWorkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<WalletBloc>(),
        ),
        BlocProvider(
          create: (context) => sl<ProjectsBloc>(),
        ),
        BlocProvider(
          create: (context) => sl<CreateProjectBloc>(),
        ),
        BlocProvider(
          create: (context) => sl<ProjectDetailBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'TrustWork Escrow',
        debugShowCheckedModeBanner: false,
        theme: TrustWorkTheme.darkTheme,
        home: const ConnectWalletScreen(),
      ),
    );
  }
}
