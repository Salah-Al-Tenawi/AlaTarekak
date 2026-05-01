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
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("لا توجد تعليقات بعد", textAlign: TextAlign.center),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        border: Border.all(width: 0.3, color: MyColors.background),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: comments.length,
        itemBuilder: (context, index) {
          return Comment(commentEntity: comments[index]);
        },
      ),
    );
  }
}
class Comment extends StatelessWidget {
  final CommentEntity commentEntity;

  const Comment({super.key, required this.commentEntity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.h, horizontal: 10.w),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        border: Border.all(width: 0.3, color: MyColors.background),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  commentEntity.authorName,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 5),
                Text(
                  commentEntity.text,
                  style: AppTextStyles.bodySmall,
                  textDirection: TextDirection.rtl,
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    commentEntity.createdAt,
                    style: const TextStyle(
                      fontSize: 6.2,
                      fontWeight: FontWeight.bold,
                      color: MyColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          MyButton(
            onPressed: () {
              Get.toNamed(RouteName.profile, arguments: commentEntity.iduser);
            },
            child: CircleAvatar(
              maxRadius: 25,
              backgroundColor: MyColors.primary,
              backgroundImage: commentEntity.authorPhoto != null
                  ? NetworkImage(commentEntity.authorPhoto!)
                  : const AssetImage(ImagesUrl.profileImage) as ImageProvider,
            ),
          ),
        ],
      ),
    );
  }
}
