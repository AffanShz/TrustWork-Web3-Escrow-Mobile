import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:convert/convert.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustwork_mobile/core/config/env.dart';
import 'package:trustwork_mobile/core/constants/contracts.dart';
import 'package:trustwork_mobile/data/models/models.dart';
import 'package:trustwork_mobile/domain/entities/entities.dart';

class Web3RemoteDataSource {
  final Web3Client _client;
  final DeployedContract _trustWorkContract;
  final DeployedContract _mockUsdcContract;

  Web3RemoteDataSource()
      : _client = Web3Client(Env.rpcUrl, http.Client()),
        _trustWorkContract = DeployedContract(
          ContractAbi.fromJson(trustWorkAbi, 'TrustWork'),
          EthereumAddress.fromHex(trustWorkAddress),
        ),
        _mockUsdcContract = DeployedContract(
          ContractAbi.fromJson(mockUsdcAbi, 'MockUSDC'),
          EthereumAddress.fromHex(mockUsdcAddress),
        );

  Future<double> getUsdcBalance(String address) async {
    final result = await _client.call(
      contract: _mockUsdcContract,
      function: _mockUsdcContract.function('balanceOf'),
      params: [EthereumAddress.fromHex(address)],
    );
    final BigInt raw = result.first as BigInt;
    return raw / BigInt.from(10).pow(18);
  }

  Future<int> getProjectCount() async {
    final result = await _client.call(
      contract: _trustWorkContract,
      function: _trustWorkContract.function('projectCount'),
      params: [],
    );
    final BigInt count = result.first as BigInt;
    return count.toInt();
  }

  Future<OnChainProjectEntity?> getOnChainProject(int projectId) async {
    final result = await _client.call(
      contract: _trustWorkContract,
      function: _trustWorkContract.function('projects'),
      params: [BigInt.from(projectId)],
    );
    return OnChainProjectEntity(
      clientAddress: (result[0] as EthereumAddress).with0x,
      workerAddress: (result[1] as EthereumAddress).with0x,
      totalAmountRaw: result[2] as BigInt,
      tokenAddress: (result[3] as EthereumAddress).with0x,
      status: ProjectStatusX.fromOnChainCode((result[4] as BigInt).toInt()),
      currentMilestone: (result[5] as BigInt).toInt(),
      arbiterAddress: (result[6] as EthereumAddress).with0x,
    );
  }

