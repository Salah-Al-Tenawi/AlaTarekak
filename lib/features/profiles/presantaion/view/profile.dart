import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
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
  late Future<ProfileEntity> _loadProfileFuture;

  @override
  void initState() {
    super.initState();
    _profileCubit = context.read<ProfileCubit>();
    final args = Get.arguments;
    userId = (args is int) ? args : (myid() ?? 0);
    _loadProfileFuture = _fetchProfileData(userId);
  }

  Future<ProfileEntity> _fetchProfileData(int id) async {
    if (id == myid()) {
      return await _profileCubit.showMyProfile();
    } else {
      return await _profileCubit.showOtherProfile(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadProfileFuture = _fetchProfileData(userId);
          });
        },
        child: FutureBuilder<ProfileEntity>(
          future: _loadProfileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidgetSize150();
            }

            if (snapshot.hasError || snapshot.data == null) {
              return ProfileErrorWidget(
                onRetry: () {
                  setState(() {
                    _loadProfileFuture = _fetchProfileData(userId);
                  });
                },
              );
            }

            return const ProfileBody();
          },
        ),
      ),
    );
  }
}
