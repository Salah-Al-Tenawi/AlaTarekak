// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';


// ignore: must_be_immutable
class CustomBadge extends StatelessWidget {
  Widget ?icon;
  Color? badgeColor;
  Color? bordercolor;
  bool? border = true;
  Widget? child;
  dynamic Function()? onTap;
  CustomBadge(
      {super.key,
      this.child,
       this.icon,
      this.badgeColor,
      this.bordercolor,
      this.border,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return badges.Badge(
      
      position: badges.BadgePosition.topEnd(top: -10, end: -12),
      showBadge: true,
      ignorePointer: false,
      onTap: () {
        onTap==null? null :onTap!();
      },
      badgeContent: icon
      // Icon(Icons.cancel, color: Colors.red, size: 15),
      ,
      badgeAnimation: const badges.BadgeAnimation.rotation(
        animationDuration: Duration(seconds: 2),
        colorChangeAnimationDuration: Duration(seconds: 1),
        loopAnimation: false,
        curve: Curves.fastOutSlowIn,
        colorChangeAnimationCurve: Curves.easeInCubic,
      ),
      badgeStyle: badges.BadgeStyle(
        shape: badges.BadgeShape.square,
       
        badgeColor: badgeColor == null ? MyColors.greyTextColor : badgeColor!,
        padding: const EdgeInsets.all(5),
        borderRadius: BorderRadius.circular(4),
        borderSide: border == true
            ? BorderSide(
                color: bordercolor == null ? MyColors.blueColor : bordercolor!,
                width: 1)
            : const BorderSide(width: 0),
        elevation: 0,
      ),
      child: child,
    );
  }
}
