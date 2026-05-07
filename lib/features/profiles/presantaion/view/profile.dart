import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:alatarekak/core/utils/functions/get_userid.dart';
import 'package:alatarekak/core/utils/widgets/loading_widget_size_150.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_body.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_erorr.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late ProfileCubit _profileCubit;
  late int userId;

  @override
  void initState() {
    super.initState();
    _profileCubit = context.read<ProfileCubit>();
    // userId = Get.arguments as int; 
    userId = 1 ;

    // _loadProfileFuture = _fetchProfileData(userId);
  }

  Future<ProfileEntity> _fetchProfileData(int userId) async {
    final currentUserid = myid();
    if (userId == currentUserid) {
      print("me profile");
      return await _profileCubit.showMyProfile();
    } else {
      print("me profile");
      return await _profileCubit.showOtherProfile(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {},
        child: FutureBuilder<ProfileEntity>(
          future: _fetchProfileData(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidgetSize150();
            }

            if (snapshot.hasError || snapshot.data == null) {
              print(
                  "===========================================${snapshot.error}");
              return ProfileErrorWidget(
                onRetry: () {
                  setState(() {
                    _fetchProfileData(userId);
                  });
                },
              );
            }

            return ProfileBody();
          },
        ),
      ),
    );
  }
}
