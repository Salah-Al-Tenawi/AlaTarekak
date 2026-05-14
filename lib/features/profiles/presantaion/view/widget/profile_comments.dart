import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:alatarekak/core/constant/imagesUrl.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/my_button.dart';
import 'package:alatarekak/features/profiles/domain/entity/comment_entity.dart';

class ProfileComments extends StatelessWidget {
  final List<CommentEntity>? feadBack;

  const ProfileComments({super.key, required this.feadBack});

  @override
  Widget build(BuildContext context) {
    final comments = feadBack ?? [];

    if (comments.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Center(
          child: Text(
            'لا توجد تعليقات بعد',
            style: AppTextStyles.bodySmall.copyWith(color: MyColors.textHint),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      separatorBuilder: (_, _) => const Divider(
        height: 0,
        thickness: 0.5,
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) => Comment(commentEntity: comments[index]),
    );
  }
}

class Comment extends StatelessWidget {
  final CommentEntity commentEntity;

  const Comment({super.key, required this.commentEntity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ━━ الصورة على اليمين (أول عنصر = يمين في RTL) ━━
          MyButton(
            onPressed: () {
              Get.toNamed(RouteName.profile,
                  arguments: commentEntity.iduser);
            },
            child: CircleAvatar(
              radius: 22.r,
              backgroundColor: MyColors.primary,
              backgroundImage: commentEntity.authorPhoto != null
                  ? NetworkImage(commentEntity.authorPhoto!) as ImageProvider
                  : const AssetImage(ImagesUrl.profileImage),
            ),
          ),

          SizedBox(width: 10.w),

          // ━━ النص (اسم + تعليق + تاريخ) ━━
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الاسم
                Text(
                  commentEntity.authorName,
                  style: AppTextStyles.labelLarge
                      .copyWith(color: MyColors.textPrimary),
                ),
                SizedBox(height: 4.h),
                // التعليق
                Text(
                  commentEntity.text,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: MyColors.textSecondary, height: 1.4),
                ),
                SizedBox(height: 6.h),
                // التاريخ
                Text(
                  commentEntity.createdAt,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: MyColors.textHint,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}