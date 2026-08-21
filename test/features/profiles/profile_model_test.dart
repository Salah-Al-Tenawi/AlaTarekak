import 'package:alatarekak/features/profiles/data/model/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// قراءة ردّ `GET /profile/{id}` — بالردّ الحقيقي كما يرسله الخادم.
///
/// **المتوسط يصل باسم `average`**، وكان يُقرأ `average_rating` وحده
/// فيعود صفراً دائماً: يرى المستخدم «بناءً على 12 تقييماً» ومعها متوسطٌ
/// صفريّ — والرقمان من الكتلة نفسها، أحدهما مفتاحه مطابق والآخر لا.
Map<String, dynamic> _response() => {
      'user_id': 12,
      'full_name': 'أحمد خالد',
      'verification_status': 'approved',
      'address': 'دمشق',
      'gender': 'M',
      'profile_photo': 'https://x/storage/profiles/abc.jpg',
      'description': 'نص التعريف',
      'type_of_car': 'Kia Rio',
      'color_of_car': 'أبيض',
      'number_of_seats': 4,
      'car_pic': 'https://x/storage/cars/xyz.jpg',
      'radio': true,
      'smoking': false,
      'number_of_rides': 37,
      'documents': {
        'face_id_pic': 'https://x/storage/docs/1.jpg',
        'back_id_pic': 'https://x/storage/docs/2.jpg',
        'license_pic': 'https://x/storage/docs/3.jpg',
        'mechanic_card_pic': 'https://x/storage/docs/4.jpg',
      },
      'score': {
        'score': 78,
        'tier': 'gold',
        'cancel_rate': 4.35,
        'total_rides': 46,
        'total_cancellations': 2,
        'can_create_rides': true,
        'can_book_rides': true,
      },
      'ride_history': {
        'as_driver': {
          'total_created': 20,
          'completed': 18,
          'cancelled': 1,
          'no_show': 1,
        },
        'as_passenger': {
          'total_booked': 26,
          'completed': 24,
          'cancelled': 1,
          'no_show': 1,
        },
      },
      'comments': [
        {
          'id': 5,
          'comment': 'سائق ممتاز',
          'ride_id': 88,
          'commenter': {'id': 7, 'name': 'سارة علي'},
          'created_at': '2026-08-19T14:03:11+00:00',
        },
      ],
      'rating': {'average': 4.75, 'total_ratings': 12},
    };

void main() {
  group('التقييم — العطب المُصلَح', () {
    test('المتوسط يُقرأ من `average` لا من `average_rating`', () {
      final data = ProfileData.fromJson(_response());

      expect(data.averageRating, 4.75,
          reason: 'كان يعود صفراً بينما العدد يظهر صحيحاً');
      expect(data.totalRating, 12);
    });

    test('والاسم القديم يبقى مقروءاً — الكاش على الأجهزة كُتب به', () {
      final old = _response();
      old['rating'] = {'average_rating': 3.5, 'total_ratings': 4};

      expect(ProfileData.fromJson(old).averageRating, 3.5);
    });

    test('ومتوسطٌ يصل نصّاً يُقرأ كذلك', () {
      final asText = _response();
      asText['rating'] = {'average': '4.25', 'total_ratings': 8};

      expect(ProfileData.fromJson(asText).averageRating, 4.25);
    });

    test('بلا كتلة تقييم: صفر بلا انهيار', () {
      final none = _response()..remove('rating');

      expect(ProfileData.fromJson(none).averageRating, 0.0);
      expect(ProfileData.fromJson(none).totalRating, 0);
    });

    test('ما يُكتب في الكاش يُقرأ منه بالقيمة نفسها', () {
      final once = ProfileData.fromJson(_response());
      final twice = ProfileData.fromJson(once.toJson());

      expect(twice.averageRating, 4.75,
          reason: 'الكاش يُكتب بـtoJson ويُقرأ بـfromJson — فلا يصحّ '
              'أن يختلف مفتاحاهما');
      expect(twice.totalRating, 12);
    });
  });

  group('بقية الكتل تُقرأ كما وصلت', () {
    test('درجة النشاط', () {
      final data = ProfileData.fromJson(_response());

      expect(data.scoreValue, 78);
      expect(data.tier, 'gold');
      expect(data.canCreateRides, isTrue);
      expect(data.canBookRides, isTrue);
    });

    test('سجلّ الرحلات كسائق', () {
      final data = ProfileData.fromJson(_response());

      expect(data.totalTrips, 20);
      expect(data.successfulTrips, 18);
      expect(data.cancelledTrips, 1);
      expect(data.noShowTrips, 1);
    });

    test('وكراكب', () {
      final data = ProfileData.fromJson(_response());

      expect(data.totalBookings, 26);
      expect(data.successfulBookings, 24);
      expect(data.cancelledBookings, 1);
      expect(data.noShowBookings, 1);
    });

    test('المركبة والمستندات والتعليقات', () {
      final data = ProfileData.fromJson(_response());

      expect(data.car?.type, 'Kia Rio');
      expect(data.car?.seats, 4);
      expect(data.documents?.faceIdPic, contains('1.jpg'));
      expect(data.comments, hasLength(1));
      expect(data.comments!.first.text, 'سائق ممتاز');
    });
  });
}
