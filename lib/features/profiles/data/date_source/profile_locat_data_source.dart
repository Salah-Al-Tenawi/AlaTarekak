import 'dart:convert';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/profiles/data/model/profile_model.dart';

abstract class ProfileLocatDataSource {
  ProfileModel? getProfile(int id);
  Future<void> saveProfile(int id, ProfileModel profile);
  Future<void> clearProfile(int id);
}

class ProfileLocatDataSourceIm extends ProfileLocatDataSource {
  @override
  ProfileModel? getProfile(int id) {
    final raw = HiveBoxes.profileBox.get('$id');
    if (raw == null) return null;
    return ProfileModel.fromJson(jsonDecode(raw));
  }

  @override
  Future<void> saveProfile(int id, ProfileModel profile) async {
    await HiveBoxes.profileBox.put('$id', jsonEncode(profile.toJson()));
  }

  @override
  Future<void> clearProfile(int id) async {
    await HiveBoxes.profileBox.delete('$id');
  }
}
