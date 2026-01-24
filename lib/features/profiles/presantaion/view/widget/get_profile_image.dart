import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alatarekak/core/constant/imagesUrl.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';

ImageProvider getProfileImage(BuildContext context ,String? imageurl ) {
  final cubit = context.read<ProfileCubit>();
  
  if (cubit.userPhoto != null) {
    return FileImage(File(cubit.userPhoto!.path)); 
  }
  else if (imageurl != null) {
    return NetworkImage(imageurl);
  }
  else {
    return const AssetImage(ImagesUrl.profileImage);
  }
}


ImageProvider getCarImage(BuildContext context ,String? imageurl ) {
  final cubit = context.read<ProfileCubit>();
  
  if (cubit.carPhoto != null) {
    return FileImage(File(cubit.userPhoto!.path)); 
  }
  else if (imageurl != null) {
    return NetworkImage(imageurl);
  }
  else {
    return const AssetImage(ImagesUrl.carImage);
  }
}