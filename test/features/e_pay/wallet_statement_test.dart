import 'package:alatarekak/features/e_pay/data/model/wallet_transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// رد GET /api/wallet/transactions كما يرسله الخادم فعلاً: بلا مغلَّف
/// `success` ولا `status`، والمبالغ كلها **نصوص** بخانتين عشريتين،
/// و`meta` يخلط الرصيد والدين مع حقول الترقيم.
Map<String, dynamic> _response({
  String balance = '45000.00',
  String debt = '0.00',
  int currentPage = 1,
  int lastPage = 4,
  List<Map<String, dynamic>>? items,
}) =>
    {
      'data': items ??
          [
            {
              'id': 812,
              'type': 'cash_ride_creation_fee',
              'amount': '-5000.00',
              'balance_after': '45000.00',
              'description': 'Cash ride creation fee (5%) — ride #7',
              'reference': 'ride:7',
              'created_at': '2026-08-13T12:00:00+03:00',
            },
          ],
      'links': {'first': '…', 'last': '…', 'prev': null, 'next': '…'},
      'meta': {
        'balance': balance,
        'cash_ride_debt': debt,
        'current_page': currentPage,
        'last_page': lastPage,
        'per_page': 15,
        'total': 52,
      },
    };

void main() {
  group('WalletStatement — تفكيك رد بلا مغلَّف', () {
    test('المبالغ نصوص تُقرأ كأعداد عشرية لا صحيحة', () {
      final s = WalletTransactionModel.statementFromJson(_response());
      final tx = s.items.single;

      expect(tx.amount, -5000.0);
      expect(tx.balanceAfter, 45000.0);
      expect(s.balance, 45000.0);
    });

    test('يقبل الرقم أيضاً لو غيّر الخادم النوع لاحقاً', () {
      final r = _response();
      (r['data'] as List)[0]['amount'] = -5000;
      r['meta']['balance'] = 45000;

      final s = WalletTransactionModel.statementFromJson(r);
      expect(s.items.single.amount, -5000.0);
      expect(s.balance, 45000.0);
    });

    test('cash_ride_debt يُقرأ من meta — لا من نصّ رسالة خطأ', () {
      final s = WalletTransactionModel.statementFromJson(
          _response(debt: '15000.00'));

      expect(s.cashRideDebt, 15000.0);
      expect(s.hasDebt, isTrue);
    });

    test('لا دين حين تكون القيمة صفراً', () {
      expect(WalletTransactionModel.statementFromJson(_response()).hasDebt,
          isFalse);
    });

    test('الترقيم يُقرأ من meta وتُحسب منه hasMore', () {
      final s = WalletTransactionModel.statementFromJson(_response());
      expect(s.currentPage, 1);
      expect(s.lastPage, 4);
      expect(s.total, 52);
      expect(s.hasMore, isTrue);

      final last = WalletTransactionModel.statementFromJson(
          _response(currentPage: 4, lastPage: 4));
      expect(last.hasMore, isFalse);
    });

    test('التاريخ يُحوَّل إلى التوقيت المحلي', () {
      final s = WalletTransactionModel.statementFromJson(_response());
      expect(s.items.single.createdAt, isNotNull);
      expect(s.items.single.createdAt!.isUtc, isFalse);
    });

    test('رد فارغ لا يُسقط التفكيك', () {
      final s = WalletTransactionModel.statementFromJson({});
      expect(s.items, isEmpty);
      expect(s.balance, 0);
      expect(s.hasDebt, isFalse);
    });
  });

  group('WalletStatement — الشكل الفعلي الذي رصده فريق لوحة الإدارة', () {
    /// شغّل فريق الويب المسار مقابل الخادم الحقيقي فوجد مُرقِّم Laravel
    /// خاماً تحت `transactions` وبلا كتلة `meta` — بخلاف المواصفة
    /// المرسَلة. التفكيك يقبل الشكلين حتى يُحسم التناقض.
    Map<String, dynamic> paginatorShape() => {
          'transactions': {
            'current_page': 2,
            'last_page': 5,
            'total': 73,
            'per_page': 15,
            'data': [
              {
                'id': 900,
                'type': 'cash_ride_debt_cleared',
                'amount': '-2500.00',
                'balance_after': '12000.00',
                'description': 'debt cleared',
              }
            ],
          },
          'balance': '12000.00',
          'cash_ride_debt': '0.00',
        };

    test('القائمة تُقرأ من transactions.data لا من data', () {
      final s = WalletTransactionModel.statementFromJson(paginatorShape());
      expect(s.items, hasLength(1));
      expect(s.items.single.amount, -2500.0);
    });

    test('الترقيم يُقرأ من جذر المُرقِّم حين تغيب meta', () {
      final s = WalletTransactionModel.statementFromJson(paginatorShape());
      expect(s.currentPage, 2);
      expect(s.lastPage, 5);
      expect(s.total, 73);
      expect(s.hasMore, isTrue);
    });

    test('الرصيد والدين يُقرآن من الجذر حين تغيب meta', () {
      final r = paginatorShape()..['cash_ride_debt'] = '7500.00';
      final s = WalletTransactionModel.statementFromJson(r);
      expect(s.balance, 12000.0);
      expect(s.cashRideDebt, 7500.0);
      expect(s.hasDebt, isTrue);
    });

    test('الشكل الموصوف في المواصفة ما زال يعمل', () {
      final s = WalletTransactionModel.statementFromJson(
          _response(debt: '300.00'));
      expect(s.items, hasLength(1));
      expect(s.cashRideDebt, 300.0);
      expect(s.currentPage, 1);
    });
  });

  group('WalletTransaction — حركات التدقيق بقيمة صفر', () {
    test('تأجيل الرسم كديْن ليس حركة مالية', () {
      final r = _response(items: [
        {
          'id': 1,
          'type': 'cash_ride_fee_deferred',
          'amount': '0.00',
          'balance_after': '45000.00',
          'description': 'deferred',
          'reference': 'ride:9',
        }
      ]);
      final tx = WalletTransactionModel.statementFromJson(r).items.single;

      expect(tx.isAuditOnly, isTrue,
          reason: 'الرصيد لا يتغيّر — الدين هو الذي يزيد');
      expect(tx.isCredit, isFalse);
      expect(tx.label, 'تأجيل رسوم الإنشاء كديْن');
    });

    test('الخصم سالب والإيداع موجب', () {
      final r = _response(items: [
        {'id': 1, 'type': 'cash_ride_fee_refund', 'amount': '5000.00',
         'balance_after': '50000.00', 'description': ''},
      ]);
      final tx = WalletTransactionModel.statementFromJson(r).items.single;
      expect(tx.isCredit, isTrue);
      expect(tx.isAuditOnly, isFalse);
    });

    test('كل الأنواع الستّة المعروفة لها ترجمة عربية', () {
      const types = [
        'cash_ride_creation_fee',
        'cash_ride_fee_deferred',
        'cash_ride_fee_refund',
        'cash_ride_fee_debt_cancelled',
        'cash_ride_fee_no_refund',
        'cash_ride_debt_cleared',
      ];
      for (final t in types) {
        final r = _response(items: [
          {'id': 1, 'type': t, 'amount': '0.00', 'balance_after': '0.00',
           'description': ''}
        ]);
        final tx = WalletTransactionModel.statementFromJson(r).items.single;
        expect(tx.label, isNot('حركة على المحفظة'),
            reason: 'النوع $t بلا ترجمة');
      }
    });

    test('نوع غير معروف يسقط إلى وصف عام بلا انكسار', () {
      final r = _response(items: [
        {'id': 1, 'type': 'brand_new_type', 'amount': '10.00',
         'balance_after': '0.00', 'description': ''}
      ]);
      expect(WalletTransactionModel.statementFromJson(r).items.single.label,
          'حركة على المحفظة');
    });

    test('reference يُفكَّك إلى معرّف الرحلة', () {
      final s = WalletTransactionModel.statementFromJson(_response());
      expect(s.items.single.referenceId, 7);
    });
  });
}
