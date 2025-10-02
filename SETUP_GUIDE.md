# 하루올데이 앱 설정 가이드

## Phase 2 완료 후 필수 작업

Phase 2에서 모델 클래스와 Repository 패턴을 구현했습니다. 이제 다음 단계를 수행해야 합니다.

### 1. 패키지 설치

```bash
flutter pub get
```

### 2. 코드 생성 (JSON 직렬화)

모델 클래스에 `json_serializable`을 사용했으므로 코드 생성이 필요합니다:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

이 명령어는 다음 파일들을 생성합니다:
- `lib/core/models/user_model.g.dart`
- `lib/core/models/product_model.g.dart`
- `lib/core/models/pet_model.g.dart`
- `lib/core/models/cart_item_model.g.dart`
- `lib/core/models/order_model.g.dart`

### 3. 변경 사항 요약

#### Phase 2에서 완료한 작업:

1. **모델 클래스 생성**
   - `UserModel`, `ProductModel`, `PetModel`
   - `CartItemModel`, `OrderModel`
   - Equatable와 json_serializable 사용
   - copyWith, props 메서드 구현

2. **Repository 패턴 구현**
   - `ProductRepository` 인터페이스
   - `ProductRepositoryImpl` 구현
   - Either(dartz) 패턴으로 에러 처리

3. **Cubit 상태 관리**
   - `ProductsCubit` 생성
   - `ProductsState` (Initial, Loading, Loaded, Error)
   - Repository를 통한 데이터 로드

4. **Go Router 설정**
   - `AppRouter` 클래스 생성
   - 모든 라우트 정의
   - 인증 기반 리다이렉션
   - 에러 페이지

5. **의존성 주입 업데이트**
   - Repository 등록
   - Cubit Factory 등록
   - 레거시 서비스와 새 아키텍처 공존

6. **Main 앱 업데이트**
   - `MaterialApp.router` 사용
   - `go_router` 통합

### 4. 다음 단계

Phase 2가 완료되면 다음을 진행할 수 있습니다:

#### Option 1: 기존 코드를 새 아키텍처로 마이그레이션
- `ProductService` → `ProductRepository` 전환
- UI 컴포넌트에서 Cubit 사용
- StatefulWidget → BlocBuilder 전환

#### Option 2: 추가 기능 구현
- Auth Repository 및 Cubit
- Cart Repository 및 Cubit
- Pet Repository 및 Cubit

#### Option 3: 코드 품질 개선
- 테스트 코드 작성
- 에러 처리 강화
- 로깅 시스템 개선

### 5. 예제: ProductsPage에 Cubit 적용

기존 코드를 Cubit을 사용하도록 변경하는 예제:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/injection/injection_container.dart';
import '../cubit/products_cubit.dart';
import '../cubit/products_state.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductsCubit>()..loadAllProducts(),
      child: Scaffold(
        appBar: AppBar(title: const Text('상품 목록')),
        body: BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, state) {
            if (state is ProductsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProductsError) {
              return Center(
                child: Text(
                  ErrorHandler.getUserFriendlyMessage(state.error),
                ),
              );
            }

            if (state is ProductsLoaded) {
              return ListView.builder(
                itemCount: state.products.length,
                itemBuilder: (context, index) {
                  final product = state.products[index];
                  return ProductCard(product: product);
                },
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
```

### 6. 주의사항

- 코드 생성(`build_runner`) 실행 전까지는 빌드 에러가 발생할 수 있습니다
- `*.g.dart` 파일은 자동 생성되므로 직접 수정하지 마세요
- 모델 클래스를 수정한 후에는 다시 `build_runner`를 실행하세요

### 7. 문제 해결

#### 빌드 에러 발생 시
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 캐시 문제
```bash
flutter pub cache repair
```

#### 의존성 충돌
```bash
flutter pub upgrade
```
