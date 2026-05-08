import 'package:get_it/get_it.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/features/auth/data/data_source/auth_local_data_source.dart';
import 'package:alatarekak/features/auth/data/data_source/auth_remote_data_source.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';
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
  getit.registerSingleton<TripMeCubit>(TripMeCubit(TripMeRepoIm(
      tripMeRemoteDataSource:
          TripMeRemoteDataSource(api: getit.get<DioConSumer>())))); 



//           getit.registerSingleton<ConversationsRemoteDataSource>(
//     ConversationsRemoteDataSourceIM 
// (api: getit.get<DioConSumer>()),
//   );

//   getit.registerSingleton<ChatRepo>(
//     ChatRepoImpl(remoteDataSource: getit.get<ConversationsRemoteDataSource>()),
//   );
}
