import 'package:intl/intl.dart';

/// 포맷팅 관련 유틸리티 함수
class Formatters {
  /// 숫자를 통화 형식으로 포맷 (예: 45000 -> "45,000원")
  static String formatCurrency(int amount, {bool showSymbol = true}) {
    final formatter = NumberFormat('#,###', 'ko_KR');
    final formatted = formatter.format(amount);
    return showSymbol ? '$formatted원' : formatted;
  }

  /// 숫자를 통화 형식으로 포맷 (double 버전)
  static String formatCurrencyDouble(double amount, {bool showSymbol = true}) {
    final formatter = NumberFormat('#,###.##', 'ko_KR');
    final formatted = formatter.format(amount);
    return showSymbol ? '$formatted원' : formatted;
  }

  /// 날짜를 포맷 (예: "2024-01-15" -> "2024년 1월 15일")
  static String formatDate(DateTime date, {String? pattern}) {
    final formatter = DateFormat(pattern ?? 'yyyy년 M월 d일', 'ko_KR');
    return formatter.format(date);
  }

  /// 날짜와 시간을 포맷 (예: "2024-01-15 14:30")
  static String formatDateTime(DateTime dateTime, {String? pattern}) {
    final formatter = DateFormat(pattern ?? 'yyyy-MM-dd HH:mm', 'ko_KR');
    return formatter.format(dateTime);
  }

  /// 상대 시간 표시 (예: "5분 전", "3시간 전", "2일 전")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}주 전';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else {
      return '${(difference.inDays / 365).floor()}년 전';
    }
  }

  /// 전화번호 포맷 (예: "01012345678" -> "010-1234-5678")
  static String formatPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.length == 11) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 7)}-${cleaned.substring(7)}';
    } else if (cleaned.length == 10) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }

    return phoneNumber;
  }

  /// 파일 크기 포맷 (예: 1024 -> "1 KB", 1048576 -> "1 MB")
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 퍼센트 포맷 (예: 0.15 -> "15%")
  static String formatPercentage(double value, {int decimals = 0}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  /// 숫자를 축약 포맷 (예: 1500 -> "1.5K", 1500000 -> "1.5M")
  static String formatCompactNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else if (number < 1000000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    }
  }

  /// 시간 지속시간 포맷 (예: Duration(hours: 2, minutes: 30) -> "2시간 30분")
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      if (minutes > 0) {
        return '$hours시간 $minutes분';
      }
      return '$hours시간';
    } else if (minutes > 0) {
      if (seconds > 0) {
        return '$minutes분 $seconds초';
      }
      return '$minutes분';
    } else {
      return '$seconds초';
    }
  }

  /// 주문 상태를 한글로 변환
  static String formatOrderStatus(String status) {
    switch (status) {
      case 'pending':
        return '결제 대기';
      case 'paid':
        return '결제 완료';
      case 'payment_failed':
        return '결제 실패';
      case 'preparing':
        return '상품 준비중';
      case 'shipped':
        return '배송중';
      case 'delivered':
        return '배송 완료';
      case 'cancelled':
        return '주문 취소';
      case 'refunded':
        return '환불 완료';
      default:
        return status;
    }
  }

  /// 결제 방법을 한글로 변환
  static String formatPaymentMethod(String method) {
    switch (method) {
      case 'card':
        return '신용카드';
      case 'bank_transfer':
        return '계좌이체';
      case 'kakaopay':
        return '카카오페이';
      case 'naverpay':
        return '네이버페이';
      case 'payco':
        return '페이코';
      default:
        return method;
    }
  }
}
