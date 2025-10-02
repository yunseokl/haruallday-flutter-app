import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/app_constants.dart';
import '../network/dio_client.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/pet_service.dart';
import '../services/analytics_service.dart';
import '../services/recommendation_service.dart';
import '../services/notification_service.dart';
import '../services/cart_service.dart';
import '../services/payment_service.dart';
import '../repositories/product_repository.dart';
import '../repositories/product_repository_impl.dart';
import '../../features/products/presentation/cubit/products_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Supabase 초기화
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  final supabaseClient = Supabase.instance.client;
  sl.registerLazySingleton(() => supabaseClient);

  // Firebase Messaging
  final firebaseMessaging = FirebaseMessaging.instance;
  sl.registerLazySingleton(() => firebaseMessaging);

  // Local Notifications
  final localNotifications = FlutterLocalNotificationsPlugin();
  sl.registerLazySingleton(() => localNotifications);

  // Core
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => DioClient(sl()));

  // Repositories
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl()),
  );

  // Services (레거시 - 점진적으로 Repository로 이동)
  sl.registerLazySingleton(() => AuthService(sl(), sl()));
  sl.registerLazySingleton(() => ProductService(sl()));
  sl.registerLazySingleton(() => PetService(sl()));
  sl.registerLazySingleton(() => AnalyticsService(sl(), sl()));
  sl.registerLazySingleton(() => RecommendationService(sl(), sl()));
  sl.registerLazySingleton(() => NotificationService(sl(), sl(), sl()));
  sl.registerLazySingleton(() => CartService(sl(), sl()));
  sl.registerLazySingleton(() => PaymentService(sl(), sl(), sl()));

  // Cubits (Factory로 등록 - 매번 새 인스턴스)
  sl.registerFactory(() => ProductsCubit(sl()));
}
