import 'dart:io';

import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:hive/hive.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/vieryfiy_user/data/data_source/verifit_user_remote_data_source.dart';
import 'package:alatarekak/features/vieryfiy_user/data/model/verifiy_user_modle.dart';
import 'package:alatarekak/features/vieryfiy_user/data/repo/verfiy_user_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class MockApi extends Mock implements DioConSumer {}

class MockDataSource extends Mock implements VerifitUserRemoteDataSource {}

class FakeXFile extends Fake implements XFile {}

/// انهيار شاشة التوثيق عند الضغط على «إرسال».
///
/// كان `VerifiyUserModle.fromJson(response)` تحويلاً ضمنياً من `dynamic`
/// إلى `Map<String, dynamic>`: يرمي `TypeError` على أي ردّ ليس كائن JSON
/// — جسم فارغ، أو مصفوفة، أو نصّ. و`TypeError` ليس `ServerExpcptions`،
/// فكان يمرّ من فوق `catch` في المستودع ويخرج غير ملتقَط.

void main() {
  late Directory tempDir;

  setUpAll(() => registerFallbackValue(FakeXFile()));

  // مصدر البيانات يقرأ التوكن من Hive، ومستودعه يمسح كاش الملف الشخصي —
  // فيُهيّأ صندوق حقيقي على مجلد مؤقّت بدل محاكاته.
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('verify_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    await Hive.openBox<UserModel>(HiveBoxes.authBoxName);
  });

  tearDown(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('تفكيك ردّ الرفع — لا ينهار على شكل غير متوقَّع', () {
    late MockApi api;
    late VerifitUserRemoteDataSource dataSource;

    setUp(() {
      api = MockApi();
      dataSource = VerifitUserRemoteDataSource(api: api);
    });

    void stub(dynamic response) {
      when(() => api.post(any(),
          data: any(named: 'data'),
          header: any(named: 'header'),
          isFomrData: any(named: 'isFomrData'))).thenAnswer((_) async => response);
    }

    for (final entry in <String, dynamic>{
      'جسم فارغ (201 بلا محتوى)': null,
      'نصّ عارٍ': 'Documents uploaded',
      'مصفوفة': <dynamic>[],
      'كائن بلا مغلَّف': {'message': 'تم الرفع'},
      'مغلَّف ناجح': {'status': 'success', 'message': 'ok'},
      'مغلَّف ناجح بصيغة success': {'success': true},
    }.entries) {
      test('«${entry.key}» يمرّ بلا انهيار', () async {
        stub(entry.value);
        await expectLater(
            dataSource.checkUpPassenger(null, null), completes);
      });
    }

    test('الخادم يقول success:false صراحةً → ServerExpcptions لا نجاح كاذب',
        () async {
      stub({'success': false, 'message': 'Verification request already exists'});

      await expectLater(
        dataSource.checkUpDriver(null, null, null, null),
        throwsA(isA<ServerExpcptions>().having((e) => e.error.message,
            'message', 'Verification request already exists')),
      );
    });

    test('status:error يُلتقط أيضاً (المغلَّف الثاني)', () async {
      stub({'status': 'error', 'message': 'Rejected'});

      await expectLater(dataSource.checkUpPassenger(null, null),
          throwsA(isA<ServerExpcptions>()));
    });
  });

  group('المستودع يلتقط كل استثناء لا ServerExpcptions وحده', () {
    late MockDataSource dataSource;
    late VerfiYUserRepo repo;

    setUp(() {
      dataSource = MockDataSource();
      repo = VerfiYUserRepo(verifitUserRemoteDataSource: dataSource);
    });

    test('TypeError من التفكيك يعود Left لا يخرج ليُسقط الشاشة', () async {
      when(() => dataSource.checkUpDriver(any(), any(), any(), any()))
          .thenThrow(TypeError());

      final result = await repo.verfiyDriver(null, null, null, null);

      expect(result.isLeft(), isTrue);
    });

    test('استثناء عام أثناء رفع الراكب يعود Left', () async {
      when(() => dataSource.checkUpPassenger(any(), any()))
          .thenThrow(Exception('فشل غير متوقّع'));

      final result = await repo.verfiyPassanger(null, null);

      expect(result.isLeft(), isTrue);
    });

    test('ServerExpcptions تُنقل برسالتها كما كانت', () async {
      when(() => dataSource.checkUpPassenger(any(), any())).thenThrow(
          ServerExpcptions(error: const Filuar(message: 'Unauthenticated.')));

      final result = await repo.verfiyPassanger(null, null);

      expect(result.fold((f) => f.message, (_) => null), 'Unauthenticated.');
    });

    test('النجاح يبقى نجاحاً', () async {
      when(() => dataSource.checkUpDriver(any(), any(), any(), any()))
          .thenAnswer((_) async => VerifiyUserModle());

      final result = await repo.verfiyDriver(null, null, null, null);

      expect(result.isRight(), isTrue);
    });
  });
}
