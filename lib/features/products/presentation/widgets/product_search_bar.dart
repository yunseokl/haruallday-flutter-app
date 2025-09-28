import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ProductSearchBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final String hintText;
  final String? initialValue;

  const ProductSearchBar({
    super.key,
    required this.onSearchChanged,
    this.hintText = '상품을 검색하세요',
    this.initialValue,
  });

  @override
  State<ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends State<ProductSearchBar> {
  late TextEditingController _controller;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    
    // 검색어 변경 감지
    _controller.addListener(() {
      final query = _controller.text.trim();
      setState(() {
        _isSearching = query.isNotEmpty;
      });
      widget.onSearchChanged(query);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            MdiIcons.magnify,
            color: Colors.grey[600],
            size: 20,
          ),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: Icon(
                    MdiIcons.close,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(fontSize: 16),
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          // 검색 완료 시 키보드 숨기기
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }
}
