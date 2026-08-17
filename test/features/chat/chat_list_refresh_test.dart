import 'package:alatarekak/features/chat/data/model/conversation_model.dart';
import 'package:alatarekak/features/chat/presentation/manager/conversation_cubit/conversation_cubit.dart';
import 'package:alatarekak/features/chat/presentation/view/chat_list_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockConversationCubit extends MockCubit<ConversationState>
    implements ConversationCubit {}

/// شاشة قائمة المحادثات.
///
/// كان `RefreshIndicator` داخل فرع القائمة **غير الفارغة** وحده، فتُحبَس
/// الشاشة على الفراغ أو الخطأ بلا سبيل لإعادة المحاولة بالسحب. والحالة
/// الابتدائية كانت تُرسم `SizedBox.shrink()` — شاشة بيضاء لا تُطلق تحميلاً
/// ولا تُسحب.

ConversationModel _conv(int id) => ConversationModel.fromJson({
      'id': id,
      'type': 'direct',
      'title': null,
      'other_participant': {'id': 7, 'name': 'أحمد', 'avatar': null},
      'last_message': {
        'content': 'مرحباً',
        'created_at': '2026-08-17T00:18:09+00:00',
      },
      'updated_at': '2026-08-17T00:18:09+00:00',
    });

void main() {
  late MockConversationCubit cubit;

  setUp(() {
    cubit = MockConversationCubit();
    Get.testMode = true;
    when(() => cubit.loadConversations()).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, ConversationState state) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    whenListen(cubit, const Stream<ConversationState>.empty(),
        initialState: state);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: GetMaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: BlocProvider<ConversationCubit>.value(
              value: cubit,
              child: const ChatListScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// سحب للأسفل فوق جسم الشاشة
  Future<void> pullToRefresh(WidgetTester tester) async {
    await tester.fling(
        find.byType(Scaffold), const Offset(0, 320), 1200);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  group('السحب للتحديث متاح في كل الحالات (الخطأ المُصلَح)', () {
    testWidgets('على قائمة فيها محادثات', (tester) async {
      await pump(tester, ConversationLoaded([_conv(1), _conv(2)]));
      expect(find.byType(RefreshIndicator), findsOneWidget);

      await pullToRefresh(tester);
      verify(() => cubit.loadConversations()).called(greaterThan(0));
    });

    testWidgets('على قائمة فارغة', (tester) async {
      await pump(tester, ConversationLoaded(const []));

      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.text('لا توجد محادثات بعد'), findsOneWidget);

      await pullToRefresh(tester);
      verify(() => cubit.loadConversations()).called(greaterThan(0));
    });

    testWidgets('على حالة الخطأ', (tester) async {
      await pump(tester, ConversationError('لا يوجد اتصال بالإنترنت'));

      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);

      await pullToRefresh(tester);
      verify(() => cubit.loadConversations()).called(greaterThan(0));
    });

    testWidgets('حالة غير متوقّعة لا تُنتج شاشة بيضاء صامتة', (tester) async {
      await pump(tester, ConversationStarted(5));

      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
      expect(find.text('لا توجد محادثات بعد'), findsOneWidget);
    });
  });

  group('الحالة الابتدائية تُطلق التحميل بنفسها', () {
    testWidgets('ConversationInitial → مؤشّر تحميل + استدعاء التحميل',
        (tester) async {
      await pump(tester, ConversationInitial());
      await tester.pump();

      verify(() => cubit.loadConversations()).called(1);
    });

    testWidgets('لا تُرسم شاشة بيضاء بلا محتوى', (tester) async {
      await pump(tester, ConversationInitial());
      // العنوان ما زال ظاهراً — الشاشة ليست فارغة تماماً
      expect(find.text('المحادثات'), findsOneWidget);
    });
  });

  group('حالة التحميل', () {
    testWidgets('لا مؤشّر سحب أثناء التحميل الأول', (tester) async {
      await pump(tester, ConversationLoading());
      expect(find.byType(RefreshIndicator), findsNothing);
      verifyNever(() => cubit.loadConversations());
    });
  });
}
