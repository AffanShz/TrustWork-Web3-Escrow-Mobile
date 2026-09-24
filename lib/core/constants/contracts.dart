import '../config/env.dart';

final String trustWorkAddress = Env.trustWorkAddress;
final String mockUsdcAddress = Env.mockUsdcAddress;

const String trustWorkAbi = '''[
  {"inputs":[{"internalType":"address","name":"_defaultArbiter","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},
  {"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"projectId","type":"uint256"}],"name":"Disputed","type":"event"},
  {"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"projectId","type":"uint256"},{"indexed":false,"internalType":"uint8","name":"milestoneIndex","type":"uint8"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"MilestoneApproved","type":"event"},
  {"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"projectId","type":"uint256"},{"indexed":true,"internalType":"address","name":"client","type":"address"},{"indexed":true,"internalType":"address","name":"worker","type":"address"}],"name":"ProjectCreated","type":"event"},
  {"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"projectId","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"clientAmount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"workerAmount","type":"uint256"}],"name":"Resolved","type":"event"},
  {"inputs":[{"internalType":"uint256","name":"_projectId","type":"uint256"}],"name":"approveMilestone","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"internalType":"address","name":"_worker","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"},{"internalType":"address","name":"_token","type":"address"},{"internalType":"uint8[]","name":"_milestonePercentages","type":"uint8[]"}],"name":"createProject","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[],"name":"defaultArbiter","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},
  {"inputs":[],"name":"projectCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"projectMilestones","outputs":[{"internalType":"uint8","name":"percentage","type":"uint8"},{"internalType":"bool","name":"isApproved","type":"bool"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"projects","outputs":[{"internalType":"address","name":"client","type":"address"},{"internalType":"address","name":"worker","type":"address"},{"internalType":"uint256","name":"totalAmount","type":"uint256"},{"internalType":"address","name":"token","type":"address"},{"internalType":"uint8","name":"status","type":"uint8"},{"internalType":"uint8","name":"currentMilestone","type":"uint8"},{"internalType":"address","name":"arbiter","type":"address"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"internalType":"uint256","name":"_projectId","type":"uint256"},{"internalType":"uint8","name":"_clientPct","type":"uint8"},{"internalType":"uint8","name":"_workerPct","type":"uint8"}],"name":"resolveDispute","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"internalType":"uint256","name":"_projectId","type":"uint256"}],"name":"triggerDispute","outputs":[],"stateMutability":"nonpayable","type":"function"}
]''';

const String mockUsdcAbi = '''[
  {"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}
]''';
