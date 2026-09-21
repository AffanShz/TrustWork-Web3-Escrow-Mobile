import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? '';
      
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static String get pinataJwt =>
      dotenv.env['PINATA_JWT'] ?? '';

  static String get walletConnectProjectId =>
      dotenv.env['WALLETCONNECT_PROJECT_ID'] ?? '';

  static String get rpcUrl =>
      dotenv.env['RPC_URL'] ?? 'https://ethereum-sepolia-rpc.publicnode.com';

  static int get chainId =>
      int.tryParse(dotenv.env['CHAIN_ID'] ?? '11155111') ?? 11155111;
}
