import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/profiles/data/model/enum/profile_mode.dart';

class ProfileRating extends StatelessWidget {
  final int totalRating;
  final double averageRating;
  final int tripsCount;
  final ProfileMode? mode;

  const ProfileRating({
    super.key,
    required this.averageRating,
    required this.totalRating,
    required this.tripsCount,
    this.mode,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == ProfileMode.myEdit) {
      return const SizedBox(); 
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RatingBarIndicator(
          rating: averageRating,
          itemBuilder: (context, index) => const Icon(
            Icons.star,
            color: Colors.amber,
          ),
          itemCount: 5,
          itemSize: 20.0,
          direction: Axis.horizontal,
        ),
        const SizedBox(height: 2),
        Text(
          "($totalRating) التقييمات",
          style: AppTextStyles.bodySmall,
        ),
        Text(
          "($tripsCount) الرحلات",
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}
