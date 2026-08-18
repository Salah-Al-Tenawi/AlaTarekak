import 'package:equatable/equatable.dart';
import 'package:alatarekak/core/service/safe_cubit.dart';
import 'package:alatarekak/features/policy/domain/entity/policy_content.dart';
import 'package:alatarekak/features/policy/domain/repo/policy_repo.dart';

part 'policy_state.dart';

/// السياسات والأسئلة الشائعة.
///
/// **لا حالة خطأ.** الوثيقة القانونية يجب أن تُعرض دائماً: شاشة إنشاء
/// الحساب تشترط الموافقة عليها، فلو تعذّر تحميلها لتعذّر التسجيل نفسه،
/// و«الأسئلة الشائعة» بلا شبكة تصير صفحة عطل بدل مساعدة. لذلك ثلاثة
/// مصادر بالترتيب:
///
///   1. المخزَّن محلياً — يُعرض فوراً بلا انتظار،
///   2. الخادم — يستبدله حين يصل،
///   3. النسخة المدمجة في التطبيق — حين لا هذا ولا ذاك.
///
/// و[PolicyLoaded.fresh] يميّز ما جاء من الخادم في هذه الجلسة عمّا هو
/// أقدم، فتُظهر الشاشة تنبيهاً هادئاً بدل أن توهم المستخدم أن ما يقرأه
/// هو أحدث نسخة.
class PolicyCubit extends SafeCubit<PolicyState> {
  final PolicyRepo _repo;

  PolicyCubit(this._repo) : super(PolicyInitial());

  /// [force] للسحب اليدوي للتحديث. بدونه لا يتكرّر الطلب ما دام محتوى
  /// هذه الجلسة قد وصل من الخادم — المحتوى واحد في الشاشات الثلاث.
  Future<void> load({bool force = false}) async {
    final current = state;
    if (!force && current is PolicyLoaded && current.fresh) return;

    if (current is! PolicyLoaded) {
      final cached = _repo.getCached();
      emit(PolicyLoaded(
        content: cached ?? PolicyContent.builtIn,
        fresh: false,
      ));
    }

    final result = await _repo.getPolicies();
    result.fold(
      (_) {
        // الشبكة تعذّرت — يبقى المعروض كما هو (مخزَّن أو مدمج) وهو ما
        // نُعلم به المستخدم عبر fresh = false
        final s = state;
        if (s is PolicyLoaded && s.fresh) return;
        emit(PolicyLoaded(
          content: s is PolicyLoaded ? s.content : PolicyContent.builtIn,
          fresh: false,
        ));
      },
      (content) => emit(PolicyLoaded(content: content, fresh: true)),
    );
  }

  /// المحتوى المعروض الآن أياً كان مصدره — لمن يحتاجه خارج البنّاء
  /// (سطر الموافقة في التسجيل مثلاً).
  PolicyContent get content {
    final s = state;
    return s is PolicyLoaded ? s.content : PolicyContent.builtIn;
  }
}
