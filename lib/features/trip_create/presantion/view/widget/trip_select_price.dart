// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';

class TripSelectPrice extends StatefulWidget {
  TripFrom tripFrom;
  TripSelectPrice({
    super.key,
    required this.tripFrom,
  });

  @override
  State<TripSelectPrice> createState() => _TripSelectPriceState();
}

class _TripSelectPriceState extends State<TripSelectPrice> {
  void incremant(int priceRecomanded) {
    if (priceRecomanded > 40000) {
      if (priceRecomanded < 60000) {
        priceRecomanded += 5000;
      }
    } else if (priceRecomanded < 40000 && priceRecomanded > 20000) {
      priceRecomanded += 5000;
    } else if (priceRecomanded < 20000) {
      priceRecomanded += 2000;
    }
    widget.tripFrom.price = priceRecomanded;

    setState(() {
      widget.tripFrom.price;
    });
  }

  void decremant(int priceRecomanded) {
    int counter = 0;
    if (priceRecomanded > 40000 && counter < 3) {
      priceRecomanded -= 10000;
      counter++;
    } else if (priceRecomanded < 40000 &&
        priceRecomanded > 20000 &&
        counter < 3) {
      priceRecomanded -= 5000;
    } else if (priceRecomanded < 20000 && counter < 3) {
      priceRecomanded -= 2000;
    }
    widget.tripFrom.price = priceRecomanded;

    setState(() {
      widget.tripFrom.price;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(top: 10.h, bottom: 50.h, right: 20.w, left: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () {
              incremant(widget.tripFrom.price);
            },
            icon: const FaIcon(
              FontAwesomeIcons.plus,
              size: 40,
              color: MyColors.textPrimary,
            ),
          ),
          Text(
            "${widget.tripFrom.price}",
            style: AppTextStyles.displayMedium,
          ),
          IconButton(
            onPressed: () {
              decremant(widget.tripFrom.price);
            },
            icon: const FaIcon(FontAwesomeIcons.minus,
                size: 40, color: MyColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
