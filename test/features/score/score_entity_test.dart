import 'package:alatarekak/features/score/data/model/score_model.dart';
import 'package:alatarekak/features/score/domain/entity/score_entity.dart';
import 'package:flutter_test/flutter_test.dart';

/// كيان نقاط الثقة وسجلّها.
///
/// كانت `tierLabels` تحوي `platinum` غير الموجود عند الخادم وتُغفل
/// `restricted` وهو الافتراضي، و`isPositive` تُصنّف «+0» مكافأةً،
/// و`ScoreHistoryModel.fromJson` تُحوّل `id` تحويلاً غير محروس.

void main() {
  group('المستويات', () {
    test('كل مستوى يُترجَم — ومنها restricted الافتراضي', () {
      String label(String tier) => ScoreEntity(
            score: 0,
            tier: tier,
            cancelRate: 0,
            totalRides: 0,
            totalCancellations: 0,
            canCreateRides: false,
            canBookRides: false,
          ).tierLabel;

      expect(label('restricted'), 'مقيَّد');
      expect(label('Restricted'), 'مقيَّد', reason: 'رد /profile يرسلها بحرف كبير');
      expect(label('bronze'), 'برونزي');
      expect(label('silver'), 'فضي');
      expect(label('gold'), 'ذهبي');
    });

    test('مستوى مجهول يُعرض كما وصل بلا اختراع', () {
      expect(
        ScoreEntity(
          score: 0,
          tier: 'diamond',
          cancelRate: 0,
          totalRides: 0,
          totalCancellations: 0,
          canCreateRides: false,
          canBookRides: false,
        ).tierLabel,
        'diamond',
      );
    });

    test('حدّا العمل مثبَّتان كما في §5.1', () {
      expect(ScoreEntity.minScoreToCreate, 50);
      expect(ScoreEntity.minScoreToBook, 40);
    });
  });

  group('إشارة الحركة', () {
    ScoreHistoryEntity entry(String points) => ScoreHistoryEntity(
          id: 1,
          action: 'ride_completed',
          points: points,
          previousScore: 50,
          newScore: 55,
          reason: 'Completed a ride',
        );

    test('«+5» زيادة و«-10» خصم', () {
      expect(entry('+5').isPositive, isTrue);
      expect(entry('+5').pointsDelta, 5);
      expect(entry('-10').isNegative, isTrue);
      expect(entry('-10').pointsDelta, -10);
    });

    test('«+0» ليست مكافأة (الخطأ المُصلَح)', () {
      expect(entry('+0').isPositive, isFalse);
      expect(entry('+0').isNegative, isFalse);
      expect(entry('+0').isNeutral, isTrue);
      expect(entry('+0').deltaLabel, 'بلا تغيير في النقاط');
    });

    test('رقم بلا إشارة يُقرأ زيادة', () {
      expect(entry('7').pointsDelta, 7);
      expect(entry('7').isPositive, isTrue);
    });

    test('قيمة غير رقمية لا ترمي', () {
      expect(entry('لا-شيء').pointsDelta, 0);
      expect(entry('لا-شيء').isNeutral, isTrue);
    });
  });

  group('صياغة النقاط بالعربية', () {
    test('المفرد والمثنّى وجمعا القلّة والكثرة', () {
      expect(ScoreHistoryEntity.pointsPhrase(1), 'نقطة واحدة');
      expect(ScoreHistoryEntity.pointsPhrase(2), 'نقطتين');
      expect(ScoreHistoryEntity.pointsPhrase(5), '5 نقاط');
      expect(ScoreHistoryEntity.pointsPhrase(10), '10 نقاط');
      expect(ScoreHistoryEntity.pointsPhrase(15), '15 نقطة');
    });

    test('سطر السجل كما يريده المستخدم', () {
      ScoreHistoryEntity e(String p) => ScoreHistoryEntity(
            id: 1,
            action: '',
            points: p,
            previousScore: 0,
            newScore: 0,
            reason: '',
          );

      expect(e('-5').deltaLabel, 'تم خصم 5 نقاط');
      expect(e('+10').deltaLabel, 'تمت إضافة 10 نقاط');
      expect(e('-1').deltaLabel, 'تم خصم نقطة واحدة');
      expect(e('+2').deltaLabel, 'تمت إضافة نقطتين');
    });

    test('السطر لا يعتمد على action فيصحّ أياً كان ما يرسله الخادم', () {
      final unknown = ScoreHistoryEntity(
        id: 1,
        action: 'something_we_never_heard_of',
        points: '-5',
        previousScore: 0,
        newScore: 0,
        reason: 'English reason',
      );
      expect(unknown.deltaLabel, 'تم خصم 5 نقاط');
      expect(unknown.actionLabel, isNull,
          reason: 'لا نُخرج نصّ الخادم الإنجليزي للمستخدم');
    });

    test('action معروف يُترجَم', () {
      final known = ScoreHistoryEntity(
        id: 1,
        action: 'ride_completed',
        points: '+10',
        previousScore: 0,
        newScore: 0,
        reason: '',
      );
      expect(known.actionLabel, 'إكمال رحلة');
    });
  });

  group('ScoreHistoryModel.fromJson — تفكيك محصَّن', () {
    test('الشكل الكامل كما في §5.2', () {
      final m = ScoreHistoryModel.fromJson(const {
        'id': 12,
        'action': 'ride_cancelled',
        'points': '-10',
        'previous_score': 60,
        'new_score': 50,
        'reason': 'Cancelled a ride less than 2 hours before departure',
        'high_cancel_rate_applied': true,
        'reference_type': 'ride',
        'reference_id': 7,
        'created_at': '2026-08-16T21:52:11+00:00',
      });

      expect(m.id, 12);
      expect(m.pointsDelta, -10);
      expect(m.newScore, 50);
      expect(m.highCancelRateApplied, isTrue);
      expect(m.createdAt, isNotNull);
      expect(m.actionLabel, 'إلغاء رحلة');
      expect(m.deltaLabel, 'تم خصم 10 نقاط');
    });

    test('غياب id لا يرمي (الخطأ المُصلَح)', () {
      expect(() => ScoreHistoryModel.fromJson(const {'points': '-5'}),
          returnsNormally);
      expect(ScoreHistoryModel.fromJson(const {'points': '-5'}).id, 0);
    });

    test('id نصاً يُقرأ رقماً', () {
      expect(ScoreHistoryModel.fromJson(const {'id': '9'}).id, 9);
    });

    test('تاريخ غير صالح يصير null لا استثناء', () {
      final m = ScoreHistoryModel.fromJson(const {
        'id': 1,
        'created_at': 'ليس تاريخاً',
      });
      expect(m.createdAt, isNull);
    });

    test('غياب high_cancel_rate_applied يعني false', () {
      expect(ScoreHistoryModel.fromJson(const {'id': 1}).highCancelRateApplied,
          isFalse);
    });
  });

  group('ScoreModel.fromJson', () {
    test('الشكل الكامل كما في §5.1', () {
      final m = ScoreModel.fromJson(const {
        'score': 85,
        'tier': 'gold',
        'cancel_rate': 3.5,
        'total_rides': 40,
        'total_cancellations': 2,
        'can_create_rides': true,
        'can_book_rides': true,
      });

      expect(m.score, 85);
      expect(m.tierLabel, 'ذهبي');
      expect(m.cancelRate, 3.5);
      expect(m.canCreateRides, isTrue);
    });

    test('غياب الأذونات يسقط إلى قواعد العمل', () {
      final low = ScoreModel.fromJson(const {'score': 45});
      expect(low.canCreateRides, isFalse, reason: '45 < 50');
      expect(low.canBookRides, isTrue, reason: '45 >= 40');
    });

    test('رحلة الكاش المحلي تحفظ كل الحقول', () {
      const raw = {
        'score': 85,
        'tier': 'gold',
        'cancel_rate': 3.5,
        'total_rides': 40,
        'total_cancellations': 2,
        'can_create_rides': true,
        'can_book_rides': true,
      };
      final restored = ScoreModel.fromJson(ScoreModel.fromJson(raw).toJson());
      expect(restored.score, 85);
      expect(restored.tier, 'gold');
      expect(restored.cancelRate, 3.5);
    });
  });
}
