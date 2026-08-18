import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/policy/data/model/policy_content_model.dart';
import 'package:alatarekak/features/policy/domain/entity/policy_content.dart';
import 'package:alatarekak/features/policy/domain/repo/policy_repo.dart';
import 'package:alatarekak/features/policy/presantion/manger/cubit/policy_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'policies_fixture.dart';

/// السياسات لا تعرف حالة خطأ.
///
/// الوثيقة تُعرض دائماً: شاشة إنشاء الحساب تشترط الموافقة عليها، فلو
/// تعذّر تحميلها لتعذّر التسجيل نفسه. ثلاثة مصادر بالترتيب — المخزَّن،
/// ثم الخادم، ثم النسخة المدمجة في التطبيق.

class MockPolicyRepo extends Mock implements PolicyRepo {}

PolicyContent get _server => PolicyContentModel.fromJson(
    Map<String, dynamic>.from(policiesResponseFixture['data'] as Map));

PolicyContent _cachedWith(String consentLabel) => PolicyContentModel.fromJson({
      'settings': {'consent_label': consentLabel},
      'privacy': {
        'sections': [
          {'title': 'نسخة مخزَّنة'}
        ]
      },
    });

void main() {
  late MockPolicyRepo repo;

  setUp(() => repo = MockPolicyRepo());

  group('بلا كاش', () {
    test('يعرض النسخة المدمجة فوراً ثم يستبدلها بردّ الخادم', () async {
      when(() => repo.getCached()).thenReturn(null);
      when(() => repo.getPolicies()).thenAnswer((_) async => right(_server));

      final cubit = PolicyCubit(repo);
      addTearDown(cubit.close);

      final seen = <PolicyState>[];
      cubit.stream.listen(seen.add);
      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(seen, hasLength(2));
      expect((seen.first as PolicyLoaded).fresh, isFalse);
      expect((seen.last as PolicyLoaded).fresh, isTrue);
      expect((seen.last as PolicyLoaded).content.faq, isNotEmpty);
    });

    test('فشل الشبكة: النسخة المدمجة تبقى معروضة بلا خطأ', () async {
      when(() => repo.getCached()).thenReturn(null);
      when(() => repo.getPolicies())
          .thenAnswer((_) async => left(const Filuar(message: 'no network')));

      final cubit = PolicyCubit(repo);
      addTearDown(cubit.close);
      await cubit.load();

      final state = cubit.state as PolicyLoaded;
      expect(state.fresh, isFalse);
      expect(
        state.content.settings.consentLabel,
        PolicyContent.builtIn.settings.consentLabel,
        reason: 'شاشة التسجيل تشترط هذا السطر — لا يصحّ أن يفرغ',
      );
    });
  });

  group('مع كاش', () {
    test('المخزَّن يُعرض قبل أن تردّ الشبكة', () async {
      when(() => repo.getCached()).thenReturn(_cachedWith('موافقة مخزَّنة'));
      when(() => repo.getPolicies()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return right(_server);
      });

      final cubit = PolicyCubit(repo);
      addTearDown(cubit.close);

      final pending = cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect((cubit.state as PolicyLoaded).content.settings.consentLabel,
          'موافقة مخزَّنة');
      expect((cubit.state as PolicyLoaded).fresh, isFalse);

      await pending;
      expect((cubit.state as PolicyLoaded).fresh, isTrue);
    });

    test('فشل الشبكة فوق كاش: يبقى المخزَّن لا المدمج', () async {
      when(() => repo.getCached()).thenReturn(_cachedWith('موافقة مخزَّنة'));
      when(() => repo.getPolicies())
          .thenAnswer((_) async => left(const Filuar(message: 'down')));

      final cubit = PolicyCubit(repo);
      addTearDown(cubit.close);
      await cubit.load();

      final state = cubit.state as PolicyLoaded;
      expect(state.content.settings.consentLabel, 'موافقة مخزَّنة');
      expect(state.fresh, isFalse);
    });
  });

  group('لا طلبات مكرّرة', () {
    test('محتوى وصل من الخادم لا يُعاد طلبه في الشاشة التالية', () async {
      when(() => repo.getCached()).thenReturn(null);
      when(() => repo.getPolicies()).thenAnswer((_) async => right(_server));

      final cubit = PolicyCubit(repo);
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.load();
      await cubit.load();

      verify(() => repo.getPolicies()).called(1);
    });

    test('السحب للتحديث يطلب من جديد', () async {
      when(() => repo.getCached()).thenReturn(null);
      when(() => repo.getPolicies()).thenAnswer((_) async => right(_server));

      final cubit = PolicyCubit(repo);
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.load(force: true);

      verify(() => repo.getPolicies()).called(2);
    });

    test('محتوى لم يصل من الخادم يُعاد طلبه', () async {
      when(() => repo.getCached()).thenReturn(null);
      when(() => repo.getPolicies())
          .thenAnswer((_) async => left(const Filuar(message: 'down')));

      final cubit = PolicyCubit(repo);
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.load();

      verify(() => repo.getPolicies()).called(2);
    });
  });

  group('المحتوى متاح خارج البنّاء', () {
    test('قبل التحميل يعطي النسخة المدمجة لا null', () {
      when(() => repo.getCached()).thenReturn(null);
      final cubit = PolicyCubit(repo);
      addTearDown(cubit.close);

      expect(cubit.content.settings.appName,
          PolicyContent.builtIn.settings.appName);
    });
  });
}
