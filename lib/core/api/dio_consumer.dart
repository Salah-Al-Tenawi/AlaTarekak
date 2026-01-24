import 'package:dio/dio.dart';
import 'package:alatarekak/core/api/api_consumer.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/api_interceptor.dart';
import 'package:alatarekak/core/errors/excptions.dart';

class DioConSumer extends ApiConSumer {
  late Dio dio;

  DioConSumer() {
    dio = Dio();
    dio.options.baseUrl = ApiEndPoint.baserUrl;

    dio.interceptors.add(ApiInterCeptor());
    dio.interceptors.add(LogInterceptor(
        request: true,
        responseBody: true,
        requestBody: true,
        requestHeader: true,
        responseHeader: true,
        error: true));
  }

  @override
  Future post(
    String path, {
    dynamic data,
    Map<String, dynamic>? header,
    Map<String, dynamic>? queryParameters,
    bool isFomrData = false,
  }) async {
    try {
      final response = await dio.post(
        path,
        data: isFomrData == true ? FormData.fromMap(data) : data,
        queryParameters: queryParameters,
        options: Options(headers: header),
      );

      return response.data;
    } on DioException catch (e) {
      handelDioExcptions(e);
    }
  }

  @override
  Future delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? header,
    Map<String, dynamic>? queryParameters,
    bool isFomrData = false,
  }) async {
    try {
      final response = await dio.delete(path,
          data: isFomrData == true ? FormData.fromMap(data) : data,
          queryParameters: queryParameters,
          options: Options(headers: header));
      return response.data;
    } on DioException catch (e) {
      handelDioExcptions(e);
    }
  }

  @override
  Future get(
    String path, {
    dynamic data,
    Map<String, dynamic>? header,
    Map<String, dynamic>? queryParameters,
    bool isFomrData = false,
  }) async {
    try {
      final response = await dio.get(path,
          data: isFomrData == true ? FormData.fromMap(data) : data,
          queryParameters: queryParameters,
          options: Options(headers: header));
      return response.data;
    } on DioException catch (e) {
      handelDioExcptions(e);
    }
  }

  @override
  Future patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
  bool isFormData = false,
  }) async {
    try {
      final response = await dio.patch(path,
          data: isFormData == true ? FormData.fromMap(data) : data,
          queryParameters: queryParameters,
          options: Options(headers: header));
      return response.data;
    } on DioException catch (e) {
      handelDioExcptions(e);
    }
  }

  @override
  Future put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
    bool isFormData = false,
  }) async {
    try {
      final response = await dio.put(path,
          data: isFormData == true ? FormData.fromMap(data) : data,
          queryParameters: queryParameters,
          options: Options(headers: header));
      return response.data;
    } on DioException catch (e) {
      handelDioExcptions(e);
    }
  }
}
