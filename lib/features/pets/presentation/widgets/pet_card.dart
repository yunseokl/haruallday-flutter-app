import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../core/services/pet_service.dart';
import '../../../../core/injection/injection_container.dart';

class PetCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final VoidCallback? onTap;

  const PetCard({
    super.key,
    required this.pet,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final petService = sl<PetService>();
    
    final name = pet['name']?.toString() ?? '이름 없음';
    final breed = pet['breed']?.toString() ?? '품종 미상';
    final gender = pet['gender']?.toString() ?? '';
    final weight = pet['weight'] as double? ?? 0.0;
    final imageUrl = pet['image_url']?.toString();
    
    // 생년월일로부터 나이 계산
    int age = 0;
    if (pet['birth_date'] != null) {
      final birthDate = DateTime.tryParse(pet['birth_date']);
      if (birthDate != null) {
        age = petService.calculateAge(birthDate);
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 반려견 이미지
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              MdiIcons.dog,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              MdiIcons.dog,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          ),
                        )
                      : Icon(
                          MdiIcons.dog,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // 반려견 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이름
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 품종
                    Text(
                      breed,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 나이, 성별, 체중
                    Row(
                      children: [
                        if (age > 0) ...[
                          Icon(
                            MdiIcons.cakeVariant,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${age}살',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        
                        if (gender.isNotEmpty) ...[
                          Icon(
                            gender == '수컷' ? MdiIcons.genderMale : MdiIcons.genderFemale,
                            size: 16,
                            color: gender == '수컷' ? Colors.blue : Colors.pink,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            gender,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        
                        if (weight > 0) ...[
                          Icon(
                            MdiIcons.weight,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${weight.toStringAsFixed(1)}kg',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // 화살표 아이콘
              Icon(
                MdiIcons.chevronRight,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