  Future<void> waitForTransaction(String txHash) async {
    for (int i = 0; i < 30; i++) {
      try {
        final receipt = await _client.getTransactionReceipt(txHash);
        if (receipt != null) return;
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  String encodeApproveUsdc(BigInt amount) {
    final data = _mockUsdcContract.function('approve').encodeCall([
      EthereumAddress.fromHex(trustWorkAddress),
      amount,
    ]);
    return '0x${hex.encode(data)}';
  }

  String encodeCreateProject(String worker, BigInt amount, List<BigInt> milestonePercentages) {
    final data = _trustWorkContract.function('createProject').encodeCall([
      EthereumAddress.fromHex(worker),
      amount,
      EthereumAddress.fromHex(mockUsdcAddress),
      milestonePercentages,
    ]);
    return '0x${hex.encode(data)}';
  }

  String encodeApproveMilestone(int projectId) {
    final data = _trustWorkContract.function('approveMilestone').encodeCall([BigInt.from(projectId)]);
    return '0x${hex.encode(data)}';
  }

  String encodeTriggerDispute(int projectId) {
    final data = _trustWorkContract.function('triggerDispute').encodeCall([BigInt.from(projectId)]);
    return '0x${hex.encode(data)}';
  }

  String encodeResolveDispute(int projectId, int clientPct, int workerPct) {
    final data = _trustWorkContract.function('resolveDispute').encodeCall([
      BigInt.from(projectId),
      BigInt.from(clientPct),
      BigInt.from(workerPct),
    ]);
    return '0x${hex.encode(data)}';
  }
}

class SupabaseRemoteDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ProjectModel>> getProjects(String address) async {
    final response = await _client
        .from('projects')
        .select()
        .or('client_address.eq.$address,freelancer_address.eq.$address')
        .order('created_at', ascending: false);

    return (response as List).map((e) => ProjectModel.fromJson(e)).toList();
  }

  Future<ProjectModel> createProject(ProjectModel project) async {
    final response = await _client
        .from('projects')
        .insert(project.toJson())
        .select()
        .single();

    return ProjectModel.fromJson(response);
  }

  Future<void> updateProjectStatus(String projectId, String status) async {
    await _client.from('projects').update({'status': status}).eq('id', projectId);
  }

  Future<List<MilestoneModel>> getMilestones(String projectId) async {
    final response = await _client
        .from('milestones')
        .select()
        .eq('project_id', projectId)
        .order('milestone_index', ascending: true);

    return (response as List).map((e) => MilestoneModel.fromJson(e)).toList();
  }

  Future<void> createMilestones(List<MilestoneModel> milestones) async {
    final data = milestones.map((m) => m.toJson()).toList();
    await _client.from('milestones').insert(data);
  }

  Future<void> updateMilestoneStatus(String milestoneId, String status, {String? cid}) async {
    final data = <String, dynamic>{'status': status};
    if (cid != null) {
      data['deliverable_cid'] = cid;
    }
    await _client.from('milestones').update(data).eq('id', milestoneId);
  }
}

class IpfsRemoteDataSource {
  Future<String> uploadToPinata(String filePath) async {
    final uri = Uri.parse("https://api.pinata.cloud/pinning/pinFileToIPFS");
    final request = http.MultipartRequest("POST", uri)
      ..headers["Authorization"] = "Bearer ${Env.pinataJwt}"
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["IpfsHash"];
    } else {
      throw Exception("Gagal upload file ke IPFS: ${response.body}");
    }
  }
}

class WalletConnectDataSource {
  static const String _manualAddressKey = 'saved_manual_address';
  ReownAppKitModal? _appKitModal;
  String? _manualAddress;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _manualAddress = prefs.getString(_manualAddressKey);
    } catch (_) {}
  }

  ReownAppKitModal? get modal => _appKitModal;
  String? get currentAddress {
    if (_manualAddress != null && _manualAddress!.isNotEmpty) {
      return _manualAddress;
    }
    return _appKitModal?.session?.getAddress('eip155');
  }

  bool get isConnected => currentAddress != null && currentAddress!.isNotEmpty;

  void setManualAddress(String address) {
    _manualAddress = address;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_manualAddressKey, address);
    }).catchError((_) {});
  }

  void disconnect() {
    _manualAddress = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_manualAddressKey);
    }).catchError((_) {});
    _appKitModal?.disconnect();
  }

  void setModal(ReownAppKitModal modal) {
    _appKitModal = modal;
  }

  Future<String> sendTransaction(String to, String data, {String value = '0x0'}) async {
    if (_manualAddress != null && _manualAddress!.isNotEmpty) {
      // In demo mode without signer, simulate transaction hash
      return '0xsimulated${DateTime.now().millisecondsSinceEpoch}';
    }

    if (_appKitModal == null || !_appKitModal!.isConnected) {
      throw Exception('Wallet not connected');
    }

    final topic = _appKitModal!.session?.topic;
    final chainId = _appKitModal!.selectedChain?.chainId ?? 'eip155:${Env.chainId}';
    if (topic == null) throw Exception('No active session');

    final result = await _appKitModal!.request(
      topic: topic,
      chainId: chainId,
      request: SessionRequestParams(
        method: 'eth_sendTransaction',
        params: [
          {
            'from': currentAddress,
            'to': to,
            'data': data,
            'value': value,
          }
        ],
      ),
    );
    return result.toString();
  }
}
