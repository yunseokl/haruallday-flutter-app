import 'package:equatable/equatable.dart';

/// 앱 전역에서 사용하는 에러 클래스
abstract class AppError extends Equatable {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppError({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  List<Object?> get props => [message, code, originalError];

  @override
  String toString() => message;
}

/// 네트워크 관련 에러
class NetworkError extends AppError {
  const NetworkError({
    String message = '네트워크 연결을 확인해주세요.',
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

/// 인증 관련 에러
class AuthError extends AppError {
  const AuthError({
    String message = '인증에 실패했습니다.',
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

/// 서버 에러
class ServerError extends AppError {
  const ServerError({
    String message = '서버 오류가 발생했습니다.',
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

/// 유효성 검증 에러
class ValidationError extends AppError {
  const ValidationError({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

/// 권한 관련 에러
class PermissionError extends AppError {
  const PermissionError({
    String message = '권한이 없습니다.',
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

/// 데이터를 찾을 수 없음
class NotFoundError extends AppError {
  const NotFoundError({
    String message = '요청한 데이터를 찾을 수 없습니다.',
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

/// 타임아웃 에러
class TimeoutError extends AppError {
  const TimeoutError({
    String message = '요청 시간이 초과되었습니다.',
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

/// 알 수 없는 에러
class UnknownError extends AppError {
  const UnknownError({
    String message = '알 수 없는 오류가 발생했습니다.',
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}
