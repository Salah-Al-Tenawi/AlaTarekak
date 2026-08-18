import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/them/them_app.dart';
import 'package:alatarekak/features/policy/data/model/policy_content_model.dart';
import 'package:alatarekak/features/policy/domain/entity/policy_content.dart';
import 'package:alatarekak/features/policy/domain/repo/policy_repo.dart';
import 'package:alatarekak/features/policy/policy.dart';
import 'package:alatarekak/features/policy/presantion/manger/cubit/policy_cubit.dart';
import 'package:alatarekak/features/profiles/presantaion/view/profile_support.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

/// الشاشتان تعرضان ما يكتبه الأدمن لا النصّ المدمج.
///
/// هذا هو جوهر التحويل: السياسة والأسئلة صارتا تُحرَّران من لوحة الأدمن
/// عبر `GET /policies` بعد أن كانتا نصّاً مكتوباً في التطبيق.

class MockPolicyRepo extends Mock implements PolicyRepo {}

const String _adminSection = 'قسم كتبه الأدمن بعد النشر';
const String _adminQuestion = 'سؤال أضافه الأدمن اليوم';

PolicyContent get _adminContent => PolicyContentModel.fromJson({
      'settings': {'app_name': 'عطريقك', 'contact_email': 'admin@example.com'},
      'privacy': {
        'last_updated_label': '18 آب 2026',
        'sections': [
          {'title': _adminSection, 'intro': 'نصّ القسم'}
        ],
      },
      'cancellation': {
        'sections': [
          {'title': 'الإلغاء من اللوحة'}
        ]
      },
      'faq': {
        'groups': [
          {
            'title': 'مجموعة من اللوحة',
            'icon': 'event_seat_outlined',
            'entries': [
              {'question': _adminQuestion, 'answer': 'جواب من اللوحة'}
            ],
          }
        ],
      },
    });

Future<PolicyCubit> _pump(
  WidgetTester tester,
  Widget screen, {
  required Either<Filuar, PolicyContent> response,
  PolicyContent? cached,
}) async {
  final repo = MockPolicyRepo();
  when(() => repo.getCached()).thenReturn(cached);
  when(() => repo.getPolicies()).thenAnswer((_) async => response);

  final cubit = PolicyCubit(repo);
  addTearDown(cubit.close);

  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => GetMaterialApp(
        theme: ThemApp.lightThem,
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: BlocProvider.value(value: cubit, child: screen),
      ),
    ),
  );

  await cubit.load();
  await tester.pumpAndSettle();
  return cubit;
}

void main() {
  tearDown(Get.reset);

  group('شاشة السياسات', () {
    testWidgets('تعرض أقسام الأدمن لا النصّ المدمج', (tester) async {
      await _pump(tester, const Policy(), response: right(_adminContent));

      expect(find.text(_adminSection), findsOneWidget);
      expect(
        find.text(PolicyContent.builtIn.privacy.sections.first.title),
        findsNothing,
        reason: 'ما زالت تعرض النصّ المكتوب في التطبيق',
      );
    });

    testWidgets('تاريخ التحديث من اللوحة', (tester) async {
      await _pump(tester, const Policy(), response: right(_adminContent));

      expect(find.textContaining('18 آب 2026'), findsOneWidget);
    });

    testWidgets('بلا شبكة: تعرض المدمج مع تنبيه أنها نسخة محفوظة',
        (tester) async {
      await _pump(
        tester,
        const Policy(),
        response: left(const Filuar(message: 'no network')),
      );

      expect(
        find.text(PolicyContent.builtIn.privacy.sections.first.title),
        findsOneWidget,
        reason: 'التسجيل يشترط الموافقة — لا يصحّ أن تفرغ الشاشة',
      );
      expect(find.textContaining('نسخة محفوظة'), findsOneWidget);
    });

    testWidgets('مع الشبكة: لا تنبيه', (tester) async {
      await _pump(tester, const Policy(), response: right(_adminContent));

      expect(find.textContaining('نسخة محفوظة'), findsNothing);
    });
  });

  group('الأسئلة الشائعة', () {
    testWidgets('تعرض أسئلة الأدمن لا المدمجة', (tester) async {
      await _pump(tester, const ProfileSupportScreen(),
          response: right(_adminContent));

      expect(find.text(_adminQuestion), findsOneWidget);
      expect(
        find.text(PolicyContent.builtIn.faq.first.entries.first.question),
        findsNothing,
      );
    });

    testWidgets('بلا شبكة: الأسئلة المدمجة تبقى متاحة', (tester) async {
      await _pump(
        tester,
        const ProfileSupportScreen(),
        response: left(const Filuar(message: 'down')),
      );

      expect(
        find.text(PolicyContent.builtIn.faq.first.entries.first.question),
        findsOneWidget,
        reason: 'صفحة مساعدة فارغة بلا شبكة أسوأ من نصّ قديم',
      );
    });
  });
}
