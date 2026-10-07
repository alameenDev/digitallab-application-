import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PatientApiException implements Exception {
  const PatientApiException(this.status, this.message);
  final int status;
  final String message;
  @override String toString() => message;
}
class PatientApi {
  PatientApi(String baseUrl, {http.Client? client}) : client = client ?? http.Client() {
    final uri = Uri.tryParse(baseUrl);
    final local = uri != null && ['localhost', '127.0.0.1', '::1'].contains(uri.host);
    if (uri == null || uri.host.isEmpty || uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment ||
        (uri.scheme != 'https' && !(kDebugMode && local && uri.scheme == 'http'))) {
      throw const PatientApiException(0, 'عنوان خدمة الربط غير صالح. يجب استخدام اتصال HTTPS.');
    }
    base = baseUrl.replaceAll(RegExp(r'/+$'), '');
  }
  late final String base;
  final http.Client client;
  Future<Map<String, dynamic>> call(String method, String path, {String? token, Map<String, dynamic>? body}) async {
    final request = http.Request(method, Uri.parse('$base/patient-mobile/v1/$path'))
      ..followRedirects = false
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    try {
      final response = await http.Response.fromStream(await client.send(request).timeout(const Duration(seconds: 20)))
          .timeout(const Duration(seconds: 20));
      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) data = decoded;
      } on FormatException { /* Do not expose server HTML or request secrets. */ }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = switch (response.statusCode) {
          401 => 'انتهى ربط هذا الملف. خذ رمزاً جديداً من بوابة المريض.',
          403 => 'أكمل التحقق المطلوب من بوابة المريض أولاً.',
          404 => 'الملف أو خدمة الربط غير متاحة حالياً.',
          409 => 'التقرير قيد الإجراء ولم يُعتمد للنشر بعد.',
          422 => 'تأكد من رقم الهاتف ورمز الربط وصلاحيته، ثم حاول مجدداً.',
          429 => 'محاولات كثيرة. انتظر قليلاً قبل المحاولة مرة أخرى.',
          _ => 'تعذر الاتصال بخدمة المختبر. حاول لاحقاً.',
        };
        throw PatientApiException(response.statusCode, message);
      }
      if (data.isEmpty) throw const PatientApiException(0, 'وصل رد غير مكتمل من الخدمة.');
      return data;
    } on TimeoutException {
      throw const PatientApiException(0, 'استغرق الاتصال وقتاً طويلاً. تحقق من الإنترنت وأعد المحاولة.');
    } on http.ClientException {
      throw const PatientApiException(0, 'تعذر الاتصال. تحقق من الإنترنت وحاول مجدداً.');
    }
  }
  void close() => client.close();
}
String normalizePatientDigits(String value) {
  const arabic = '٠١٢٣٤٥٦٧٨٩', persian = '۰۱۲۳۴۵۶۷۸۹';
  for (var i = 0; i < 10; i++) {
    value = value.replaceAll(arabic[i], '$i').replaceAll(persian[i], '$i');
  }
  return value;
}
String? normalizePatientPhone(String value) {
  value = normalizePatientDigits(value).replaceAll(RegExp(r'[\s()\-]'), '');
  final match = RegExp(r'^(?:0|964|\+964|00964)(7[3-9]\d{8})$').firstMatch(value);
  return match == null ? null : '964' + match[1]!;
}
String normalizePairingCode(String value) => normalizePatientDigits(value).replaceAll(RegExp(r'\s'), '');
