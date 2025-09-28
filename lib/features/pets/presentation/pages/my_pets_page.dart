import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../core/services/pet_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/injection/injection_container.dart';
import '../widgets/pet_card.dart';
import 'add_pet_page.dart';
import 'pet_detail_page.dart';

class MyPetsPage extends StatefulWidget {
  const MyPetsPage({super.key});

  @override
  State<MyPetsPage> createState() => _MyPetsPageState();
}

class _MyPetsPageState extends State<MyPetsPage> {
  final PetService _petService = sl<PetService>();
  final AuthService _authService = sl<AuthService>();
  
  List<Map<String, dynamic>> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final pets = await _petService.getUserPets(userId);
      setState(() {
        _pets = pets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('반려견 정보를 불러오는 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddPet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddPetPage(),
      ),
    );

    if (result == true) {
      _loadPets(); // 새 반려견이 추가되면 목록 새로고침
    }
  }

  Future<void> _navigateToPetDetail(Map<String, dynamic> pet) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailPage(pet: pet),
      ),
    );

    if (result == true) {
      _loadPets(); // 반려견 정보가 수정되면 목록 새로고침
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUserId;
    
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('내 반려견'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('로그인이 필요합니다.'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 반려견'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(MdiIcons.plus),
            onPressed: _navigateToAddPet,
            tooltip: '반려견 추가',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pets.isEmpty
              ? _buildEmptyState()
              : _buildPetsList(),
      floatingActionButton: _pets.isNotEmpty
          ? FloatingActionButton(
              onPressed: _navigateToAddPet,
              child: Icon(MdiIcons.plus),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            MdiIcons.dog,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            '등록된 반려견이 없습니다',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 반려견을 등록해보세요',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToAddPet,
            icon: Icon(MdiIcons.plus),
            label: const Text('반려견 등록하기'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetsList() {
    return RefreshIndicator(
      onRefresh: _loadPets,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pets.length,
        itemBuilder: (context, index) {
          final pet = _pets[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < _pets.length - 1 ? 16 : 0,
            ),
            child: PetCard(
              pet: pet,
              onTap: () => _navigateToPetDetail(pet),
            ),
          );
        },
      ),
    );
  }
}
