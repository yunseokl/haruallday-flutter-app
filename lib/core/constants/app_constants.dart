class AppConstants {
  // Supabase 설정
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  
  // 앱 정보
  static const String appName = '하루올데이';
  static const String appVersion = '1.0.0';
  
  // API 엔드포인트
  static const String baseUrl = 'https://api.haruallday.com';
  
  // 페이지네이션
  static const int defaultPageSize = 20;
  
  // 이미지 설정
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  
  // 캐시 설정
  static const Duration cacheExpiration = Duration(hours: 24);
  
  // 결제 설정
  static const String iamportUserCode = 'your-iamport-user-code';
  
  // 푸시 알림
  static const String fcmServerKey = 'your-fcm-server-key';
  
  // 소셜 로그인
  static const String googleClientId = 'your-google-client-id';
  static const String kakaoNativeAppKey = 'your-kakao-native-app-key';
  
  // 에러 메시지
  static const String networkErrorMessage = '네트워크 연결을 확인해주세요.';
  static const String unknownErrorMessage = '알 수 없는 오류가 발생했습니다.';
  static const String authErrorMessage = '인증에 실패했습니다.';
}
