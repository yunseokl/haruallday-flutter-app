# 하루올데이 플러터 앱

하루올데이 강아지 브랜드를 위한 완전한 이커머스 플러터 앱입니다. CRM 및 타겟팅 기능을 포함하여 고객이 제품을 쉽게 구매할 수 있도록 설계되었습니다.

## 주요 기능

### 🔐 사용자 인증
- 로그인 및 회원가입
- 스플래시 화면
- 사용자 프로필 관리

### 🛍️ 상품 관리
- 상품 목록 및 검색
- 상품 상세 정보
- 카테고리별 분류
- 개인화 추천 시스템

### 🐕 반려견 관리
- 내 반려견 등록 및 관리
- 반려견별 맞춤 상품 추천
- 건강 정보 관리

### 🛒 장바구니 및 결제
- 장바구니 기능
- 쿠폰 시스템
- 다양한 결제 방법 지원
- 주문 관리

### 📊 CRM 및 분석
- 사용자 행동 분석
- 개인화 추천
- 구매 패턴 분석
- 대시보드

### 🔔 알림 시스템
- 푸시 알림
- 맞춤형 알림 설정

## 기술 스택

- **프레임워크**: Flutter 3.x
- **언어**: Dart
- **상태 관리**: Bloc/Cubit
- **데이터베이스**: Supabase
- **인증**: Supabase Auth
- **결제**: 아임포트 (Portone)
- **알림**: Firebase Cloud Messaging
- **아키텍처**: Clean Architecture

## 프로젝트 구조

```
lib/
├── core/
│   ├── constants/          # 앱 상수
│   ├── injection/          # 의존성 주입
│   ├── network/           # 네트워크 설정
│   └── services/          # 핵심 서비스
├── features/
│   ├── auth/              # 인증 기능
│   ├── home/              # 홈 화면
│   ├── products/          # 상품 관리
│   ├── pets/              # 반려견 관리
│   ├── cart/              # 장바구니
│   ├── checkout/          # 결제
│   └── profile/           # 프로필
├── shared/
│   ├── themes/            # 앱 테마
│   └── widgets/           # 공통 위젯
└── main.dart
```

## 설치 및 실행

### 사전 요구사항
- Flutter SDK 3.x 이상
- Dart SDK 3.x 이상
- Android Studio / VS Code
- Git

### 설치 방법

1. 저장소 클론
```bash
git clone https://github.com/yunseokl/haruallday-flutter-app.git
cd haruallday-flutter-app
```

2. 의존성 설치
```bash
flutter pub get
```

3. 환경 설정
- Supabase 프로젝트 생성 및 설정
- Firebase 프로젝트 생성 및 설정
- 환경 변수 파일 생성

4. 앱 실행
```bash
# 웹에서 실행
flutter run -d chrome

# 안드로이드에서 실행
flutter run -d android

# iOS에서 실행 (macOS에서만)
flutter run -d ios
```

## 빌드

### 웹 빌드
```bash
flutter build web --release
```

### 안드로이드 빌드
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS 빌드 (macOS에서만)
```bash
flutter build ios --release
```

## 환경 설정

### Supabase 설정
1. [Supabase](https://supabase.com)에서 새 프로젝트 생성
2. 데이터베이스 스키마 적용 (`haruallday_schema.sql` 참조)
3. API 키 및 URL 설정

### Firebase 설정
1. [Firebase Console](https://console.firebase.google.com)에서 새 프로젝트 생성
2. Flutter 앱 추가
3. `google-services.json` (Android) 및 `GoogleService-Info.plist` (iOS) 파일 추가

## 주요 서비스

### AuthService
사용자 인증 및 세션 관리를 담당합니다.

### ProductService
상품 정보 관리 및 검색 기능을 제공합니다.

### CartService
장바구니 기능 및 주문 관리를 담당합니다.

### PaymentService
결제 처리 및 주문 생성을 관리합니다.

### AnalyticsService
사용자 행동 분석 및 데이터 수집을 담당합니다.

### RecommendationService
개인화 추천 알고리즘을 제공합니다.

## 기여하기

1. 이 저장소를 포크합니다
2. 새 기능 브랜치를 생성합니다 (`git checkout -b feature/새기능`)
3. 변경사항을 커밋합니다 (`git commit -am '새 기능 추가'`)
4. 브랜치에 푸시합니다 (`git push origin feature/새기능`)
5. Pull Request를 생성합니다

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 문의

프로젝트에 대한 문의사항이 있으시면 이슈를 생성해 주세요.

---

**하루올데이** - 반려견과 함께하는 행복한 하루를 만들어갑니다. 🐕💕
