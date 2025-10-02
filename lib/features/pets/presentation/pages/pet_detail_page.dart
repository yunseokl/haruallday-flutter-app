import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../core/services/pet_service.dart';
import '../../../../core/injection/injection_container.dart';

class PetDetailPage extends StatefulWidget {
  final String petId;
  final Map<String, dynamic>? pet;

  const PetDetailPage({
    super.key,
    required this.petId,
    this.pet,
  });

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> with TickerProviderStateMixin {
  final PetService _petService = sl<PetService>();
  
  late TabController _tabController;
  List<Map<String, dynamic>> _healthRecords = [];
  bool _isLoadingRecords = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHealthRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthRecords() async {
    setState(() {
      _isLoadingRecords = true;
    });

    try {
      final records = await _petService.getPetHealthRecords(widget.pet['id']);
      setState(() {
        _healthRecords = records;
        _isLoadingRecords = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRecords = false;
      });
      print('Error loading health records: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.pet['name']?.toString() ?? '이름 없음';
    final breed = widget.pet['breed']?.toString() ?? '품종 미상';
    final gender = widget.pet['gender']?.toString() ?? '';
    final weight = widget.pet['weight'] as double? ?? 0.0;
    final description = widget.pet['description']?.toString() ?? '';
    final imageUrl = widget.pet['image_url']?.toString();
    
    // 생년월일로부터 나이 계산
    int age = 0;
    DateTime? birthDate;
    if (widget.pet['birth_date'] != null) {
      birthDate = DateTime.tryParse(widget.pet['birth_date']);
      if (birthDate != null) {
        age = _petService.calculateAge(birthDate);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(MdiIcons.pencil),
            onPressed: () {
              // TODO: 반려견 정보 수정 페이지로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('수정 기능은 준비 중입니다.')),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '기본 정보'),
            Tab(text: '건강 기록'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicInfoTab(name, breed, gender, weight, age, birthDate, description, imageUrl),
          _buildHealthRecordsTab(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab(
    String name,
    String breed,
    String gender,
    double weight,
    int age,
    DateTime? birthDate,
    String description,
    String? imageUrl,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 반려견 이미지
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(75),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(75),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: Icon(
                            MdiIcons.dog,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: Icon(
                            MdiIcons.dog,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    : Icon(
                        MdiIcons.dog,
                        size: 60,
                        color: Colors.grey[400],
                      ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 기본 정보 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '기본 정보',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow(MdiIcons.dog, '이름', name),
                  _buildInfoRow(MdiIcons.dna, '품종', breed),
                  if (gender.isNotEmpty)
                    _buildInfoRow(
                      gender == '수컷' ? MdiIcons.genderMale : MdiIcons.genderFemale,
                      '성별',
                      gender,
                    ),
                  if (age > 0)
                    _buildInfoRow(MdiIcons.cakeVariant, '나이', '${age}살'),
                  if (birthDate != null)
                    _buildInfoRow(
                      MdiIcons.calendar,
                      '생년월일',
                      '${birthDate.year}년 ${birthDate.month}월 ${birthDate.day}일',
                    ),
                  if (weight > 0)
                    _buildInfoRow(MdiIcons.weight, '체중', '${weight.toStringAsFixed(1)}kg'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 설명 카드
          if (description.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '설명',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRecordsTab() {
    return Column(
      children: [
        // 건강 기록 추가 버튼
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: 건강 기록 추가 페이지로 이동
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('건강 기록 추가 기능은 준비 중입니다.')),
                );
              },
              icon: Icon(MdiIcons.plus),
              label: const Text('건강 기록 추가'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        
        // 건강 기록 목록
        Expanded(
          child: _isLoadingRecords
              ? const Center(child: CircularProgressIndicator())
              : _healthRecords.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medical_services_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text('건강 기록이 없습니다.'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _healthRecords.length,
                      itemBuilder: (context, index) {
                        final record = _healthRecords[index];
                        return _buildHealthRecordCard(record);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildHealthRecordCard(Map<String, dynamic> record) {
    final recordType = record['record_type']?.toString() ?? '';
    final description = record['description']?.toString() ?? '';
    final recordDate = DateTime.tryParse(record['record_date'] ?? '');
    final veterinarian = record['veterinarian']?.toString();
    final medication = record['medication']?.toString();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    recordType,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (recordDate != null)
                  Text(
                    '${recordDate.year}.${recordDate.month.toString().padLeft(2, '0')}.${recordDate.day.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            
            if (veterinarian != null && veterinarian.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(MdiIcons.doctor, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '수의사: $veterinarian',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            
            if (medication != null && medication.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(MdiIcons.pill, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '처방약: $medication',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
