import 'package:flutter/material.dart';
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

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    try {
      await dotenv.load(fileName: '.env.example');
    } catch (_) {}
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
