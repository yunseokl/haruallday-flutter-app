import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final SupabaseClient _supabaseClient;
  final SharedPreferences _prefs;

  AuthService(this._supabaseClient, this._prefs);

  // 현재 사용자 정보 가져오기
  User? get currentUser => _supabaseClient.auth.currentUser;
  
  // 현재 사용자 ID 가져오기
  String? get currentUserId => _supabaseClient.auth.currentUser?.id;
  
  // 로그인 상태 확인
  bool get isLoggedIn => _supabaseClient.auth.currentUser != null;

  // 이메일/비밀번호로 회원가입
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
  }) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone_number': phoneNumber,
        },
      );

      if (response.user != null) {
        // 사용자 프로필 정보를 별도 테이블에 저장
        await _createUserProfile(response.user!.id, name, email, phoneNumber);
        
        return {
          'success': true,
          'user': response.user,
          'message': '회원가입이 완료되었습니다.',
        };
      } else {
        return {
          'success': false,
          'message': '회원가입에 실패했습니다.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '회원가입 중 오류가 발생했습니다: $e',
      };
    }
  }

  // 이메일/비밀번호로 로그인
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // 로그인 성공 시 로컬에 저장
        await _saveLoginState(true);
        
        return {
          'success': true,
          'user': response.user,
          'message': '로그인되었습니다.',
        };
      } else {
        return {
          'success': false,
          'message': '로그인에 실패했습니다.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '로그인 중 오류가 발생했습니다: $e',
      };
    }
  }

  // 로그아웃
  Future<Map<String, dynamic>> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
      await _saveLoginState(false);
      
      return {
        'success': true,
        'message': '로그아웃되었습니다.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '로그아웃 중 오류가 발생했습니다: $e',
      };
    }
  }

  // 비밀번호 재설정 이메일 발송
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
      
      return {
        'success': true,
        'message': '비밀번호 재설정 이메일이 발송되었습니다.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '비밀번호 재설정 중 오류가 발생했습니다: $e',
      };
    }
  }

  // 사용자 프로필 정보 가져오기
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUserId == null) return null;

      final response = await _supabaseClient
          .from('user_profiles')
          .select()
          .eq('user_id', currentUserId!)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // 사용자 프로필 정보 업데이트
  Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      if (currentUserId == null) {
        return {
          'success': false,
          'message': '로그인이 필요합니다.',
        };
      }

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (address != null) updateData['address'] = address;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _supabaseClient
          .from('user_profiles')
          .update(updateData)
          .eq('user_id', currentUserId!);

      return {
        'success': true,
        'message': '프로필이 업데이트되었습니다.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '프로필 업데이트 중 오류가 발생했습니다: $e',
      };
    }
  }

  // 자동 로그인 확인
  Future<bool> checkAutoLogin() async {
    try {
      final session = _supabaseClient.auth.currentSession;
      if (session != null && !session.isExpired) {
        return true;
      }
      
      // 세션이 만료되었거나 없으면 로컬 저장소에서 제거
      await _saveLoginState(false);
      return false;
    } catch (e) {
      print('Error checking auto login: $e');
      return false;
    }
  }

  // 사용자 프로필 생성 (회원가입 시)
  Future<void> _createUserProfile(
    String userId,
    String name,
    String email,
    String? phoneNumber,
  ) async {
    try {
      await _supabaseClient.from('user_profiles').insert({
        'user_id': userId,
        'name': name,
        'email': email,
        'phone_number': phoneNumber,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating user profile: $e');
      // 프로필 생성 실패해도 회원가입은 성공으로 처리
    }
  }

  // 로그인 상태 로컬 저장
  Future<void> _saveLoginState(bool isLoggedIn) async {
    await _prefs.setBool('is_logged_in', isLoggedIn);
  }

  // 인증 상태 변경 리스너
  Stream<AuthState> get authStateChanges => _supabaseClient.auth.onAuthStateChange;
}
