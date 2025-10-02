/// 입력 유효성 검증 유틸리티 함수
class Validators {
  /// 이메일 유효성 검증
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이메일을 입력해주세요';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return '올바른 이메일 형식을 입력해주세요';
    }

    return null;
  }

  /// 비밀번호 유효성 검증
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }

    if (value.length < minLength) {
      return '비밀번호는 $minLength자 이상이어야 합니다';
    }

    return null;
  }

  /// 비밀번호 확인 검증
  static String? validatePasswordConfirm(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해주세요';
    }

    if (value != password) {
      return '비밀번호가 일치하지 않습니다';
    }

    return null;
  }

  /// 전화번호 유효성 검증
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '전화번호를 입력해주세요';
    }

    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.length < 10 || cleaned.length > 11) {
      return '올바른 전화번호를 입력해주세요';
    }

    return null;
  }

  /// 이름 유효성 검증
  static String? validateName(String? value, {int minLength = 2, int maxLength = 20}) {
    if (value == null || value.trim().isEmpty) {
      return '이름을 입력해주세요';
    }

    if (value.trim().length < minLength) {
      return '이름은 $minLength자 이상이어야 합니다';
    }

    if (value.trim().length > maxLength) {
      return '이름은 $maxLength자 이하여야 합니다';
    }

    return null;
  }

  /// 필수 입력 검증
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName을(를) 입력해주세요' : '필수 입력 항목입니다';
    }

    return null;
  }

  /// 숫자 유효성 검증
  static String? validateNumber(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName을(를) 입력해주세요' : '숫자를 입력해주세요';
    }

    if (int.tryParse(value) == null) {
      return '올바른 숫자를 입력해주세요';
    }

    return null;
  }

  /// 범위 검증 (최소값, 최대값)
  static String? validateRange(
    String? value, {
    int? min,
    int? max,
    String? fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName을(를) 입력해주세요' : '값을 입력해주세요';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return '올바른 숫자를 입력해주세요';
    }

    if (min != null && number < min) {
      return '최소 $min 이상이어야 합니다';
    }

    if (max != null && number > max) {
      return '최대 $max 이하여야 합니다';
    }

    return null;
  }

  /// 길이 검증
  static String? validateLength(
    String? value, {
    int? minLength,
    int? maxLength,
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return fieldName != null ? '$fieldName을(를) 입력해주세요' : '값을 입력해주세요';
    }

    if (minLength != null && value.length < minLength) {
      return '최소 $minLength자 이상 입력해주세요';
    }

    if (maxLength != null && value.length > maxLength) {
      return '최대 $maxLength자까지 입력 가능합니다';
    }

    return null;
  }

  /// URL 유효성 검증
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'URL을 입력해주세요';
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return '올바른 URL 형식을 입력해주세요';
    }

    return null;
  }

  /// 주소 유효성 검증
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '주소를 입력해주세요';
    }

    if (value.trim().length < 5) {
      return '올바른 주소를 입력해주세요';
    }

    return null;
  }
}
