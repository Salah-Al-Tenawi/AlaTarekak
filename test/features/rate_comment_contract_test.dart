import 'dart:io';

import 'package:alatarekak/core/api/api_consumer.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/booking_user_in_trip/data/data_source/booking_user_trip_remote_data.dart';
import 'package:alatarekak/features/profiles/data/model/comment_model.dart';
import 'package:alatarekak/features/profiles/data/model/rating_modle.dart';
import 'package:alatarekak/features/trip_booking/data/data%20source/booking_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockApi extends Mock implements ApiConSumer {}

/// عقد التقييم والتعليق — `POST /profile/{id}/rate` و`/comments`.
///
/// **`ride_id` شرطٌ في الجسم**، وكان غائباً عن المسارين في الجانبين معاً.
/// فالتقييم يُرسَل عارياً من رحلته: الخادم لا يعرف أيّها يقيّم المستخدم،
/// ولا يستطيع منع تقييمين على الرحلة الواحدة. ولم يكن اختبارٌ واحد يفحص
/// **ما يُرسَل**، فمرّ العيب صامتاً — الطلب يُبنى ويُرسل ولا ينهار شيء.
void main() {
  late MockApi api;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('rate_contract');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    final box = await Hive.openBox<UserModel>(HiveBoxes.authBoxName);
    await box.put(
      HiveKeys.user,
      const UserModel(
        id: 7,
        firstName: 'يزن',
        lastName: 'صلاح',
        email: 'me@example.com',
        accessToken: 'token',
        refreshToken: 'refresh',
      ),
    );
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } on FileSystemException {
      // قفل ملفات مؤقت على ويندوز — غير مؤثر
    }
  });

  Map<String, dynamic> capturedBody() =>
      verify(() => api.post(any(),
              data: captureAny(named: 'data'), header: any(named: 'header')))
          .captured
          .single as Map<String, dynamic>;

  setUp(() {
    api = MockApi();
    when(() => api.post(any(),
            data: any(named: 'data'), header: any(named: 'header')))
        .thenAnswer((_) async => {
              'success': true,
              'message': 'Rating submitted successfully',
              'data': {'average': 4.5, 'total_ratings': 1},
            });
  });

  group('التقييم يحمل رحلته', () {
    test('جانب السائق: rating و ride_id معاً', () async {
      await BookingUserTripRemoteData(api: api).rateUser(4.5, 12, 1);

      final body = capturedBody();
      expect(body[ApiKey.rating], 4.5);
      expect(body[ApiKey.rideId], 1,
          reason: 'كان يُرسَل التقييم بلا رحلة، فلا يعرف الخادم أيّها يقيّم');
    });

    test('وجانب الراكب كذلك', () async {
      await BookingRemoteDataSource(api: api).rateUser(4.5, 12, 1);

      final body = capturedBody();
      expect(body[ApiKey.rating], 4.5);
      expect(body[ApiKey.rideId], 1);
    });

    test('والمسار إلى المستخدم المُقيَّم لا إلى المُقيِّم', () async {
      await BookingUserTripRemoteData(api: api).rateUser(4.5, 12, 1);

      verify(() => api.post('${ApiEndPoint.profile}/12/rate',
          data: any(named: 'data'), header: any(named: 'header'))).called(1);
    });
  });

  group('التعليق يحمل رحلته', () {
    test('جانب السائق', () async {
      await BookingUserTripRemoteData(api: api).addcommit('راكب مهذّب', 12, 1);

      final body = capturedBody();
      expect(body[ApiKey.comment], 'راكب مهذّب');
      expect(body[ApiKey.rideId], 1);
    });

    test('وجانب الراكب', () async {
      await BookingRemoteDataSource(api: api)
          .addcommit('سائق ممتاز', 12, 1);

      final body = capturedBody();
      expect(body[ApiKey.comment], 'سائق ممتاز');
      expect(body[ApiKey.rideId], 1);
    });
  });

  group('قراءة الردّ', () {
    test('المتوسط يصل باسم average لا average_rating', () {
      final model = RatingModle.fromJson(const {
        'success': true,
        'message': 'Rating submitted successfully',
        'data': {'average': 4.5, 'total_ratings': 1},
      });

      expect(model.averageRating, 4.5,
          reason: 'كان يُقرأ بالاسم الآخر وحده فيعود صفراً دائماً');
      expect(model.totalRating, 1);
    });

    test('والاسم القديم يبقى مقروءاً — ردّ الملف الشخصي يستعمله', () {
      final model = RatingModle.fromJson(const {
        'data': {'average_rating': 3.75, 'total_ratings': 8},
      });

      expect(model.averageRating, 3.75);
    });

    test('التعليق يُقرأ من data لا من غلافه', () {
      final model = CommentModel.fromJson(const {
        'success': true,
        'message': 'Comment added',
        'data': {
          'id': 1,
          'comment': 'Great driver, very punctual!',
          'ride_id': 1,
          'commenter': {'id': 12, 'name': 'Passenger1 Test'},
          'created_at': '2026-08-21T10:54:15+03:00',
        },
      });

      expect(model.id, 1);
      expect(model.text, 'Great driver, very punctual!');
      expect(model.authorName, 'Passenger1 Test');
      expect(model.iduser, 12);
    });

    test('وعنصر القائمة المسطّح يبقى مقروءاً كما كان', () {
      final model = CommentModel.fromJson(const {
        'id': 9,
        'comment': 'رحلة مريحة',
        'commenter': {'id': 4, 'name': 'صلاح'},
        'created_at': '2026-08-20T10:00:00+03:00',
      });

      expect(model.id, 9);
      expect(model.text, 'رحلة مريحة');
    });
  });

  group('أخطاء المسارين معرّبة', () {
    test('403 — لم تكتمل رحلة بينكما', () {
      expect(
        HandelErorrMessage.rateUser(
            'You can only rate a driver after completing a ride with them.'),
        'لا يمكن التقييم إلا بعد إتمام رحلة معاً',
      );
      expect(
        HandelErorrMessage.commet(
            'You can only comment on a driver after completing a ride '
            'with them.'),
        'لا يمكن التعليق إلا بعد إتمام رحلة معاً',
      );
    });

    test('409 — الرحلة الواحدة مرّة واحدة', () {
      expect(HandelErorrMessage.rateUser('You have already rated this ride.'),
          HandelErorrMessage.alreadyRatedRide);
      expect(
          HandelErorrMessage.commet(
              'You have already left a comment for this ride.'),
          HandelErorrMessage.alreadyCommentedRide);
    });
  });
}
