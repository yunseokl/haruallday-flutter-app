import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final SupabaseClient _supabase;
  final Logger _logger = Logger();

  NotificationService(
    this._firebaseMessaging,
    this._localNotifications,
    this._supabase,
  );

  /// 알림 서비스 초기화
  Future<void> initialize() async {
    try {
      // Firebase 메시징 권한 요청
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.i('User granted permission for notifications');
      } else {
        _logger.w('User declined or has not accepted permission for notifications');
        return;
      }

      // 로컬 알림 초기화
      await _initializeLocalNotifications();

      // FCM 토큰 가져오기 및 저장
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveFCMToken(token);
      }

      // 토큰 갱신 리스너
      _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);

      // 포그라운드 메시지 처리
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 백그라운드 메시지 처리
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // 앱이 종료된 상태에서 알림으로 앱을 열었을 때
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }

    } catch (e) {
      _logger.e('Failed to initialize notification service: $e');
    }
  }

  /// 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// FCM 토큰 저장
  Future<void> _saveFCMToken(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _supabase.from('user_fcm_tokens').upsert({
          'user_id': userId,
          'fcm_token': token,
          'updated_at': DateTime.now().toIso8601String(),
        });
        _logger.i('FCM token saved: $token');
      }
    } catch (e) {
      _logger.e('Failed to save FCM token: $e');
    }
  }

  /// 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('Received foreground message: ${message.messageId}');
    
    // 로컬 알림으로 표시
    _showLocalNotification(
      title: message.notification?.title ?? '하루올데이',
      body: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
    );

    // 알림 데이터베이스에 저장
    _saveNotificationToDatabase(message);
  }

  /// 백그라운드 메시지 처리
  void _handleBackgroundMessage(RemoteMessage message) {
    _logger.i('Received background message: ${message.messageId}');
    
    // 알림 클릭 시 해당 페이지로 이동하는 로직
    final data = message.data;
    if (data.containsKey('action')) {
      _handleNotificationAction(data['action'], data);
    }
  }

  /// 로컬 알림 표시
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'haruallday_channel',
      '하루올데이 알림',
      channelDescription: '하루올데이 앱의 알림입니다.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        if (data.containsKey('action')) {
          _handleNotificationAction(data['action'], data);
        }
      } catch (e) {
        _logger.e('Failed to parse notification payload: $e');
      }
    }
  }

  /// 알림 액션 처리
  void _handleNotificationAction(String action, Map<String, dynamic> data) {
    switch (action) {
      case 'open_product':
        final productId = data['product_id'];
        if (productId != null) {
          // 제품 상세 페이지로 이동
          _logger.i('Navigate to product: $productId');
        }
        break;
      case 'open_order':
        final orderId = data['order_id'];
        if (orderId != null) {
          // 주문 상세 페이지로 이동
          _logger.i('Navigate to order: $orderId');
        }
        break;
      case 'open_health_tip':
        final tipId = data['tip_id'];
        if (tipId != null) {
          // 건강 팁 페이지로 이동
          _logger.i('Navigate to health tip: $tipId');
        }
        break;
      default:
        // 홈 페이지로 이동
        _logger.i('Navigate to home');
    }
  }

  /// 알림을 데이터베이스에 저장
  Future<void> _saveNotificationToDatabase(RemoteMessage message) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _supabase.from('notifications').insert({
          'user_id': userId,
          'title': message.notification?.title ?? '',
          'message': message.notification?.body ?? '',
          'type': message.data['type'] ?? 'general',
          'action_url': message.data['action_url'],
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      _logger.e('Failed to save notification to database: $e');
    }
  }

  /// 맞춤형 알림 전송
  Future<void> sendPersonalizedNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // FCM 토큰 가져오기
      final tokenResponse = await _supabase
          .from('user_fcm_tokens')
          .select('fcm_token')
          .eq('user_id', userId)
          .single();

      final fcmToken = tokenResponse['fcm_token'] as String?;
      if (fcmToken == null) {
        _logger.w('No FCM token found for user: $userId');
        return;
      }

      // 알림 데이터베이스에 저장
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'action_url': data?['action_url'],
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      // FCM을 통해 푸시 알림 전송 (실제 구현에서는 서버 사이드에서 처리)
      _logger.i('Notification sent to user $userId: $title');

    } catch (e) {
      _logger.e('Failed to send personalized notification: $e');
    }
  }

  /// 제품 추천 알림
  Future<void> sendProductRecommendationNotification({
    required String userId,
    required String productName,
    required String productId,
  }) async {
    await sendPersonalizedNotification(
      userId: userId,
      title: '맞춤 제품 추천',
      message: '$productName이(가) 우리 아이에게 좋을 것 같아요!',
      type: 'recommendation',
      data: {
        'action': 'open_product',
        'product_id': productId,
      },
    );
  }

  /// 주문 상태 알림
  Future<void> sendOrderStatusNotification({
    required String userId,
    required String orderId,
    required String status,
  }) async {
    String title = '';
    String message = '';

    switch (status) {
      case 'paid':
        title = '결제 완료';
        message = '주문이 결제되었습니다. 곧 배송 준비에 들어갑니다.';
        break;
      case 'shipped':
        title = '배송 시작';
        message = '주문하신 제품이 배송을 시작했습니다.';
        break;
      case 'delivered':
        title = '배송 완료';
        message = '주문하신 제품이 배송 완료되었습니다. 리뷰를 남겨주세요!';
        break;
    }

    if (title.isNotEmpty) {
      await sendPersonalizedNotification(
        userId: userId,
        title: title,
        message: message,
        type: 'order',
        data: {
          'action': 'open_order',
          'order_id': orderId,
        },
      );
    }
  }

  /// 건강 팁 알림
  Future<void> sendHealthTipNotification({
    required String userId,
    required String tipTitle,
    required String tipId,
  }) async {
    await sendPersonalizedNotification(
      userId: userId,
      title: '새로운 건강 정보',
      message: '$tipTitle - 우리 아이 건강을 위한 유용한 정보를 확인해보세요!',
      type: 'health',
      data: {
        'action': 'open_health_tip',
        'tip_id': tipId,
      },
    );
  }

  /// 정기 구독 알림
  Future<void> sendSubscriptionReminder({
    required String userId,
    required String productName,
    required DateTime nextDeliveryDate,
  }) async {
    final daysUntilDelivery = nextDeliveryDate.difference(DateTime.now()).inDays;
    
    await sendPersonalizedNotification(
      userId: userId,
      title: '정기 구독 알림',
      message: '$productName이(가) ${daysUntilDelivery}일 후 배송됩니다.',
      type: 'subscription',
      data: {
        'action': 'open_subscription',
      },
    );
  }

  /// 사용자 알림 목록 가져오기
  Future<List<Map<String, dynamic>>> getUserNotifications({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      _logger.e('Failed to get user notifications: $e');
      return [];
    }
  }

  /// 알림 읽음 처리
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      _logger.e('Failed to mark notification as read: $e');
    }
  }

  /// 모든 알림 읽음 처리
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      _logger.e('Failed to mark all notifications as read: $e');
    }
  }

  /// 읽지 않은 알림 개수
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      _logger.e('Failed to get unread notification count: $e');
      return 0;
    }
  }
}

/// 백그라운드 메시지 핸들러 (최상위 함수여야 함)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final logger = Logger();
  logger.i('Handling a background message: ${message.messageId}');
}
