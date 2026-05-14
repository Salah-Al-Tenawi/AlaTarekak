import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/utils/functions/get_userid.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_body.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late final int _userId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _userId = (args is int) ? args : (myid() ?? 0);
    _load();
  }

  void _load() {
    final cubit = context.read<ProfileCubit>();
    if (_userId == myid()) {
      cubit.showMyProfile();
    } else {
      cubit.showOtherProfile(_userId);
    }
  }

  @override
  Widget build(BuildContext context) => ProfileBody(onRefresh: _load);
}
