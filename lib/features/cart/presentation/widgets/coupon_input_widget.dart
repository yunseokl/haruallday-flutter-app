import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class CouponInputWidget extends StatefulWidget {
  final String? appliedCouponCode;
  final Function(String) onApplyCoupon;
  final VoidCallback onRemoveCoupon;

  const CouponInputWidget({
    super.key,
    this.appliedCouponCode,
    required this.onApplyCoupon,
    required this.onRemoveCoupon,
  });

  @override
  State<CouponInputWidget> createState() => _CouponInputWidgetState();
}

class _CouponInputWidgetState extends State<CouponInputWidget> {
  final TextEditingController _couponController = TextEditingController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.appliedCouponCode != null) {
      _couponController.text = widget.appliedCouponCode!;
      _isExpanded = true;
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final couponCode = _couponController.text.trim();
    if (couponCode.isNotEmpty) {
      widget.onApplyCoupon(couponCode);
    }
  }

  void _removeCoupon() {
    _couponController.clear();
    widget.onRemoveCoupon();
    setState(() {
      _isExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 쿠폰 헤더
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    MdiIcons.ticketPercent,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.appliedCouponCode != null
                          ? '쿠폰 적용됨: ${widget.appliedCouponCode}'
                          : '쿠폰 코드 입력',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.appliedCouponCode != null
                            ? Colors.green[700]
                            : Colors.black,
                      ),
                    ),
                  ),
                  if (widget.appliedCouponCode != null)
                    IconButton(
                      onPressed: _removeCoupon,
                      icon: Icon(
                        MdiIcons.close,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    )
                  else
                    Icon(
                      _isExpanded ? MdiIcons.chevronUp : MdiIcons.chevronDown,
                      color: Colors.grey[600],
                    ),
                ],
              ),
            ),
          ),
          
          // 쿠폰 입력 영역
          if (_isExpanded && widget.appliedCouponCode == null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Divider(
                    color: Colors.grey[300],
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          decoration: InputDecoration(
                            hintText: '쿠폰 코드를 입력하세요',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _applyCoupon(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _applyCoupon,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('적용'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // 사용 가능한 쿠폰 목록
                  _buildAvailableCoupons(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailableCoupons() {
    // 예시 쿠폰 목록 (실제로는 서버에서 가져와야 함)
    final availableCoupons = [
      {
        'code': 'WELCOME10',
        'name': '신규 회원 10% 할인',
        'description': '첫 구매 시 10% 할인 (최대 5,000원)',
        'minAmount': 30000,
      },
      {
        'code': 'HEALTH20',
        'name': '건강 제품 20% 할인',
        'description': '건강 관련 제품 20% 할인 (최대 10,000원)',
        'minAmount': 50000,
      },
      {
        'code': 'FREE3000',
        'name': '3,000원 즉시 할인',
        'description': '3,000원 즉시 할인',
        'minAmount': 20000,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '사용 가능한 쿠폰',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ...availableCoupons.map((coupon) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Icon(
              MdiIcons.ticket,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            title: Text(
              coupon['name'] as String,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon['description'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '최소 주문 금액: ${(coupon['minAmount'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            trailing: TextButton(
              onPressed: () {
                _couponController.text = coupon['code'] as String;
                _applyCoupon();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 0),
              ),
              child: const Text(
                '적용',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        )).toList(),
      ],
    );
  }
}
