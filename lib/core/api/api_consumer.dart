abstract class ApiConSumer {
  Future<dynamic> get(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Map<String, dynamic> header});
  Future<dynamic> post(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Map<String, dynamic> header});
  Future<dynamic> patch(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Map<String, dynamic> header});
  Future<dynamic> delete(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Map<String, dynamic> header});
  Future<dynamic> put(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Map<String, dynamic> header});
}
