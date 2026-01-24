import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ignore: must_be_immutable
class CricularDecoration extends StatelessWidget {
  Color? color;
  int width = 0;
  int heghit = 100;
  CricularDecoration(
      {super.key, required this.heghit, required this.width, this.color});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: MyClipper(width = width, heghit = heghit),
      child: Container(
        height: 180.h,
        width: double.infinity,
        color: color,
      ),
    );
  }
}

class MyClipper extends CustomClipper<Path> {
  MyClipper(this.heghit, this.width);

  int width;
  int heghit;
  @override
  Path getClip(Size size) {
    var path = Path();

    path.lineTo(0, size.height - 150);

    path.quadraticBezierTo(size.width / 2, size.height + heghit,
        size.width + width, size.height - 150);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
// size.width / 2, size.height + 100, size.width+150, size.height - 100);
