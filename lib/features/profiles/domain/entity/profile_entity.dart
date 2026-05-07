import 'package:alatarekak/features/profiles/data/model/documents_model.dart';
import 'package:alatarekak/features/profiles/domain/entity/car_entity.dart';
import 'package:alatarekak/features/profiles/domain/entity/comment_entity.dart';

class ProfileEntity {
  final String fullname;
  final String? profilePhoto;
  final int numberOfides;
  final int totalRating;
  final double averageRating;
  final String verification;
  final String description;
  final String address;
  final String gender;
  final CarEntity? car;
  final List<CommentEntity>? comments;
  final DocumentsModel? documents;

  // ━━ إحصائيات الرحلات (كسائق) ━━
  final int totalTrips;
  final int successfulTrips;
  final int cancelledTrips;
  final int noShowTrips;

  // ━━ إحصائيات الحجوزات (كراكب) ━━
  final int totalBookings;
  final int successfulBookings;
  final int cancelledBookings;

  ProfileEntity({
    required this.fullname,
    required this.profilePhoto,
    required this.numberOfides,
    required this.totalRating,
    required this.averageRating,
    required this.verification,
    required this.description,
    required this.address,
    required this.gender,
    required this.car,
    required this.comments,
    required this.documents,
    // ✅ لها قيم افتراضية حتى لا تكسر الكود القديم
    this.totalTrips = 0,
    this.successfulTrips = 0,
    this.cancelledTrips = 0,
    this.noShowTrips = 0,
    this.totalBookings = 0,
    this.successfulBookings = 0,
    this.cancelledBookings = 0,
  });

  ProfileEntity copyWith({
    String? fullname,
    String? profilePhoto,
    int? numberOfides,
    int? totalRating,
    double? averageRating,
    String? verification,
    String? description,
    String? address,
    String? gender,
    CarEntity? car,
    List<CommentEntity>? comments,
    DocumentsModel? documents,
    int? totalTrips,
    int? successfulTrips,
    int? cancelledTrips,
    int? noShowTrips,
    int? totalBookings,
    int? successfulBookings,
    int? cancelledBookings,
  }) {
    return ProfileEntity(
      fullname: fullname ?? this.fullname,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      numberOfides: numberOfides ?? this.numberOfides,
      totalRating: totalRating ?? this.totalRating,
      averageRating: averageRating ?? this.averageRating,
      verification: verification ?? this.verification,
      description: description ?? this.description,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      car: car ?? this.car,
      comments: comments ?? this.comments,
      documents: documents ?? this.documents,
      totalTrips: totalTrips ?? this.totalTrips,
      successfulTrips: successfulTrips ?? this.successfulTrips,
      cancelledTrips: cancelledTrips ?? this.cancelledTrips,
      noShowTrips: noShowTrips ?? this.noShowTrips,
      totalBookings: totalBookings ?? this.totalBookings,
      successfulBookings: successfulBookings ?? this.successfulBookings,
      cancelledBookings: cancelledBookings ?? this.cancelledBookings,
    );
  }
}