import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';

Dio createPublicWebDio({HttpClientAdapter? adapter}) {
  final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));
  dio.httpClientAdapter =
      adapter ??
      NativeAdapter(createFallbackAdapter: (_, _) => IOHttpClientAdapter());
  return dio;
}

bool isPublicWebUri(Uri uri) {
  if (!['http', 'https'].contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return false;
  }
  if (uri.hasPort && uri.port != 80 && uri.port != 443) return false;
  final host = uri.host.toLowerCase().replaceAll(RegExp(r'^\[|\]$'), '');
  if (host == 'localhost' ||
      host.endsWith('.localhost') ||
      host.endsWith('.local') ||
      host.endsWith('.internal')) {
    return false;
  }
  final address = InternetAddress.tryParse(host);
  return address == null
      ? host.contains('.') &&
            !host.endsWith('.test') &&
            !host.endsWith('.invalid')
      : isPublicWebAddress(address);
}

bool isPublicWebAddress(InternetAddress address) {
  final bytes = address.rawAddress;
  if (bytes.length == 4) {
    final a = bytes[0];
    final b = bytes[1];
    return !(a == 0 ||
        a == 10 ||
        a == 127 ||
        a >= 224 ||
        (a == 100 && b >= 64 && b <= 127) ||
        (a == 169 && b == 254) ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168) ||
        (a == 192 && b == 0) ||
        (a == 198 && (b == 18 || b == 19 || b == 51)) ||
        (a == 203 && b == 0 && bytes[2] == 113));
  }
  // Accept only global-unicast IPv6, excluding documentation and 6to4.
  return bytes[0] & 0xe0 == 0x20 &&
      !(bytes[0] == 0x20 &&
          bytes[1] == 0x01 &&
          bytes[2] == 0x0d &&
          bytes[3] == 0xb8) &&
      !(bytes[0] == 0x20 && bytes[1] == 0x02);
}
