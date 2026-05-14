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
          numberOfides: data.numberOfRides,
          totalTrips: data.totalTrips,
          successfulTrips: data.successfulTrips,
          cancelledTrips: data.cancelledTrips,
          noShowTrips: data.noShowTrips,
          totalBookings: data.totalBookings,
          successfulBookings: data.successfulBookings,
          cancelledBookings: data.cancelledBookings,
          noShowBookings: data.noShowBookings,
          scoreValue: data.scoreValue,
          tier: data.tier,
          canCreateRides: data.canCreateRides,
          canBookRides: data.canBookRides,
        );

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

  // ━━ إحصائيات الرحلات (كسائق) ━━
  final int totalTrips;
  final int successfulTrips;
  final int cancelledTrips;
  final int noShowTrips;

  // ━━ إحصائيات الحجوزات (كراكب) ━━
  final int totalBookings;
  final int successfulBookings;
  final int cancelledBookings;
  final int noShowBookings;

  // ━━ درجة النشاط ━━
  final int scoreValue;
  final String tier;
  final bool canCreateRides;
  final bool canBookRides;

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
    this.totalTrips = 0,
    this.successfulTrips = 0,
    this.cancelledTrips = 0,
    this.noShowTrips = 0,
    this.totalBookings = 0,
    this.successfulBookings = 0,
    this.cancelledBookings = 0,
    this.noShowBookings = 0,
    this.scoreValue = 0,
    this.tier = 'Restricted',
    this.canCreateRides = false,
    this.canBookRides = false,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final rating = json[ApiKey.rating] ?? {};

    // ride_history → as_driver (كسائق) + as_passenger (كراكب)
    final rideHistory = json['ride_history'] ?? {};
    final asDriver = rideHistory['as_driver'] ?? {};
    final asPassenger = rideHistory['as_passenger'] ?? {};

    // score object
    final scoreData = json['score'] ?? {};

    return ProfileData(
      userId: json[ApiKey.userId] ?? 0,
      fullName: json[ApiKey.fullName] ?? '',
      totalRating: rating[ApiKey.totalRatings] ?? 0,
      averageRating: (rating[ApiKey.averageRating] is num)
          ? (rating[ApiKey.averageRating] as num).toDouble()
          : 0.0,
      verificationStatus: json[ApiKey.verificationStatus] ?? 'none',
      address: json[ApiKey.address] ?? '',
      gender: json[ApiKey.gender] ?? 'M',
      profilePhoto: json[ApiKey.profilePhoto],
      description: json[ApiKey.description] ?? '',
      car: json[ApiKey.typeOfCar] != null ? CarModel.fromJson(json) : null,
      numberOfRides: json[ApiKey.numberOfRides] ?? 0,
      documents: (json[ApiKey.documents] != null &&
              json[ApiKey.documents] is Map<String, dynamic>)
          ? DocumentsModel.fromJson(json[ApiKey.documents])
          : null,
      comments: (json[ApiKey.comments] as List<dynamic>?)
              ?.map((c) => CommentModel.fromJson(c))
              .toList() ??
          [],

      // ━━ الرحلات (كسائق) ━━
      totalTrips: asDriver['total_created'] ?? 0,
      successfulTrips: asDriver['completed'] ?? 0,
      cancelledTrips: asDriver['cancelled'] ?? 0,
      noShowTrips: asDriver['no_show'] ?? 0,

      // ━━ الحجوزات (كراكب) ━━
      totalBookings: asPassenger['total_booked'] ?? 0,
      successfulBookings: asPassenger['completed'] ?? 0,
      cancelledBookings: asPassenger['cancelled'] ?? 0,
      noShowBookings: asPassenger['no_show'] ?? 0,

      // ━━ درجة النشاط ━━
      scoreValue: (scoreData['score'] is num)
          ? (scoreData['score'] as num).toInt()
          : 0,
      tier: scoreData['tier'] ?? 'Restricted',
      canCreateRides: scoreData['can_create_rides'] ?? false,
      canBookRides: scoreData['can_book_rides'] ?? false,
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
      ApiKey.rating: {
        ApiKey.totalRatings: totalRating,
        ApiKey.averageRating: averageRating,
      },
      ApiKey.documents: documents?.toJson(),
      ApiKey.comments: comments?.map((c) => c.toJson()).toList(),
      'ride_history': {
        'as_driver': {
          'total_created': totalTrips,
          'completed': successfulTrips,
          'cancelled': cancelledTrips,
          'no_show': noShowTrips,
        },
        'as_passenger': {
          'total_booked': totalBookings,
          'completed': successfulBookings,
          'cancelled': cancelledBookings,
          'no_show': noShowBookings,
        },
      },
      'score': {
        'score': scoreValue,
        'tier': tier,
        'can_create_rides': canCreateRides,
        'can_book_rides': canBookRides,
      },
    };
  }
}