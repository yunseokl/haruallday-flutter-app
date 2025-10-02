# 하루올데이 (HaruAllDay) - 강아지 브랜드 CRM 및 쇼핑 앱

하루올데이는 반려견과 함께하는 건강한 하루를 위한 종합 쇼핑 및 CRM 앱입니다.

## 주요 기능

### 🛍️ 쇼핑 기능
- 반려견 용품 카테고리별 탐색
- 상품 검색 및 필터링
- 장바구니 및 찜하기
- 주문 및 결제 (아임포트 연동)
- 쿠폰 및 할인 적용

### 🐕 반려견 관리
- 반려견 프로필 등록 및 관리
- 건강 기록 추적
- 맞춤형 상품 추천

### 👤 사용자 기능
- 이메일/비밀번호 회원가입 및 로그인
- 게스트 모드 지원
- 주문 내역 조회
- 프로필 관리

### 📊 CRM 대시보드
- 구매 통계 및 분석
- 고객 활동 추적
- 사용자 행동 분석

## 기술 스택

### Frontend
- **Framework**: Flutter 3.5.4+
- **상태 관리**: flutter_bloc
- **의존성 주입**: get_it, injectable
- **라우팅**: go_router

### Backend
- **BaaS**: Supabase (인증, 데이터베이스)
- **네트워킹**: Dio, Retrofit
- **로컬 저장소**: SharedPreferences, Hive

### 기타
- **결제**: 아임포트 (iamport_flutter)
- **푸시 알림**: Firebase Cloud Messaging
- **이미지**: cached_network_image
- **애니메이션**: Lottie

## 프로젝트 구조

```
lib/
├── core/                       # 핵심 기능
│   ├── constants/             # 앱 상수
│   ├── error/                 # 에러 처리
│   ├── injection/             # 의존성 주입
│   ├── network/               # 네트워크 클라이언트
│   ├── services/              # 비즈니스 서비스
│   └── utils/                 # 유틸리티 함수
├── features/                  # 기능별 모듈
│   ├── auth/                 # 인증
│   ├── cart/                 # 장바구니
│   ├── checkout/             # 주문/결제
│   ├── home/                 # 홈
│   ├── pets/                 # 반려견 관리
│   ├── products/             # 상품
│   └── profile/              # 프로필
├── shared/                    # 공유 리소스
│   ├── themes/               # 테마
│   └── widgets/              # 공통 위젯
└── main.dart                  # 앱 진입점
```

## 설치 및 실행

### 1. 사전 요구사항

- Flutter SDK 3.5.4 이상
- Dart SDK 3.5.4 이상
- Android Studio / Xcode (모바일 개발 시)
- Firebase 프로젝트 (푸시 알림 사용 시)
- Supabase 프로젝트

### 2. 프로젝트 클론

```bash
git clone <repository-url>
cd haruallday-flutter-app
```

### 3. 의존성 설치

```bash
flutter pub get
```

### 4. 환경 설정

#### 4.1 환경변수 파일 설정

`.env.example` 파일을 복사하여 `.env` 파일을 생성하고 필요한 값을 입력하세요:

```bash
cp .env.example .env
```

`.env` 파일 내용:
```env
# Supabase 설정
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key

# API 설정
API_BASE_URL=https://api.haruallday.com

# 결제 설정
IAMPORT_USER_CODE=your-iamport-user-code

# 환경 (development, staging, production)
ENVIRONMENT=development
```

#### 4.2 Supabase 설정

1. [Supabase](https://supabase.com)에서 새 프로젝트 생성
2. Project Settings > API에서 URL과 anon key 복사
3. `.env` 파일에 해당 값 입력
4. Database 스키마는 별도 문서 참조

#### 4.3 Firebase 설정 (선택사항 - 푸시 알림 사용 시)

```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트 설정
flutterfire configure
```

이 명령어는 `lib/firebase_options.dart` 파일을 자동으로 생성합니다.

#### 4.4 Assets 추가

필요한 리소스 파일을 해당 디렉토리에 추가하세요:

- `assets/images/` - 이미지 파일
- `assets/icons/` - 아이콘 파일
- `assets/animations/` - Lottie 애니메이션 파일
- `assets/fonts/` - 폰트 파일 (NotoSansKR-Regular.ttf, NotoSansKR-Bold.ttf)

### 5. 앱 실행

```bash
# 개발 모드
flutter run

# 릴리즈 모드
flutter run --release
```

### 6. 빌드

```bash
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS
flutter build ios

# Web
flutter build web
```

## 개발 가이드

### 코드 생성

프로젝트에서 코드 생성이 필요한 경우:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 테스트 실행

```bash
flutter test
```

### 코드 분석

```bash
flutter analyze
```

### 코드 포맷팅

```bash
flutter format lib/
```

## 환경별 설정

### Development (개발)
```env
ENVIRONMENT=development
```
- 디버그 로그 활성화
- 테스트 API 사용

### Staging (스테이징)
```env
ENVIRONMENT=staging
```
- 제한적 로그
- 스테이징 API 사용

### Production (프로덕션)
```env
ENVIRONMENT=production
```
- 로그 최소화
- 프로덕션 API 사용

## 문제 해결

### Firebase 초기화 오류
Firebase를 사용하지 않는 경우, 앱은 Firebase 없이도 정상적으로 동작합니다. `main.dart`의 Firebase 초기화는 try-catch로 감싸져 있습니다.

### Assets not found 오류
필요한 asset 파일들이 해당 디렉토리에 있는지 확인하세요. 최소한 `.gitkeep` 파일이 있어야 합니다.

### Supabase 연결 오류
- `.env` 파일의 SUPABASE_URL과 SUPABASE_ANON_KEY가 올바른지 확인
- Supabase 프로젝트의 API 설정 확인
- 네트워크 연결 확인

## 주요 패키지

| 패키지 | 용도 |
|--------|------|
| flutter_bloc | 상태 관리 |
| get_it | 의존성 주입 |
| supabase_flutter | 백엔드 서비스 |
| dio | HTTP 클라이언트 |
| go_router | 라우팅 |
| flutter_dotenv | 환경변수 관리 |
| iamport_flutter | 결제 |
| firebase_messaging | 푸시 알림 |
| cached_network_image | 이미지 캐싱 |

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다.

## 기여

버그 리포트, 기능 제안, Pull Request는 언제나 환영합니다!

## 문의

문의사항이 있으시면 이슈를 등록해주세요.
