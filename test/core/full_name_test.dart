import 'package:alatarekak/core/utils/functions/input_valid.dart';
import 'package:flutter_test/flutter_test.dart';

/// تعديل الاسم في «تعديل المعلومات الشخصية».
///
/// الخادم يخزّن `first_name` و`last_name` حقلين ويعيدهما مجموعين في
/// `full_name`. والشاشة تعرض حقلاً واحداً — كما يراه المستخدم في ملفه —
/// فالفصل يقع عند الحفظ.

void main() {
  group('تقسيم الاسم', () {
    test('اسمان: الأول والعائلة', () {
      final n = splitFullName('يزن صلاح');
      expect(n.first, 'يزن');
      expect(n.last, 'صلاح');
    });

    test('ثلاثة أسماء: الأول واحد والباقي عائلة', () {
      final n = splitFullName('محمد علي الحسن');
      expect(n.first, 'محمد');
      expect(n.last, 'علي الحسن',
          reason: 'اسم العائلة قد يكون مركّباً، والأول لا يكون كذلك');
    });

    test('مسافات زائدة تُطوى', () {
      final n = splitFullName('  أحمد   العظمة  ');
      expect(n.first, 'أحمد');
      expect(n.last, 'العظمة');
    });

    test('كلمة واحدة: لا عائلة', () {
      final n = splitFullName('أحمد');
      expect(n.first, 'أحمد');
      expect(n.last, '');
    });

    test('فارغ لا يرمي', () {
      final n = splitFullName('   ');
      expect(n.first, '');
      expect(n.last, '');
    });
  });

  group('التحقّق', () {
    test('اسم صحيح يمرّ', () {
      expect(validateFullName('يزن صلاح'), isNull);
      expect(validateFullName('محمد علي الحسن'), isNull);
    });

    test('الفارغ يُرفض', () {
      expect(validateFullName('   '), 'الاسم مطلوب');
    });

    test('كلمة واحدة تُرفض — الخادم يطلب حقلين', () {
      expect(validateFullName('أحمد'), 'أدخل الاسم الأول واسم العائلة');
    });

    test('جزء من حرف واحد يُرفض', () {
      expect(validateFullName('أ محمد'), isNotNull);
      expect(validateFullName('محمد ع'), isNotNull);
    });

    test('الأرقام تُرفض', () {
      expect(validateFullName('يزن 2صلاح'), 'الاسم لا يحتوي أرقاماً');
    });

    test('الطويل جداً يُرفض', () {
      expect(validateFullName('${'ا' * 25} ${'ب' * 20}'), 'الاسم طويل جداً');
    });

    test('ما يمرّ التحقّق يُقسَم إلى جزأين غير فارغين', () {
      for (final name in ['يزن صلاح', 'محمد علي الحسن', 'سارة الأحمد']) {
        expect(validateFullName(name), isNull);
        final parts = splitFullName(name);
        expect(parts.first, isNotEmpty);
        expect(parts.last, isNotEmpty);
      }
    });
  });
}
