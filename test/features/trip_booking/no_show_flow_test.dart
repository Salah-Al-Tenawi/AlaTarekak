import 'dart:io';

import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/core/service/no_show_report_store.dart';
import 'package:alatarekak/core/utils/class/no_show_report.dart';
import 'package:alatarekak/features/trip_booking/data/repo/booking_me_repo.dart';
import 'package:alatarekak/features/trip_booking/presantion/manger/cubit/booking_me_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBookingMeRepo extends Mock implements BookingMeRepo {}

/// دورة بلاغ الغياب من جانب الراكب.
///
/// ثلاث نهايات والخادم لا يميّزها بحقل: التعارض يصل **200 كالنجاح** بنصّ
/// مختلف، و«سبق الإبلاغ» يصل **422 كالخطأ** وهو في المعنى نجاح متأخّر.
/// ولا مسار `GET` يكشف تقارير الغياب، فحالة «أبلغتُ» محليّة بالضرورة.
const int _rideId = 5;

const _successBody = {
  'status': 'success',
  'message': 'No-show report submitted. The driver has 2 hours to dispute. '
      'If no dispute, the penalty is applied automatically.',
};

const _conflictBody = {
  'status': 'success',
  'message': 'Both parties filed a no-show report. A support complaint has '
      'been opened automatically. No automatic penalty will be applied — '
      'the support team will investigate.',
};

void main() {
  late MockBookingMeRepo repo;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('no_show_flow');
    Hive.init(tempDir.path);
    await Hive.openBox<String>(HiveBoxes.cacheBoxName);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } on FileSystemException {
      // قفل ملفات مؤقت على ويندوز — غير مؤثر
    }
  });

  setUp(() async {
    repo = MockBookingMeRepo();
    await NoShowReportStore.clear();
  });

  BookingMeCubit build() => BookingMeCubit(repo);

  group('بلاغ مقبول', () {
    test('يُصدر النتيجة «مُبلَّغ» ويُذكر مهلة الاعتراض', () async {
      when(() => repo.driverNoShow(any()))
          .thenAnswer((_) async => right(_successBody));

      final cubit = build();
      addTearDown(cubit.close);
      await cubit.reportDriverNoShow(_rideId);

      final state = cubit.state as BookingMeDriverNoShowReported;
      expect(state.outcome, NoShowOutcome.reported);
      expect(state.message, contains('مهلة للاعتراض'));
    });

    test('يُحفظ محلياً فيُقفل الزرّ — لا مصدر حقيقة على الخادم', () async {
      when(() => repo.driverNoShow(any()))
          .thenAnswer((_) async => right(_successBody));

      final cubit = build();
      addTearDown(cubit.close);

      expect(
          NoShowReportStore.wasReported(NoShowReportStore.rideKey(_rideId)),
          isFalse);

      await cubit.reportDriverNoShow(_rideId);

      expect(
          NoShowReportStore.wasReported(NoShowReportStore.rideKey(_rideId)),
          isTrue);
    });

    test('المفتاح يخصّ رحلته وحدها', () async {
      when(() => repo.driverNoShow(any()))
          .thenAnswer((_) async => right(_successBody));

      final cubit = build();
      addTearDown(cubit.close);
      await cubit.reportDriverNoShow(_rideId);

      expect(NoShowReportStore.wasReported(NoShowReportStore.rideKey(99)),
          isFalse);
    });
  });

  group('تعارض — الطرفان أبلغا', () {
    test('يُقرأ تعارضاً رغم أنه 200 كالنجاح', () async {
      when(() => repo.driverNoShow(any()))
          .thenAnswer((_) async => right(_conflictBody));

      final cubit = build();
      addTearDown(cubit.close);
      await cubit.reportDriverNoShow(_rideId);

      final state = cubit.state as BookingMeDriverNoShowReported;
      expect(state.outcome, NoShowOutcome.conflict);
      expect(state.message, contains('شكوى'));
      expect(state.message, contains('لا عقوبة'));
    });

    test('يُحفظ محلياً كذلك — البلاغ سُجّل فعلاً', () async {
      when(() => repo.driverNoShow(any()))
          .thenAnswer((_) async => right(_conflictBody));

      final cubit = build();
      addTearDown(cubit.close);
      await cubit.reportDriverNoShow(_rideId);

      expect(
          NoShowReportStore.wasReported(NoShowReportStore.rideKey(_rideId)),
          isTrue);
    });
  });

  group('«سبق أن أبلغت» — 422 يُعامَل نجاحاً متأخّراً', () {
    test('لا يُصدر خطأً بل نتيجة', () async {
      when(() => repo.driverNoShow(any())).thenAnswer((_) async => left(
          const Filuar(
              message:
                  'You have already submitted a no-show report for this ride.')));

      final cubit = build();
      addTearDown(cubit.close);
      await cubit.reportDriverNoShow(_rideId);

      expect(cubit.state, isA<BookingMeDriverNoShowReported>());
      expect(cubit.state, isNot(isA<BookingMeErorr>()));
      expect((cubit.state as BookingMeDriverNoShowReported).outcome,
          NoShowOutcome.alreadyReported);
    });

    test('يُعيد بناء الحالة المحلية الضائعة فيُقفل الزرّ', () async {
      // الحالة تضيع بإعادة التثبيت أو تسجيل الخروج — والخادم يمسك الحقيقة
      when(() => repo.driverNoShow(any())).thenAnswer((_) async => left(
          const Filuar(
              message:
                  'You have already submitted a no-show report for this ride.')));

      final cubit = build();
      addTearDown(cubit.close);
      await cubit.reportDriverNoShow(_rideId);

      expect(
          NoShowReportStore.wasReported(NoShowReportStore.rideKey(_rideId)),
          isTrue);
    });
  });

  group('أخطاء حقيقية تبقى أخطاء', () {
    test('البوابة مقفلة: خطأ معرَّب بالدقائق', () async {
      when(() => repo.driverNoShow(any())).thenAnswer((_) async => left(
          const Filuar(
              message: 'No-show reporting unlocks 1 hour after departure. '
                  '37 minute(s) remaining.')));

      final cubit = build();
      addTearDown(cubit.close);
      await cubit.reportDriverNoShow(_rideId);

      final state = cubit.state as BookingMeErorr;
      expect(state.message, contains('37 دقيقة'));
    });

    test('لا حجز مؤكَّد: خطأ معرَّب ولا حفظ محلي', () async {
      when(() => repo.driverNoShow(any())).thenAnswer((_) async => left(
          const Filuar(
              message: 'No confirmed booking found for you on this ride.')));

      final cubit = build();
      addTearDown(cubit.close);
      await cubit.reportDriverNoShow(_rideId);

      expect(cubit.state, isA<BookingMeErorr>());
      expect(
          NoShowReportStore.wasReported(NoShowReportStore.rideKey(_rideId)),
          isFalse,
          reason: 'بلاغ لم يُقبل لا يُقفل الزرّ');
    });
  });
}
