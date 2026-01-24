import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/features/profiles/data/model/car_model.dart';
import 'package:alatarekak/features/profiles/data/model/comment_model.dart';
import 'package:alatarekak/features/profiles/data/model/documents_model.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  final bool success;
  final ProfileData data;

  ProfileModel({
    required this.success,
    required this.data,
  }) : super(
            fullname: data.fullName,
            profilePhoto: data.profilePhoto,
            totalRating: data.totalRating,
            verification: data.verificationStatus,
            address: data.address,
            gender: data.gender,
            description: data.description,
            car: data.car,
            comments: data.comments,
            documents: data.documents,
            averageRating: data.averageRating,
            numberOfides: data.numberOfRides);

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      success: json[ApiKey.success] ?? false,
      data: ProfileData.fromJson(json[ApiKey.data] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.success: success,
      ApiKey.data: data.toJson(),
    };
  }
}

class ProfileData {
  final int userId;
  final String fullName;
  final String verificationStatus;
  final String address;
  final String gender;
  final String? profilePhoto;
  final String description;
  final double averageRating;
  final int totalRating;
  final CarModel? car;
  final int numberOfRides;
  final DocumentsModel? documents;
  final List<CommentModel>? comments;

  ProfileData({
    required this.averageRating,
    required this.totalRating,
    required this.userId,
    required this.fullName,
    required this.verificationStatus,
    required this.address,
    required this.gender,
    this.profilePhoto,
    required this.description,
    this.car,
    required this.numberOfRides,
    required this.documents,
    required this.comments,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final rating = json[ApiKey.rating] ?? {};
    return ProfileData(
      userId: json[ApiKey.userId],
      fullName: json[ApiKey.fullName] ?? '',
      totalRating: rating[ApiKey.totalRatings] ?? 0,
      averageRating: (rating[ApiKey.averageRating] is num)
          ? (rating[ApiKey.averageRating] as num).toDouble()
          : 0.0,
      verificationStatus: json[ApiKey.verificationStatus] ?? 'none',
      address: json[ApiKey.address] ?? '',
      gender: json[ApiKey.gender] ?? 'Male',
      profilePhoto: json[ApiKey.profilePhoto],
      description: json[ApiKey.description] ?? '',
      car: json[ApiKey.typeOfCar] != null ? CarModel.fromJson(json) : null,
      numberOfRides: json[ApiKey.numberOfRides] ?? 0,
      documents: (json[ApiKey.documents] != null &&
              json[ApiKey.documents] is Map<String, dynamic>)
          ? DocumentsModel.fromJson(json[ApiKey.documents])
          : null,
      comments: (json[ApiKey.comments] as List<dynamic>?)
              ?.map((comment) => CommentModel.fromJson(comment))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.userId: userId,
      ApiKey.fullName: fullName,
      ApiKey.verificationStatus: verificationStatus,
      ApiKey.address: address,
      ApiKey.gender: gender,
      ApiKey.profilePhoto: profilePhoto,
      ApiKey.description: description,
      if (car != null) ...car!.toJson(),
      ApiKey.numberOfRides: numberOfRides,
      ApiKey.documents: documents?.toJson(),
      ApiKey.comments: comments?.map((comment) => comment.toJson()).toList(),
    };
  }
}
