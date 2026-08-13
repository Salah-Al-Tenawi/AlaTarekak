import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/e_pay/data/model/balance_model.dart';
import 'package:alatarekak/features/e_pay/data/repo/e_pay_repo_im.dart';
import 'package:alatarekak/features/e_pay/presantion/manger/cubit/wallet_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEPayRepo extends Mock implements EPayRepoIm {}

void main() {
  late MockEPayRepo repo;

  setUp(() {
    repo = MockEPayRepo();
  });

  group('WalletCubit — الرصيد (SAF-04: لا عرض رصيد إلا من رد الخادم)', () {
    blocTest<WalletCubit, WalletState>(
      'نجاح جلب الرصيد: Loading ثم Loaded بالقيم',
      build: () {
        when(() => repo.getBalance()).thenAnswer((_) async => right(
            BalanceModel(walletNumber: '0999999999', balance: '150000')));
        return WalletCubit(repo);
      },
      act: (cubit) => cubit.getBalance(),
      expect: () => [
        isA<WalletLoading>(),
        isA<WalletLoaded>()
            .having((s) => s.balance.balance, 'balance', '150000')
            .having((s) => s.balance.walletNumber, 'wallet', '0999999999'),
      ],
    );

    blocTest<WalletCubit, WalletState>(
      '"Wallet not found" ليست خطأً — تعرض شاشة التفعيل WalletNotActivated',
      build: () {
        when(() => repo.getBalance()).thenAnswer(
            (_) async => left(const Filuar(message: 'Wallet not found')));
        return WalletCubit(repo);
      },
      act: (cubit) => cubit.getBalance(),
      expect: () => [isA<WalletLoading>(), isA<WalletNotActivated>()],
    );

    blocTest<WalletCubit, WalletState>(
      'صياغة الخادم الفعلية "No wallet found for this account." تُفهم أيضاً',
      build: () {
        when(() => repo.getBalance()).thenAnswer((_) async =>
            left(const Filuar(message: 'No wallet found for this account.')));
        return WalletCubit(repo);
      },
      act: (cubit) => cubit.getBalance(),
      expect: () => [isA<WalletLoading>(), isA<WalletNotActivated>()],
    );

    blocTest<WalletCubit, WalletState>(
      'خطأ حقيقي (انقطاع خادم): WalletErorr برسالة معرّبة عامة',
      build: () {
        when(() => repo.getBalance()).thenAnswer(
            (_) async => left(const Filuar(message: 'Server error 500')));
        return WalletCubit(repo);
      },
      act: (cubit) => cubit.getBalance(),
      expect: () => [
        isA<WalletLoading>(),
        isA<WalletErorr>().having((s) => s.message, 'message',
            'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً'),
      ],
    );
  });

  group('WalletCubit — التفعيل اليدوي (خطوة واحدة بلا رمز تحقق)', () {
    blocTest<WalletCubit, WalletState>(
      'نجاح التفعيل: يعرض الرصيد مباشرة بعده',
      build: () {
        when(() => repo.createWalletDirect('0912345678'))
            .thenAnswer((_) async => right({'success': true}));
        when(() => repo.getBalance()).thenAnswer((_) async =>
            right(BalanceModel(walletNumber: 'SY-1', balance: '0')));
        return WalletCubit(repo);
      },
      act: (cubit) => cubit.activateWallet('0912345678'),
      expect: () => [
        isA<WalletActivating>(),
        isA<WalletLoading>(),
        isA<WalletLoaded>().having((s) => s.balance.balance, 'balance', '0'),
      ],
      verify: (_) =>
          verify(() => repo.createWalletDirect('0912345678')).called(1),
    );

    blocTest<WalletCubit, WalletState>(
      'محفظة موجودة أصلاً (409): ليست خطأً — يعرض الرصيد',
      build: () {
        when(() => repo.createWalletDirect(any())).thenAnswer((_) async =>
            left(const Filuar(message: 'You already have a wallet.')));
        when(() => repo.getBalance()).thenAnswer((_) async =>
            right(BalanceModel(walletNumber: 'SY-1', balance: '5000')));
        return WalletCubit(repo);
      },
      act: (cubit) => cubit.activateWallet('0912345678'),
      expect: () => [
        isA<WalletActivating>(),
        isA<WalletLoading>(),
        isA<WalletLoaded>().having((s) => s.balance.balance, 'balance', '5000'),
      ],
    );

    blocTest<WalletCubit, WalletState>(
      'الرقم مستخدم في محفظة أخرى (422): يبقى في شاشة التفعيل برسالة معرّبة',
      build: () {
        when(() => repo.createWalletDirect(any())).thenAnswer((_) async => left(
            const Filuar(
                message:
                    'This phone number is already linked to another wallet.')));
        return WalletCubit(repo);
      },
      act: (cubit) => cubit.activateWallet('0912345678'),
      expect: () => [
        isA<WalletActivating>(),
        isA<WalletActivationFailed>().having(
            (s) => s.message, 'message', 'هذا الرقم مستخدم في محفظة أخرى'),
      ],
      verify: (_) => verifyNever(() => repo.getBalance()),
    );

    blocTest<WalletCubit, WalletState>(
      'فشل شبكة أثناء التفعيل: رسالة خاصة بالمحفظة لا الرسالة العامة',
      build: () {
        when(() => repo.createWalletDirect(any())).thenAnswer(
            (_) async => left(const Filuar(message: 'تحقق من اتصال الإنترنت')));
        return WalletCubit(repo);
      },
      act: (cubit) => cubit.activateWallet('0912345678'),
      expect: () => [
        isA<WalletActivating>(),
        isA<WalletActivationFailed>().having((s) => s.message, 'message',
            'تعذر إنشاء المحفظة، حاول مجدداً'),
      ],
    );
  });
}
