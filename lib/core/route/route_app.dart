import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get_navigation/get_navigation.dart';

import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/locator_ser.dart';
import 'package:alatarekak/features/auth/data/data_source/auth_local_data_source.dart';
import 'package:alatarekak/features/auth/data/data_source/auth_remote_data_source.dart';
import 'package:alatarekak/features/booking_user_in_trip/data/data_source/booking_user_trip_remote_data.dart';
import 'package:alatarekak/features/booking_user_in_trip/data/repo/booking_users_in_trip_repo_imp.dart';
import 'package:alatarekak/features/booking_user_in_trip/presantion/manger/cubit/booking_user_in_trip_cubit.dart';
import 'package:alatarekak/features/booking_user_in_trip/presantion/view/booking_user_in_trip.dart';

// import 'package:alatarekak/features/chat/domain/repo/chat_repo.dart';
// import 'package:alatarekak/features/chat/presentation/manger/conversation_cubit/conversation_cubit.dart';
// import 'package:alatarekak/features/chat/presentation/manger/messages_cubit/message_cubit.dart';
// import 'package:alatarekak/features/chat/presentation/view/page/chat_list_screen.dart';
// import 'package:alatarekak/features/chat/presentation/view/page/chat_screen.dart';
import 'package:alatarekak/features/e_pay/data/data_source/e_pay_remote_data_source.dart';
import 'package:alatarekak/features/e_pay/data/repo/e_pay_repo_im.dart';
import 'package:alatarekak/features/e_pay/presantion/manger/cubit/veriyotp_epy_cubit.dart';
import 'package:alatarekak/features/e_pay/presantion/view/verfiy_otp_epy.dart';
import 'package:alatarekak/features/home/preantion/manger/cubit/home_nav_cubit_cubit.dart';
import 'package:alatarekak/features/maps/data/data_source/maps_data_source.dart';
import 'package:alatarekak/features/maps/data/repo/map_repo.dart';
import 'package:alatarekak/features/maps/presantion/manger/cubit/trip_details_map_cubit.dart';
import 'package:alatarekak/features/maps/presantion/manger/pick_location/cubit/pick_location_cubit.dart';
import 'package:alatarekak/features/maps/presantion/manger/push_ride_map/map_cubit.dart';
import 'package:alatarekak/features/maps/presantion/view/pick_location.dart';
import 'package:alatarekak/features/maps/presantion/view/route_map_view.dart';
import 'package:alatarekak/features/maps/presantion/view/search_ride_map.dart';
import 'package:alatarekak/features/onboarding/ui/manger/cubit/onboarding_cubit.dart';
import 'package:alatarekak/features/onboarding/ui/onboarding.dart';
import 'package:alatarekak/features/policy/policy.dart';
import 'package:alatarekak/features/profiles/data/date_source/profile_remote_date_source.dart';
import 'package:alatarekak/features/splash_view/presentaion/manger/cubit/splash_view_cubit.dart';
import 'package:alatarekak/features/test/my_test.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';
import 'package:alatarekak/features/auth/presentation/manger/forget_password_cubit/forget_password_cubit.dart';
import 'package:alatarekak/features/auth/presentation/manger/login_cubit/login_cubit.dart';
import 'package:alatarekak/features/auth/presentation/manger/singin_cubit/singin_cubit.dart';
import 'package:alatarekak/features/auth/presentation/view/forget_password.dart';
import 'package:alatarekak/features/auth/presentation/view/login.dart';
import 'package:alatarekak/features/auth/presentation/view/singin.dart';
import 'package:alatarekak/features/home/preantion/view/home.dart';
import 'package:alatarekak/features/maps/presantion/view/push_ride_map.dart';
import 'package:alatarekak/features/profiles/data/repo/profile_repo_im.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/my_cars_cubit/my_cars_cubit.dart';
import 'package:alatarekak/features/profiles/presantaion/view/profile.dart';
import 'package:alatarekak/features/profiles/presantaion/view/profile_personal_info.dart';
import 'package:alatarekak/features/profiles/presantaion/view/profile_my_cars.dart';
import 'package:alatarekak/features/profiles/presantaion/view/profile_driver_verification.dart';
import 'package:alatarekak/features/profiles/presantaion/view/profile_settings.dart';
import 'package:alatarekak/features/profiles/presantaion/view/profile_support.dart';
import 'package:alatarekak/features/splash_view/presentaion/view/splash_view.dart';
import 'package:alatarekak/features/trip_booking/data/data%20source/booking_remote_data_source.dart';
import 'package:alatarekak/features/trip_booking/data/repo/booking_me_repo.dart';
import 'package:alatarekak/features/trip_booking/presantion/manger/cubit/booking_me_cubit.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/booking_me_list.dart';
import 'package:alatarekak/features/trip_create/data/data_source/trip_create_remote_data_source.dart';
import 'package:alatarekak/features/trip_create/data/repo/trip_create_repo_im.dart';
import 'package:alatarekak/features/trip_create/presantion/manger/cubit/push_ride_cubit.dart';
import 'package:alatarekak/features/trip_create/presantion/view/trip_add_number_phone.dart';
import 'package:alatarekak/features/trip_create/presantion/view/trip_select_date_and_seats.dart';
import 'package:alatarekak/features/trip_create/presantion/view/trip_select_price_and_booking_type.dart';
import 'package:alatarekak/features/trip_create/presantion/view/trip_select_source_and_dist_on_map.dart';
import 'package:alatarekak/features/trip_create/presantion/view/trip_did_you_back.dart';
import 'package:alatarekak/features/trip_details/data/data_source/trip_details_remote_data_source.dart';
import 'package:alatarekak/features/trip_details/data/repo/trip_details_repo.dart';
import 'package:alatarekak/features/trip_details/presantaion/manger/cubit/tripdetails_cubit.dart';
import 'package:alatarekak/features/trip_details/presantaion/view/trip_details.dart';
import 'package:alatarekak/features/trip_me/data/data%20source/trip_me_remote_data_source.dart';
import 'package:alatarekak/features/trip_me/data/repo/trip_me_repo_im.dart';
import 'package:alatarekak/features/trip_me/presantion/manger/cubit/trip_me_cubit.dart';
import 'package:alatarekak/features/trip_me/presantion/view/trip_me_list.dart';

