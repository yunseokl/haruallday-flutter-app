import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/injection/injection_container.dart';
import '../../../auth/presentation/pages/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = sl<AuthService>();
  final PaymentService _paymentService = sl<PaymentService>();
  
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _recentOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 사용자 프로필 정보 로드
      final profile = await _authService.getUserProfile();
      
      // 최근 주문 내역 로드
      List<Map<String, dynamic>> orders = [];
      final userId = _authService.currentUserId;
      if (userId != null) {
        orders = await _paymentService.getUserOrders(userId: userId);
      }
      
      setState(() {
        _userProfile = profile;
        _recentOrders = orders.take(5).toList(); // 최근 5개만
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading user data: $e');
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _authService.signOut();
      
      if (mounted) {
        if (result['success'] == true) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? '로그아웃에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _authService.isLoggedIn;
    
    if (!isLoggedIn) {
      return _buildGuestView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(MdiIcons.logout),
            onPressed: _logout,
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 16),
                    _buildMenuSection(),
                    const SizedBox(height: 16),
                    _buildRecentOrdersSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGuestView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MdiIcons.accountCircle,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              '로그인이 필요합니다',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '하루올데이의 다양한 서비스를 이용해보세요',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              icon: Icon(MdiIcons.login),
              label: const Text('로그인하기'),
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
      ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _userProfile?['name']?.toString() ?? '사용자';
    final email = _userProfile?['email']?.toString() ?? '';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '메뉴',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _buildMenuItem(
                  icon: MdiIcons.accountEdit,
                  title: '프로필 수정',
                  onTap: () {
                    // TODO: 프로필 수정 페이지로 이동
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('프로필 수정 기능은 준비 중입니다.')),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: MdiIcons.shoppingOutline,
                  title: '주문 내역',
                  onTap: () {
                    // TODO: 주문 내역 페이지로 이동
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('주문 내역 페이지는 준비 중입니다.')),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: MdiIcons.heart,
                  title: '찜한 상품',
                  onTap: () {
                    // TODO: 찜한 상품 페이지로 이동
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('찜한 상품 기능은 준비 중입니다.')),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: MdiIcons.giftOutline,
                  title: '쿠폰함',
                  onTap: () {
                    // TODO: 쿠폰함 페이지로 이동
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('쿠폰함 기능은 준비 중입니다.')),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: MdiIcons.cog,
                  title: '설정',
                  onTap: () {
                    // TODO: 설정 페이지로 이동
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('설정 페이지는 준비 중입니다.')),
                    );
                  },
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.grey[600]),
          title: Text(title),
          trailing: Icon(MdiIcons.chevronRight, color: Colors.grey[400]),
          onTap: onTap,
        ),
        if (showDivider) Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }

  Widget _buildRecentOrdersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '최근 주문',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_recentOrders.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // TODO: 전체 주문 내역 페이지로 이동
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('주문 내역 페이지는 준비 중입니다.')),
                    );
                  },
                  child: const Text('전체보기'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentOrders.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        MdiIcons.shoppingOutline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '주문 내역이 없습니다',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: _recentOrders.asMap().entries.map((entry) {
                  final index = entry.key;
                  final order = entry.value;
                  return _buildOrderItem(
                    order,
                    showDivider: index < _recentOrders.length - 1,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order, {bool showDivider = true}) {
    final orderId = order['id']?.toString() ?? '';
    final totalAmount = order['total_amount'] as num? ?? 0;
    final status = order['status']?.toString() ?? '';
    final createdAt = DateTime.tryParse(order['created_at'] ?? '');
    
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              MdiIcons.packageVariant,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text('주문번호: ${orderId.substring(0, 8)}...'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_formatPrice(totalAmount)}원'),
              if (createdAt != null)
                Text(
                  '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getStatusText(status),
              style: TextStyle(
                color: _getStatusColor(status),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          onTap: () {
            // TODO: 주문 상세 페이지로 이동
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('주문 상세 페이지는 준비 중입니다.')),
            );
          },
        ),
        if (showDivider) Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }

  String _formatPrice(num price) {
    return price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return '완료';
      case 'processing':
        return '처리중';
      case 'cancelled':
        return '취소';
      default:
        return '알 수 없음';
    }
  }
}
