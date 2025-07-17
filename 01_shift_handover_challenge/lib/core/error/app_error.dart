import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';

class AppError extends Equatable {
  final String message;
  const AppError(this.message);

  @override
  List<Object?> get props => [message];
}

typedef AppErrorOr<T> = Future<Either<AppError, T>>;
