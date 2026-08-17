import 'package:alatarekak/core/api/api_consumer.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/features/score/data/data_source/score_remote_data_source.dart';
import 'package:alatarekak/features/score/data/model/score_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// رد `GET /api/score/transactions` كما شحنه الباك إند: الحركة كائنات
/// متداخلة (`event` و`points` و`score`) لا صفّاً مسطّحاً كما وصفت
/// المواصفة (§5.2)، ومعها `meta` للترقيم.

Map<String, dynamic> _transaction({
  int id = 42,
  String code = 'ride_completed',
  int value = 10,
  String display = '+10',
  int before = 80,
  int after = 90,
  bool highCancelRate = false,
  String occurredAt = '2026-08-17T09:35:00+00:00',
}) =>
    {
      'id': id,
      'event': {
        'code': code,
        'label': 'Ride completed',
        'summary': '$display pts — Ride completed',
      },
      'points': {'value': value, 'display': display},
      'score': {'before': before, 'after': after, 'delta': after - before},
      'reason': 'Ride completed successfully — all parties rewarded',
      'high_cancel_rate_applied': highCancelRate,
      'occurred_at': occurredAt,
    };

Map<String, dynamic> _response({
  List<Map<String, dynamic>>? data,
  int total = 84,
  int perPage = 20,
  int currentPage = 1,
  int lastPage = 5,
}) =>
    {
      'success': true,
      'data': data ?? [_transaction()],
      'meta': {
        'total': total,
        'per_page': perPage,
        'current_page': currentPage,
        'last_page': lastPage,
      },
    };

class MockApi extends Mock implements ApiConSumer {}

