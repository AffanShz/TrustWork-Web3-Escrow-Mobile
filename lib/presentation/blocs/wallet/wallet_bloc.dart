import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trustwork_mobile/data/datasources/datasources.dart';
import 'package:trustwork_mobile/domain/entities/entities.dart';
import 'package:trustwork_mobile/domain/repositories/repositories.dart';

// --- Events ---
abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class WalletCheckStatusEvent extends WalletEvent {}

class WalletSetManualAddressEvent extends WalletEvent {
  final String address;
  const WalletSetManualAddressEvent(this.address);

  @override
  List<Object?> get props => [address];
}

class WalletDisconnectEvent extends WalletEvent {}

class WalletRefreshBalanceEvent extends WalletEvent {}

// --- States ---
abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitialState extends WalletState {}

class WalletLoadingState extends WalletState {}

class WalletConnectedState extends WalletState {
  final WalletInfo walletInfo;
  const WalletConnectedState(this.walletInfo);

  @override
  List<Object?> get props => [walletInfo];
}

class WalletDisconnectedState extends WalletState {}

class WalletErrorState extends WalletState {
  final String message;
  const WalletErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository walletRepository;
  final WalletConnectDataSource walletConnectDataSource;

  WalletBloc({
    required this.walletRepository,
    required this.walletConnectDataSource,
  }) : super(WalletInitialState()) {
    on<WalletCheckStatusEvent>(_onCheckStatus);
    on<WalletSetManualAddressEvent>(_onSetManualAddress);
    on<WalletDisconnectEvent>(_onDisconnect);
    on<WalletRefreshBalanceEvent>(_onRefreshBalance);
  }

  Future<void> _onCheckStatus(
    WalletCheckStatusEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoadingState());
    final info = await walletRepository.currentInfo;
    if (info.isConnected) {
      emit(WalletConnectedState(info));
    } else {
      emit(WalletDisconnectedState());
    }
  }

  Future<void> _onSetManualAddress(
    WalletSetManualAddressEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoadingState());
    walletConnectDataSource.setManualAddress(event.address);
    final info = await walletRepository.currentInfo;
    emit(WalletConnectedState(info));
  }

  Future<void> _onDisconnect(
    WalletDisconnectEvent event,
    Emitter<WalletState> emit,
  ) async {
    await walletRepository.disconnect();
    emit(WalletDisconnectedState());
  }

  Future<void> _onRefreshBalance(
    WalletRefreshBalanceEvent event,
    Emitter<WalletState> emit,
  ) async {
    final info = await walletRepository.currentInfo;
    if (info.isConnected) {
      emit(WalletConnectedState(info));
    } else {
      emit(WalletDisconnectedState());
    }
  }
}