import 'package:alatarekak/features/trip_search/data/data%20source/search_remote_data_source.dart';
import 'package:alatarekak/features/trip_search/data/repo/search_repo_im.dart';
import 'package:alatarekak/features/trip_search/presantion/manger/cubit/search_cubit.dart';
import 'package:alatarekak/features/trip_search/presantion/manger/cubit/tripsearch_list_cubit.dart';
import 'package:alatarekak/features/trip_search/presantion/view/trip_search.dart';
import 'package:alatarekak/features/trip_search/presantion/view/trip_search_list.dart';
import 'package:alatarekak/features/vieryfiy_user/data/data_source/verifit_user_remote_data_source.dart';
import 'package:alatarekak/features/vieryfiy_user/data/repo/verfiy_user_repo.dart';
import 'package:alatarekak/features/vieryfiy_user/presintion/manger/cubit/verfiy_user_cubit.dart';
import 'package:alatarekak/features/vieryfiy_user/presintion/view/verfiy_user.dart';

List<GetPage<dynamic>> appRoute = [
  GetPage(
    name: RouteName.splashView,
    page: () => BlocProvider(
      create: (context) => SplashCubit(getit.get<AuthRepoIm>()),
      child: const SplashScreen(),
    ),
  ),

  GetPage(
    name: RouteName.onboarding,
    page: () => BlocProvider(
      create: (context) => OnboardingCubit(),
      child: OnboardingScreen(),
    ),
  ),
  GetPage(
      name: RouteName.pickLocation,
      page: () => BlocProvider(
          create: (context) => PickLocationCubit(MapRepoIm(
              mapsDataSource: MapsDataSourceIm(api: getit.get<DioConSumer>()))),
          child: const PickLocation())),

  GetPage(name: RouteName.test, page: () => const MyTest()),
  GetPage(
    name: RouteName.login,
    page: () => BlocProvider(
      create: (context) => LoginCubit(getit.get<AuthRepoIm>()),
      child: const Login(),
    ),
  ),
  GetPage(
      name: RouteName.singin,
      page: () => BlocProvider(
            create: (context) => SinginCubit(getit.get<AuthRepoIm>()),
            child: const Singin(),
          )),
  GetPage(
    name: RouteName.forgetpassword,
    page: () => BlocProvider(
      create: (context) => ForgetPasswordCubit(getit.get<AuthRepoIm>()),
      child: const ForgetPassword(),
    ),
  ),
// GetPage(
//     name: RouteName.verfiyEmailSingin,
//     page: () => BlocProvider(
//       create: (context) => SinginCubit(getit.get<AuthRepoIm>()),
//       child: const VerfiyEmailSingin(),
//     ),
//   ),

  // proile
  GetPage(
      name: RouteName.profile,
      page: () => BlocProvider(
            create: (context) => ProfileCubit(ProfileRepoIm(
                profileRemoteDateSourceIm:
                    ProfileRemoteDateSourceIm(api: getit.get<DioConSumer>()))),
            child: const Profile(),
          )),

// verfiy user
  GetPage(
    name: RouteName.verfiyUser,
    page: () => BlocProvider(
      create: (context) => VerifyUserCubit(
          verfiYUserRepo: VerfiYUserRepo(
              verifitUserRemoteDataSource:
                  VerifitUserRemoteDataSource(api: getit.get<DioConSumer>()))),
      child: const VerfiyUser(),
    ),
  ),
  // map
  GetPage(
    name: RouteName.pushRideMap,
    page: () => BlocProvider(
      create: (_) => MapCubit(),
      child: const PushRideMap(),
    ),
  ),

  GetPage(
    name: RouteName.routeMapView,
    page: () => BlocProvider(
      create: (context) => TripDetailsMapCubit(MapRepoIm(
          mapsDataSource: MapsDataSourceIm(api: getit.get<DioConSumer>()))),
      child: const RouteMapView(),
    ),
  ),

  GetPage(
    name: RouteName.searchRideMap,
    page: () => BlocProvider(
      create: (_) => MapCubit(),
      child: const SearchRideMap(),
    ),
  ),
  // trips create
  // Todo add bloc provider
  GetPage(
      name: RouteName.tripSelectSourceAndDistOnMap,
      page: () => const TripSelectSourceAndDistOnMap()),

  GetPage(
      name: RouteName.tripSelectDateAndSeats,
      page: () => const TripSelectDateAndSeats()),

  GetPage(
      name: RouteName.tripSelectPriceAndBookingType,
      page: () => const TripSelectPriceAndBookingType()),

  GetPage(
    name: RouteName.tripAddNumberPhone,
    page: () => BlocProvider(
      create: (context) => PushRideCubit(
        TripCreateRepoIm(
          tripCreateRemoteDataSource: TripCreateRemoteDataSource(
            api: getit.get<DioConSumer>(),
          ),
        ),
      ),
      child: const TripAddNumberPhone(),
    ),
  ),

  GetPage(name: RouteName.tripDidYouBack, page: () => const TripDidYouBack()),
  // trip search

  GetPage(name: RouteName.tripSearch, page: () => const TripSearch()),
  GetPage(
      name: RouteName.tripSearchList,
      page: () => BlocProvider(
            create: (context) => TripsearchListCubit(SearchRepoIm(
                searchRemoteDataSource:
                    SearchRemoteDataSource(api: getit.get<DioConSumer>()))),
            child: const TripSearchList(),
          )),

  // trip me
  GetPage(
    name: RouteName.tripMeList,
    page: () => BlocProvider(
      create: (context) => TripMeCubit(TripMeRepoIm(
          tripMeRemoteDataSource:
              TripMeRemoteDataSource(api: getit.get<DioConSumer>()))),
      child: const TripMeList(),
    ),
  ),

  GetPage(
    name: RouteName.tripDetails,
    page: () => BlocProvider(
      create: (context) => TripDetailsCubit(
          tripDetailsRepoIM: TripDetailsRepoIM(
              remoteDataSource:
                  TripDetailsRemoteDataSource(api: getit.get<DioConSumer>()))),
      child: const TripDetails(),
    ),
  ),
  GetPage(
    name: RouteName.bookingUserInTrip,
    page: () => BlocProvider(
      create: (context) => BookingUserInTripCubit(BookingUsersInTripRepoImp(
          remoteData:
              BookingUserTripRemoteData(api: getit.get<DioConSumer>()))),
      child: const BookingUserINTrip(),
    ),
  ),
  // booking me

  GetPage(
      name: RouteName.bookingMeList,
      page: () => BlocProvider(
            create: (context) => BookingMeCubit(BookingMeRepo(
                remoteDataSource:
                    BookingRemoteDataSource(api: getit.get<DioConSumer>()))),
            child: const BookingMeList(),
          )),
  // home
  GetPage(
    name: RouteName.home,
    page: () => MultiBlocProvider(
      providers: [
        BlocProvider<HomeNavCubit>(
            create: (_) => HomeNavCubit(AuthRepoIm(
                authRemoteDataSource:
                    AuthRemoteDataSourceIM(api: getit.get<DioConSumer>()),
                authLocalDataSourceIm: AuthLocalDataSourceIm()))),
        BlocProvider<SearchCubit>(
          create: (_) => SearchCubit(
            SearchRepoIm(
              searchRemoteDataSource: SearchRemoteDataSource(
                api: getit.get<DioConSumer>(),
              ),
            ),
          ),
        ),
        BlocProvider(
          create: (_) => TripMeCubit(TripMeRepoIm(
              tripMeRemoteDataSource:
                  TripMeRemoteDataSource(api: getit.get<DioConSumer>()))),
        ),
        BlocProvider(
          create: (_) => BookingUserInTripCubit(BookingUsersInTripRepoImp(
              remoteData:
                  BookingUserTripRemoteData(api: getit.get<DioConSumer>()))),
        ),
        BlocProvider(
          create: (_) => ProfileCubit(ProfileRepoIm(
              profileRemoteDateSourceIm:
                  ProfileRemoteDateSourceIm(api: getit.get<DioConSumer>()))),
        ),
      ],
      child: const Home(),
    ),
  ),

  // profile sub-screens
  GetPage(
    name: RouteName.profilePersonalInfo,
    page: () => const ProfilePersonalInfoScreen(),
  ),
  GetPage(
    name: RouteName.profileMyCars,
    page: () => BlocProvider(
      create: (_) => MyCarsScreenCubit(),
      child: const ProfileMyCarsScreen(),
    ),
  ),
  GetPage(
    name: RouteName.profileDriverVerification,
    page: () => const ProfileDriverVerificationScreen(),
  ),
  GetPage(
    name: RouteName.profileSettings,
    page: () => const ProfileSettingsScreen(),
  ),
  GetPage(
    name: RouteName.profileSupport,
    page: () => const ProfileSupportScreen(),
  ),

  // policy
  GetPage(name: RouteName.policy, page: () => const Policy()),

  GetPage(
      name: RouteName.verfiyOtpEpy,
      page: () => BlocProvider(
            create: (context) => VeriyotpEpyCubit(EPayRepoIm(
                remoteDataSource:
                    EPayRemoteDataSource(api: getit.get<DioConSumer>()))),
            child: const VerifyOtpEPay(),
          )),

  // GetPage(
  //   name: RouteName.chatListScreen,
  //   page: () => BlocProvider(
  //     create: (context) => ConversationCubit(getit<ChatRepo>()),
  //     child: ChatListScreen(),
  //   ),
  // ),

  // GetPage(
  //   name: RouteName.chatScreen,
  //   page: () {
  //     final args = Get.arguments as Map<String, dynamic>;

  //     return BlocProvider(
  //       create: (context) => MessageCubit(getit<ChatRepo>()),
  //       child: ChatScreen(
  //         conversationId: args['conversationId'],
  //         sender: args['sender'],
  //       ),
  //     );
  //   },
  // ),
];