void main() {
  group('الحركة الواحدة — الشكل المتداخل', () {
    test('الحقول تُقرأ من مواضعها الجديدة', () {
      final m = ScoreHistoryModel.fromJson(_transaction());

      expect(m.id, 42);
      expect(m.action, 'ride_completed', reason: 'من event.code');
      expect(m.points, '+10', reason: 'من points.display');
      expect(m.previousScore, 80, reason: 'من score.before');
      expect(m.newScore, 90, reason: 'من score.after');
      expect(m.highCancelRateApplied, isFalse);
      expect(m.createdAt?.toUtc(), DateTime.utc(2026, 8, 17, 9, 35),
          reason: 'من occurred_at');
    });

    test('الفرق يُؤخذ من points.value لا من انتزاعه من النصّ', () {
      // نصّ العرض هنا مكسور عمداً: الرقم الصريح هو المرجع
      final m = ScoreHistoryModel.fromJson({
        ..._transaction(value: -5, display: 'غير مفهوم'),
        'score': {'before': 90, 'after': 85, 'delta': -5},
      });

      expect(m.pointsDelta, -5);
      expect(m.isNegative, isTrue);
      expect(m.deltaLabel, 'تم خصم 5 نقاط');
    });

    test('الخصم بجزاء معدّل الإلغاء', () {
      final m = ScoreHistoryModel.fromJson(_transaction(
        code: 'driver_cancel_ride_late',
        value: -15,
        display: '-15',
        before: 90,
        after: 75,
        highCancelRate: true,
      ));

      expect(m.pointsDelta, -15);
      expect(m.newScore, 75);
      expect(m.highCancelRateApplied, isTrue);
      expect(m.actionLabel, 'إلغاء السائق للرحلة متأخراً');
      expect(m.deltaLabel, 'تم خصم 15 نقطة');
    });

    test('نصوص الخادم الإنجليزية لا تصل للمستخدم', () {
      final m = ScoreHistoryModel.fromJson(_transaction());

      expect(m.actionLabel, 'إكمال رحلة');
      expect(m.deltaLabel, 'تمت إضافة 10 نقاط');
      // label و summary و reason إنجليزية — تُقرأ ولا تُعرض
      expect(m.actionLabel, isNot(contains('Ride')));
      expect(m.deltaLabel, isNot(contains('pts')));
    });

    test('حدث لا نعرفه: السطر الأساسي يصحّ والثانوي يُخفى', () {
      final m = ScoreHistoryModel.fromJson(
          _transaction(code: 'moon_landing_bonus', value: 3, display: '+3'));

      expect(m.deltaLabel, 'تمت إضافة 3 نقاط');
      expect(m.actionLabel, isNull);
    });
  });

  group('الصفحة — meta', () {
    test('الترقيم يُقرأ وhasMore يعرف أن بعده صفحات', () {
      final page = ScoreHistoryPageModel.fromJson(_response());

      expect(page.items, hasLength(1));
      expect(page.total, 84);
      expect(page.perPage, 20);
      expect(page.currentPage, 1);
      expect(page.lastPage, 5);
      expect(page.hasMore, isTrue);
    });

    test('الصفحة الأخيرة لا تطلب المزيد', () {
      final page = ScoreHistoryPageModel.fromJson(
          _response(currentPage: 5, lastPage: 5));
      expect(page.hasMore, isFalse);
    });

    test('سجل فارغ: صفحة سليمة بلا عناصر', () {
      final page = ScoreHistoryPageModel.fromJson(
          _response(data: const [], total: 0, lastPage: 1));

      expect(page.items, isEmpty);
      expect(page.total, 0);
      expect(page.hasMore, isFalse);
    });

    test('غياب meta لا يكسر الصفحة', () {
      final page = ScoreHistoryPageModel.fromJson({
        'success': true,
        'data': [_transaction()],
      });

      expect(page.items, hasLength(1));
      expect(page.total, 1);
      expect(page.currentPage, 1);
      expect(page.hasMore, isFalse);
    });

    test('مصفوفة عارية (الشكل القديم) ما زالت تُقرأ', () {
      final page = ScoreHistoryPageModel.fromJson([_transaction()]);
      expect(page.items, hasLength(1));
      expect(page.hasMore, isFalse);
    });

    test('صفّ مكسور بين الصفوف لا يُسقط الصفحة كلها', () {
      final page = ScoreHistoryPageModel.fromJson(_response(data: [
        _transaction(),
        {'id': 'ليس رقماً', 'occurred_at': 'ليس تاريخاً'},
      ]));

      expect(page.items, hasLength(2));
      expect(page.items.last.id, 0);
      expect(page.items.last.createdAt, isNull);
    });
  });

  group('ScoreRemoteDataSource — المسار والترقيم', () {
    late MockApi api;
    late ScoreRemoteDataSourceIm dataSource;

    setUp(() {
      api = MockApi();
      dataSource = ScoreRemoteDataSourceIm(api: api);
    });

    void stub(dynamic response) {
      when(() => api.get(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => response);
    }

    test('يطلب /score/transactions لا /score/history', () async {
      stub(_response());
      await dataSource.getHistory();

      final path = verify(() => api.get(captureAny(),
          queryParameters: any(named: 'queryParameters'))).captured.single;
      expect(path, ApiEndPoint.scoreTransactions);
      expect(path.toString(), endsWith('/score/transactions'));
    });

    test('رقم الصفحة وحجمها يُرسلان في الاستعلام', () async {
      stub(_response(currentPage: 3));
      await dataSource.getHistory(page: 3, perPage: 20);

      final query = verify(() => api.get(any(),
              queryParameters: captureAny(named: 'queryParameters')))
          .captured
          .single as Map<String, dynamic>;
      expect(query['page'], 3);
      expect(query['per_page'], 20);
    });

    test('حجم صفحة خارج الحدود يُقيَّد قبل الإرسال', () async {
      stub(_response());
      await dataSource.getHistory(page: 0, perPage: 500);

      final query = verify(() => api.get(any(),
              queryParameters: captureAny(named: 'queryParameters')))
          .captured
          .single as Map<String, dynamic>;
      expect(query['page'], 1, reason: 'لا صفحة قبل الأولى');
      expect(query['per_page'], 50, reason: 'أقصى ما يقبله الخادم');
    });

    test('الصفحة تعود بعناصرها وترقيمها', () async {
      stub(_response());
      final page = await dataSource.getHistory();

      expect(page.items.single.id, 42);
      expect(page.total, 84);
      expect(page.hasMore, isTrue);
    });

    test('رد فاشل يرمي ServerExpcptions برسالة الخادم', () async {
      stub({'success': false, 'message': 'Unauthenticated.'});

      await expectLater(
        dataSource.getHistory(),
        throwsA(isA<ServerExpcptions>().having(
            (e) => e.error.message, 'message', 'Unauthenticated.')),
      );
    });
  });
}
