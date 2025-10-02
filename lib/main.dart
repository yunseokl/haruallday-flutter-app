import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/injection/injection_container.dart' as di;
import 'core/router/app_router.dart';
import 'shared/themes/app_theme.dart';
import 'core/services/notification_service.dart';

// 백그라운드 메시지 핸들러
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경변수 로드
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('Warning: .env file not found. Using fallback values.');
  }

  // Firebase 초기화
  try {
    await Firebase.initializeApp();
    // 백그라운드 메시지 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('Warning: Firebase initialization failed: $e');
  }

  // 의존성 주입 초기화
  await di.init();

  runApp(const HaruAllDayApp());
}

class HaruAllDayApp extends StatefulWidget {
  const HaruAllDayApp({super.key});

  @override
  State<HaruAllDayApp> createState() => _HaruAllDayAppState();
}

class _HaruAllDayAppState extends State<HaruAllDayApp> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      final notificationService = di.sl<NotificationService>();
      await notificationService.initialize();
    } catch (e) {
      print('Failed to initialize notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '하루올데이',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
