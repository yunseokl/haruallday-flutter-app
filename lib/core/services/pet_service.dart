import 'package:supabase_flutter/supabase_flutter.dart';

class PetService {
  final SupabaseClient _supabaseClient;

  PetService(this._supabaseClient);

  // 사용자의 반려견 목록 가져오기
  Future<List<Map<String, dynamic>>> getUserPets(String userId) async {
    try {
      final response = await _supabaseClient
          .from('pets')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user pets: $e');
      return [];
    }
  }

  // 반려견 정보 가져오기
  Future<Map<String, dynamic>?> getPetById(String petId) async {
    try {
      final response = await _supabaseClient
          .from('pets')
          .select('*')
          .eq('id', petId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting pet by id: $e');
      return null;
    }
  }

  // 새 반려견 등록
  Future<Map<String, dynamic>> addPet({
    required String userId,
    required String name,
    required String breed,
    required DateTime birthDate,
    required String gender,
    required double weight,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final petData = {
        'user_id': userId,
        'name': name,
        'breed': breed,
        'birth_date': birthDate.toIso8601String(),
        'gender': gender,
        'weight': weight,
        'description': description,
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseClient
          .from('pets')
          .insert(petData)
          .select()
          .single();

      return {
        'success': true,
        'pet': response,
        'message': '반려견이 등록되었습니다.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '반려견 등록 중 오류가 발생했습니다: $e',
      };
    }
  }

  // 반려견 정보 수정
  Future<Map<String, dynamic>> updatePet({
    required String petId,
    String? name,
    String? breed,
    DateTime? birthDate,
    String? gender,
    double? weight,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (breed != null) updateData['breed'] = breed;
      if (birthDate != null) updateData['birth_date'] = birthDate.toIso8601String();
      if (gender != null) updateData['gender'] = gender;
      if (weight != null) updateData['weight'] = weight;
      if (description != null) updateData['description'] = description;
      if (imageUrl != null) updateData['image_url'] = imageUrl;

      await _supabaseClient
          .from('pets')
          .update(updateData)
          .eq('id', petId);

      return {
        'success': true,
        'message': '반려견 정보가 수정되었습니다.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '반려견 정보 수정 중 오류가 발생했습니다: $e',
      };
    }
  }

  // 반려견 삭제
  Future<Map<String, dynamic>> deletePet(String petId) async {
    try {
      await _supabaseClient
          .from('pets')
          .delete()
          .eq('id', petId);

      return {
        'success': true,
        'message': '반려견 정보가 삭제되었습니다.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '반려견 삭제 중 오류가 발생했습니다: $e',
      };
    }
  }

  // 반려견 건강 기록 가져오기
  Future<List<Map<String, dynamic>>> getPetHealthRecords(String petId) async {
    try {
      final response = await _supabaseClient
          .from('health_records')
          .select('*')
          .eq('pet_id', petId)
          .order('record_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting pet health records: $e');
      return [];
    }
  }

  // 건강 기록 추가
  Future<Map<String, dynamic>> addHealthRecord({
    required String petId,
    required String recordType,
    required DateTime recordDate,
    required String description,
    String? veterinarian,
    String? medication,
    double? weight,
    double? temperature,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final recordData = {
        'pet_id': petId,
        'record_type': recordType,
        'record_date': recordDate.toIso8601String(),
        'description': description,
        'veterinarian': veterinarian,
        'medication': medication,
        'weight': weight,
        'temperature': temperature,
        'additional_data': additionalData,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseClient
          .from('health_records')
          .insert(recordData)
          .select()
          .single();

      return {
        'success': true,
        'record': response,
        'message': '건강 기록이 추가되었습니다.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '건강 기록 추가 중 오류가 발생했습니다: $e',
      };
    }
  }

  // 건강 기록 수정
  Future<Map<String, dynamic>> updateHealthRecord({
    required String recordId,
    String? recordType,
    DateTime? recordDate,
    String? description,
    String? veterinarian,
    String? medication,
    double? weight,
    double? temperature,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (recordType != null) updateData['record_type'] = recordType;
      if (recordDate != null) updateData['record_date'] = recordDate.toIso8601String();
      if (description != null) updateData['description'] = description;
      if (veterinarian != null) updateData['veterinarian'] = veterinarian;
      if (medication != null) updateData['medication'] = medication;
      if (weight != null) updateData['weight'] = weight;
      if (temperature != null) updateData['temperature'] = temperature;
      if (additionalData != null) updateData['additional_data'] = additionalData;

      await _supabaseClient
          .from('health_records')
          .update(updateData)
          .eq('id', recordId);

      return {
        'success': true,
        'message': '건강 기록이 수정되었습니다.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '건강 기록 수정 중 오류가 발생했습니다: $e',
      };
    }
  }

  // 건강 기록 삭제
  Future<Map<String, dynamic>> deleteHealthRecord(String recordId) async {
    try {
      await _supabaseClient
          .from('health_records')
          .delete()
          .eq('id', recordId);

      return {
        'success': true,
        'message': '건강 기록이 삭제되었습니다.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '건강 기록 삭제 중 오류가 발생했습니다: $e',
      };
    }
  }

  // 반려견 나이 계산
  int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  // 반려견 품종 목록 가져오기
  List<String> getDogBreeds() {
    return [
      '골든 리트리버',
      '래브라도 리트리버',
      '시바견',
      '진돗개',
      '포메라니안',
      '치와와',
      '말티즈',
      '요크셔 테리어',
      '푸들',
      '비숑 프리제',
      '코기',
      '보더 콜리',
      '허스키',
      '불독',
      '닥스훈트',
      '비글',
      '슈나우저',
      '스피츠',
      '믹스견',
      '기타',
    ];
  }

  // 건강 기록 타입 목록
  List<String> getHealthRecordTypes() {
    return [
      '예방접종',
      '건강검진',
      '질병치료',
      '수술',
      '응급처치',
      '정기검진',
      '약물투여',
      '체중측정',
      '기타',
    ];
  }
}
