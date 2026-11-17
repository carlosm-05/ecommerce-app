import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const <String, String>{},
  });

  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final status = response?.statusCode;
    var message = 'Ocurrió un error inesperado. Intenta nuevamente.';
    final fieldErrors = <String, String>{};

    final data = response?.data;
    if (data is Map) {
      final rawMessage = data['message'] ?? data['error'];
      if (rawMessage is String && rawMessage.trim().isNotEmpty) {
        message = rawMessage;
      }
      final rawFields = data['fieldErrors'];
      if (rawFields is Map) {
        rawFields.forEach((key, value) {
          final text = _stringify(value);
          if (text != null) {
            fieldErrors[key.toString()] = text;
          }
        });
      }
    } else if (data is String && data.trim().isNotEmpty) {
      message = data;
    }

    if (status == null) {
      message = 'No se pudo conectar con el servidor';
    }

    return ApiException(
      message,
      statusCode: status,
      fieldErrors: fieldErrors,
    );
  }

  static String? _stringify(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final text = value.trim();
      return text.isEmpty ? null : text;
    }
    if (value is List) {
      final parts = value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts.join(', ');
    }
    return value.toString();
  }

  @override
  String toString() => message;
}
