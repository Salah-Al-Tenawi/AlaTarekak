import 'package:alatarekak/core/errors/filuar.dart';
import 'package:flutter_test/flutter_test.dart';

/// اختبارات تحليل كائن الفشل الموحّد Filuar لكل أشكال أخطاء الباك إند.
void main() {
  group('Filuar.fromJson', () {
    test('يقرأ المغلف A: {success:false, message}', () {
      final filuar = Filuar.fromJson(const {
        'success': false,
        'message': 'Invalid credentials',
      });

      expect(filuar.message, 'Invalid credentials');
      expect(filuar.code, isNull);
      expect(filuar.isValidation, isFalse);
    });

    test('يقرأ المغلف B: {status:error, message, code}', () {
      final filuar = Filuar.fromJson(const {
        'status': 'error',
        'message': 'Token has expired',
        'code': 'TOKEN_EXPIRED',
      });

      expect(filuar.message, 'Token has expired');
      expect(filuar.code, 'TOKEN_EXPIRED');
    });

    test('يقرأ شكل Laravel 422: {message, errors:{field:[msgs]}}', () {
      final filuar = Filuar.fromJson(const {
        'message': 'Validation failed',
        'errors': {
          'email': ['The email field is required.'],
          'password': ['The password must be at least 8 characters.'],
        },
      });

      expect(filuar.isValidation, isTrue);
      expect(filuar.hasFieldError('email'), isTrue);
      expect(filuar.hasFieldError('phone'), isFalse);
      expect(filuar.firstFieldError, 'The email field is required.');
      expect(filuar.errors!['password'],
          ['The password must be at least 8 characters.']);
    });

    test('يستخدم أول خطأ تحقق كرسالة عندما تغيب message', () {
      final filuar = Filuar.fromJson(const {
        'errors': {
          'seats': ['Not enough seats available.'],
        },
      });

      expect(filuar.message, 'Not enough seats available.');
    });

    test('يقبل خطأ تحقق بقيمة مفردة (ليست قائمة)', () {
      final filuar = Filuar.fromJson(const {
        'errors': {'amount': 'The amount must be a number.'},
      });

      expect(filuar.errors!['amount'], ['The amount must be a number.']);
    });

    test('يقرأ الرسالة من error ككائن متداخل {error:{message}}', () {
      final filuar = Filuar.fromJson(const {
        'error': {'message': 'Ride not found'},
      });

      expect(filuar.message, 'Ride not found');
    });

    test('يقرأ الرسالة من error كنص مباشر', () {
      final filuar = Filuar.fromJson(const {'error': 'Server error'});

      expect(filuar.message, 'Server error');
    });

    test('يرجع رسالة عربية افتراضية عند json فارغ', () {
      final filuar = Filuar.fromJson(const {});

      expect(filuar.message, 'حدث خطأ غير متوقع');
    });

    group('معلومات الحظر BanInfo', () {
      test('حظر مؤقت مع تاريخ انتهاء', () {
        final filuar = Filuar.fromJson(const {
          'message': 'Your account is banned',
          'code': 'USER_BANNED',
          'ban': {
            'reason': 'Repeated no-show',
            'type': 'temporary',
            'expires_at': '2026-08-01T00:00:00Z',
          },
        });

        expect(filuar.ban, isNotNull);
        expect(filuar.ban!.isPermanent, isFalse);
        expect(filuar.ban!.reason, 'Repeated no-show');
        expect(filuar.ban!.expiresAt, '2026-08-01T00:00:00Z');
      });

      test('حظر دائم بدون تاريخ انتهاء', () {
        final filuar = Filuar.fromJson(const {
          'message': 'Your account is banned',
          'ban': {'reason': 'Fraud', 'type': 'permanent'},
        });

        expect(filuar.ban!.isPermanent, isTrue);
        expect(filuar.ban!.expiresAt, isNull);
      });

      test('ban الافتراضي permanent عند غياب type', () {
        final ban = BanInfo.fromJson(const {'reason': 'x'});

        expect(ban.isPermanent, isTrue);
      });
    });
  });
}
