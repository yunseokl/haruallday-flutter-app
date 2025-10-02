import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Supabase 설정 (환경변수에서 로드)
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: 'https://your-project.supabase.co');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY', fallback: 'your-anon-key');

  // 앱 정보
  static const String appName = '하루올데이';
  static const String appVersion = '1.0.0';

  // API 엔드포인트 (환경변수에서 로드)
  static String get baseUrl => dotenv.get('API_BASE_URL', fallback: 'https://api.haruallday.com');

  // 페이지네이션
  static const int defaultPageSize = 20;

  // 이미지 설정
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  // 캐시 설정
  static const Duration cacheExpiration = Duration(hours: 24);

  // 결제 설정 (환경변수에서 로드)
  static String get iamportUserCode => dotenv.get('IAMPORT_USER_CODE', fallback: 'your-iamport-user-code');

  // 소셜 로그인 (환경변수에서 로드)
  static String get googleClientId => dotenv.get('GOOGLE_CLIENT_ID', fallback: '');
  static String get kakaoNativeAppKey => dotenv.get('KAKAO_NATIVE_APP_KEY', fallback: '');

  // 환경 설정
  static String get environment => dotenv.get('ENVIRONMENT', fallback: 'development');
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';

  // 에러 메시지
  static const String networkErrorMessage = '네트워크 연결을 확인해주세요.';
  static const String unknownErrorMessage = '알 수 없는 오류가 발생했습니다.';
  static const String authErrorMessage = '인증에 실패했습니다.';
}
