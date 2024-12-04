import 'package:dio/dio.dart';

class TrailingSlashInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Ensure trailing slash for all requests
    if (!options.path.endsWith('/')) {
      options.path += '/';
    }
    handler.next(options);
  }
}
