import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/injection/injection_container.dart' as di;
import 'shared/themes/app_theme.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'core/services/notification_service.dart';

// 백그라운드 메시지 핸들러
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화
  await Firebase.initializeApp();
  
  // 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
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
    return MaterialApp(
      title: '하루올데이',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
