import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../core/router/app_router.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      CategoryItem(
        name: '관절 건강',
        icon: MdiIcons.bone,
        color: const Color(0xFF4CAF50),
        description: '슬개골, 관절염 예방',
      ),
      CategoryItem(
        name: '피부 건강',
        icon: MdiIcons.heart,
        color: const Color(0xFFE91E63),
        description: '습진, 모질 개선',
      ),
      CategoryItem(
        name: '장 건강',
        icon: MdiIcons.stomach,
        color: const Color(0xFF9C27B0),
        description: '소화, 유산균',
      ),
      CategoryItem(
        name: '눈 건강',
        icon: MdiIcons.eye,
        color: const Color(0xFF2196F3),
        description: '눈물, 시력 관리',
      ),
      CategoryItem(
        name: '기관지',
        icon: MdiIcons.lungs,
        color: const Color(0xFF00BCD4),
        description: '감기, 협착증',
      ),
      CategoryItem(
        name: '전체보기',
        icon: MdiIcons.viewGrid,
        color: const Color(0xFF607D8B),
        description: '모든 제품',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () {
            // 카테고리 페이지로 이동
            context.push('${AppRouter.products}?category=${category}');
          },
          child: Container(
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  category.description,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CategoryItem {
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  CategoryItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class CategoryProductsPage extends StatelessWidget {
  final CategoryItem category;

  const CategoryProductsPage({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        backgroundColor: category.color,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: 64,
              color: category.color,
            ),
            const SizedBox(height: 16),
            Text(
              '${category.name} 제품',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              category.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            const Text('제품 목록이 여기에 표시됩니다.'),
          ],
        ),
      ),
    );
  }
}
