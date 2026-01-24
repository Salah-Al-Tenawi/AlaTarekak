import 'package:dio/dio.dart';

class ApiInterCeptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {

    options.headers['Accept'] = "application/json";

    if (options.path.contains('/v2/directions/driving-car/geojson')) {
      options.headers['Accept'] = "application/geo+json";
    }

    super.onRequest(options, handler);
  }
}
