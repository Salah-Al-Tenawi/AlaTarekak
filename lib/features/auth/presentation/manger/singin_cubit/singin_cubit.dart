import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/core/service/push_token_service.dart';
import 'package:alatarekak/features/auth/domain/usecase/params/sing_up_params.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';
import 'dart:async';
import 'package:alatarekak/core/service/safe_cubit.dart';

part 'singin_state.dart';


class SinginCubit extends SafeCubit<SinginState> {
  String gender = "M";
  String? address;
  final AuthRepoIm authRepoIm;

  // ━━ OTP ━━
  String _currentOtp = '';
  int _secondsLeft = 60;
  Timer? _timer;

  SinginCubit(this.authRepoIm) : super(SinginInitial());

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // OTP Methods
  // ━━━━━━━━━━━━━━━━━━━━━━━━

  void onOtpChanged(String otp) {
    _currentOtp = otp;
    emit(SinginOtpChanged(otp: otp));
  }

  void startOtpTimer() {
    _secondsLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
        emit(const SinginOtpTimerTick(secondsLeft: 0, canResend: true));
      } else {
        _secondsLeft--;
        emit(SinginOtpTimerTick(
          secondsLeft: _secondsLeft,
          canResend: false,
        ));
      }
    });
  }

  Future<void> sendOtpAgain(String email) async {
    emit(SinginResendOtpLoading());
    final response = await authRepoIm.resendOtpSinging(email);
    response.fold(
      (e) => emit(
          SinginResendOtpError(HandelErorrMessage.emailVerification(e.message))),
      (_) => startOtpTimer(),
    );
  }

  Future<void> checkOtp(String email) async {
  if (_currentOtp.length < 6) return;

  emit(SinginLoading());

  final response = await authRepoIm.verifySinginOtp(email, _currentOtp);

  response.fold(
    (e) {
      // نفس الحالة تُبثّ من التسجيل ومن تأكيد الرمز، والشاشتان لا تفرّقان
      // بينهما — فالترجمة هنا حيث تُعرف العملية الفاشلة
      emit(SinginErorre(HandelErorrMessage.emailVerification(e.message)));
    },
    (auth) {
      // تسجيل توكن FCM بعد تأكيد البريد كما يفعل الدخول تماماً.
      //
      // كان يُستدعى من LoginCubit وحده، فمن أنشأ حسابه للتوّ يبقى بلا
      // توكن مسجَّل حتى يُغلق التطبيق ويفتحه — وأول إشعاراته (إنشاء رحلة،
      // قبول حجز) لا يصله دفعاً.
      PushTokenService.instance.registerToken();
      emit(SinginSuccess(authModel: auth));
    },
  );
}

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // باقي الـ methods
  // ━━━━━━━━━━━━━━━━━━━━━━━━

  void emitChangeGender(String gender) {
    this.gender = gender;
    emit(SinginChangeGender(gender: gender));
  }

  void changAddress(String address) {
    this.address = address;
    emit(SinginChangeAddress(address: address));
  }

  Future signIn(
  String firstName,
  String lastName,
  String gender,
  String email,
  String address,
  String password,
  String verifyPassword,
  String phoneNumber,
) async {
  emit(SinginLoading());

  final params = SignUpParams(
    firstName: firstName,
    lastName: lastName,
    gender: gender,
    email: email,
    address: address,
    password: password,
    confirmPassword: verifyPassword,
    phoneNumber: phoneNumber,
  );

  final response = await authRepoIm.signIn(params);

  response.fold(
    (failure) {
      emit(SinginErorre(HandelErorrMessage.singin(failure.message)));
    },
    (succ) {
      emit(SingInGotoVerfiyOtp(email: email));
    },
  );
}

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}