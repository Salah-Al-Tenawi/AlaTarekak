import 'package:get_it/get_it.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/features/auth/data/data_source/auth_local_data_source.dart';
import 'package:alatarekak/features/auth/data/data_source/auth_remote_data_source.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';
import 'package:alatarekak/features/policy/data/data_source/policy_local_data_source.dart';
import 'package:alatarekak/features/policy/data/data_source/policy_remote_data_source.dart';
import 'package:alatarekak/features/policy/data/repo/policy_repo_im.dart';
import 'package:alatarekak/features/policy/presantion/manger/cubit/policy_cubit.dart';
import 'package:alatarekak/features/trip_me/data/data%20source/trip_me_remote_data_source.dart';
import 'package:alatarekak/features/trip_me/data/repo/trip_me_repo_im.dart';
import 'package:alatarekak/features/trip_me/presantion/manger/cubit/trip_me_cubit.dart';

final getit = GetIt.instance;

void locatorService() {
  getit.registerSingleton<DioConSumer>(DioConSumer());
  getit.registerSingleton<AuthRemoteDataSourceIM>(
      AuthRemoteDataSourceIM(api: getit.get<DioConSumer>()));
  getit.registerSingleton<AuthLocalDataSourceIm>(AuthLocalDataSourceIm());
  getit.registerSingleton<AuthRepoIm>(
    AuthRepoIm(
      authRemoteDataSource: getit.get<AuthRemoteDataSourceIM>(),
      authLocalDataSourceIm: getit.get<AuthLocalDataSourceIm>(),
    ),
  );
  // كيوبت واحد للسياسات في التطبيق كله: المحتوى نفسه يظهر في إنشاء
  // الحساب وفي شاشة السياسات وفي الأسئلة الشائعة، فلا معنى لثلاثة طلبات.
  getit.registerSingleton<PolicyCubit>(
    PolicyCubit(PolicyRepoIm(
      remoteDataSource:
          PolicyRemoteDataSourceIm(api: getit.get<DioConSumer>()),
      localDataSource: PolicyLocalDataSourceIm(),
    )),
  );

  getit.registerSingleton<TripMeCubit>(TripMeCubit(TripMeRepoIm(
      tripMeRemoteDataSource:
          TripMeRemoteDataSource(api: getit.get<DioConSumer>()))));
}
