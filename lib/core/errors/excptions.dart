import 'dart:io';

import 'package:dio/dio.dart';
import 'package:alatarekak/core/errors/filuar.dart';

class ServerExpcptions implements Exception {
  final Filuar error;

  ServerExpcptions({required this.error});
}


void handelDioExcptions(DioException e) {
  Filuar parseFiluar(dynamic data, String fallbackMessage) {
    try {
      if (data == null) return Filuar(message: fallbackMessage);
      if (data is Map<String, dynamic>) return Filuar.fromJson(data);
      if (data is String && data.isNotEmpty) return Filuar(message: data);
      
      return Filuar(message: fallbackMessage);
    } catch (_) {
      return Filuar(message: fallbackMessage);
    }
  }

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      throw ServerExpcptions(
          error: const Filuar(message: "استغرق وقت طويل حاول مجدداً"));

    case DioExceptionType.sendTimeout:
      throw ServerExpcptions(
        error: parseFiluar(e.response?.data, "انتهت مهلة الإرسال، حاول مجدداً"),
      );

    case DioExceptionType.receiveTimeout:
      throw ServerExpcptions(
        error: parseFiluar(e.response?.data, "انتهت مهلة الاستلام، حاول مجدداً"),
      );

    case DioExceptionType.badCertificate:
      throw ServerExpcptions(
        error: parseFiluar(e.response?.data, "شهادة أمان غير صالحة"),
      );

    case DioExceptionType.cancel:
      throw ServerExpcptions(error: const Filuar(message: "تم إلغاء الطلب"));

    case DioExceptionType.connectionError:
      if (e.error is SocketException) {
        throw ServerExpcptions(error: const Filuar(message: "تحقق من اتصال الإنترنت"));
      } else {
        throw ServerExpcptions(error: Filuar(message: e.message ?? "خطأ في الاتصال"));
      }

    case DioExceptionType.unknown:
     
      if (e.error is SocketException) {
        throw ServerExpcptions(error: const Filuar(message: "لا يوجد اتصال بالشبكة"));
      }
      if (e.response != null) {
        throw ServerExpcptions(
            error: parseFiluar(e.response?.data, "حدث خطأ غير معروف"));
      }
      
      throw ServerExpcptions(error: Filuar(message: e.message ?? "خطأ غير معروف"));

    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      final fallback = "خطأ في الاستجابة من الخادم (حالة: ${status ?? 'غير معروف'})";

      switch (status) {
        case 302:
        case 400:
        case 401:
        case 402:
        case 403:
        case 404:
        case 405:
        case 409:
        case 422:
        case 500:
        case 502:
        case 520:
          throw ServerExpcptions(error: parseFiluar(e.response?.data, fallback));
        default:
          throw ServerExpcptions(error: parseFiluar(e.response?.data, fallback));
      }
  }
}






// void handelDioExcptions(DioException e) {
//   switch (e.type) {
//     case DioExceptionType.connectionTimeout:
//       throw ServerExpcptions(
//           error: const Filuar(message: "استغرق وقت طويل حاول مجددا "));

//     case DioExceptionType.sendTimeout:
//       throw ServerExpcptions(error: Filuar.fromJson(e.response!.data));

//     case DioExceptionType.receiveTimeout:
//       throw ServerExpcptions(error: Filuar.fromJson(e.response!.data));

//     case DioExceptionType.badCertificate:
//       throw ServerExpcptions(error: Filuar.fromJson(e.response!.data));
//     case DioExceptionType.cancel:
//       throw ServerExpcptions(error: Filuar.fromJson(e.response!.data));
//     case DioExceptionType.connectionError:
//       throw ServerExpcptions(error: Filuar.fromJson(e.response!.data));
//     case DioExceptionType.unknown:
//       throw ServerExpcptions(error: Filuar.fromJson(e.response!.data));
//     case DioExceptionType.badResponse:
//       switch (e.response?.statusCode) {
//         case 302:
//           throw ServerExpcptions(error: Filuar.fromJson(e.response!.data));
//         case 422:
//           throw ServerExpcptions(error: Filuar.fromJson(e.response!.data));
//         case 400:
//           throw ServerExpcptions(error: Filuar.fromJson(e.response!.data));
//         case 401:
//           throw ServerExpcptions(error: Filuar.fromJson(e.response!.data));
//         case 402:
//           throw ServerExpcptions(error: Filuar.fromJson(e.response!.data));
//         case 403:
//           throw ServerExpcptions(error: Filuar.fromJson(e.response!.data));
//         case 404:
//           throw ServerExpcptions(error: Filuar.fromJson(e.response!.data));
//         case 405:
//           throw ServerExpcptions(error: Filuar.fromJson(e.response!.data));

//         case 409:
//           throw ServerExpcptions(error: Filuar.fromJson(e.response!.data));
//         case 500:
//           throw ServerExpcptions(error: Filuar.fromJson(e.response!.data));
//         case 502:
//           throw ServerExpcptions(error: Filuar.fromJson(e.response!.data));
//         case 520:
//           throw ServerExpcptions(error: Filuar.fromJson(e.response!.data));
//       }
//   }
// }
