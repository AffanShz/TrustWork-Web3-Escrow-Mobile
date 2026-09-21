class Failure {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Network connection failed'});
}

class BlockchainFailure extends Failure {
  const BlockchainFailure({super.message = 'Blockchain transaction failed'});
}

class WalletNotConnectedFailure extends Failure {
  const WalletNotConnectedFailure() : super(message: 'Wallet not connected');
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

// Lightweight Functional Either implementation
abstract class Either<L, R> {
  const Either();

  bool get isLeft => this is Left<L, R>;
  bool get isRight => this is Right<L, R>;

  L? get left => isLeft ? (this as Left<L, R>).value : null;
  R? get right => isRight ? (this as Right<L, R>).value : null;

  T fold<T>(T Function(L left) fnL, T Function(R right) fnR) {
    if (isLeft) {
      return fnL((this as Left<L, R>).value);
    } else {
      return fnR((this as Right<L, R>).value);
    }
  }
}

class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);
}

class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);
}

