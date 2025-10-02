import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_error.dart';

/// 전역 에러 핸들러
class ErrorHandler {
  static final Logger _logger = Logger();

  /// 에러를 AppError로 변환
  static AppError handleError(dynamic error) {
    _logger.e('Error occurred: $error');

    if (error is AppError) {
      return error;
    }

    // Dio 에러 처리
    if (error is DioException) {
      return _handleDioError(error);
    }

    // Supabase 에러 처리
    if (error is AuthException) {
      return AuthError(
        message: error.message,
        code: error.statusCode,
        originalError: error,
      );
    }

    if (error is PostgrestException) {
      return ServerError(
        message: error.message,
        code: error.code,
        originalError: error,
      );
    }

    // 일반 Exception 처리
    if (error is Exception) {
      return UnknownError(
        message: error.toString(),
        originalError: error,
      );
    }

    // 기타 에러
    return UnknownError(
      message: error.toString(),
      originalError: error,
    );
  }

  /// Dio 에러를 AppError로 변환
  static AppError _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutError();

      case DioExceptionType.connectionError:
        return const NetworkError();

      case DioExceptionType.badResponse:
        return _handleStatusCodeError(error);

      case DioExceptionType.cancel:
        return const UnknownError(message: '요청이 취소되었습니다.');

      case DioExceptionType.unknown:
        return const NetworkError();

      default:
        return UnknownError(
          message: error.message ?? '알 수 없는 오류가 발생했습니다.',
          originalError: error,
        );
    }
  }

  /// HTTP 상태 코드에 따른 에러 처리
  static AppError _handleStatusCodeError(DioException error) {
    final statusCode = error.response?.statusCode;
    final message = error.response?.data?['message'] ?? error.message;

    switch (statusCode) {
      case 400:
        return ValidationError(
          message: message ?? '잘못된 요청입니다.',
          code: statusCode.toString(),
          originalError: error,
        );

      case 401:
        return AuthError(
          message: '인증이 필요합니다.',
          code: statusCode.toString(),
          originalError: error,
        );

      case 403:
        return PermissionError(
          message: '접근 권한이 없습니다.',
          code: statusCode.toString(),
          originalError: error,
        );

      case 404:
        return NotFoundError(
          message: message ?? '요청한 데이터를 찾을 수 없습니다.',
          code: statusCode.toString(),
          originalError: error,
        );

      case 408:
        return const TimeoutError();

      case 500:
      case 502:
      case 503:
      case 504:
        return ServerError(
          message: '서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요.',
          code: statusCode.toString(),
          originalError: error,
        );

      default:
        return ServerError(
          message: message ?? '서버 오류가 발생했습니다.',
          code: statusCode.toString(),
          originalError: error,
        );
    }
  }

  /// 사용자 친화적인 에러 메시지 반환
  static String getUserFriendlyMessage(AppError error) {
    if (error is NetworkError) {
      return '인터넷 연결을 확인해주세요.';
    } else if (error is TimeoutError) {
      return '서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요.';
    } else if (error is AuthError) {
      return '로그인이 필요하거나 세션이 만료되었습니다.';
    } else if (error is PermissionError) {
      return '이 기능을 사용할 권한이 없습니다.';
    } else if (error is ServerError) {
      return '서버에 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
    } else if (error is ValidationError) {
      return error.message;
    } else if (error is NotFoundError) {
      return error.message;
    }

    return '오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
  }
}
