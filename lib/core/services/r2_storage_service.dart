import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import '../config/app_config.dart';
import '../utils/app_logger.dart';

class R2StorageService {
  late final String _endpoint;
  late final String _accessKey;
  late final String _secretKey;
  late final String _bucket;
  late final String _cdnUrl;
  final AppLogger _logger = AppLogger();
  final Dio _dio = Dio();

  R2StorageService() {
    _endpoint = AppConfig.r2Endpoint;
    _accessKey = AppConfig.r2AccessKey;
    _secretKey = AppConfig.r2SecretKey;
    _bucket = AppConfig.r2Bucket;
    _cdnUrl = AppConfig.r2CdnUrl;

    _logger.i('R2StorageService initialized: bucket=$_bucket, cdn=$_cdnUrl');
  }

  Future<String> uploadFile(
    String key,
    File file, {
    void Function(double)? onProgress,
  }) async {
    try {
      _logger.i('Uploading file to R2: $key');

      final fileBytes = await file.readAsBytes();
      // Encode key segments to ensure spaces and special chars are handled correctly
      // matching S3 canonical URI requirements
      final encodedKey = key.split('/').map(Uri.encodeComponent).join('/');
      final url = '$_endpoint/$_bucket/$encodedKey';

      final headers = _generateHeaders(
        method: 'PUT',
        path: '/$_bucket/$encodedKey',
        contentType: 'audio/mpeg',
        contentLength: fileBytes.length,
      );

      final response = await _dio.put(
        url,
        data: fileBytes,
        options: Options(headers: headers, contentType: 'audio/mpeg'),
        onSendProgress: (sent, total) {
          if (total != -1 && onProgress != null) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Upload failed: ${response.statusCode} ${response.statusMessage} - ${response.data}',
        );
      }

      final publicUrl = getPublicUrl(key);
      _logger.i('File uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      _logger.e('Error uploading file to R2', e);
      rethrow;
    }
  }

  Future<void> deleteFile(String key) async {
    try {
      _logger.i('Deleting file from R2: $key');

      final encodedKey = key.split('/').map(Uri.encodeComponent).join('/');
      final url = '$_endpoint/$_bucket/$encodedKey';
      final headers = _generateHeaders(
        method: 'DELETE',
        path: '/$_bucket/$encodedKey',
      );

      final response = await _dio.delete(
        url,
        options: Options(headers: headers),
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception(
          'Delete failed: ${response.statusCode} ${response.statusMessage}',
        );
      }

      _logger.i('File deleted successfully: $key');
    } catch (e) {
      _logger.e('Error deleting file from R2', e);
      rethrow;
    }
  }

  String getPublicUrl(String key) {
    final encodedKey = key.split('/').map(Uri.encodeComponent).join('/');
    return '$_cdnUrl/$encodedKey';
  }

  Map<String, String> _generateHeaders({
    required String method,
    required String path,
    String? contentType,
    int? contentLength,
  }) {
    final now = DateTime.now().toUtc();
    final dateStamp = _formatDate(now);
    final amzDate = _formatDateTime(now);

    final headers = <String, String>{
      'Host': Uri.parse(_endpoint).host,
      'x-amz-date': amzDate,
      'x-amz-content-sha256': 'UNSIGNED-PAYLOAD',
    };

    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }
    if (contentLength != null) {
      headers['Content-Length'] = contentLength.toString();
    }

    final authorization = _generateAuthHeader(
      method: method,
      path: path,
      headers: headers,
      dateStamp: dateStamp,
      amzDate: amzDate,
    );

    headers['Authorization'] = authorization;
    return headers;
  }

  String _generateAuthHeader({
    required String method,
    required String path,
    required Map<String, String> headers,
    required String dateStamp,
    required String amzDate,
  }) {
    const algorithm = 'AWS4-HMAC-SHA256';
    const region = 'auto';
    const service = 's3';
    final credentialScope = '$dateStamp/$region/$service/aws4_request';

    final canonicalHeaders =
        headers.entries
            .map((e) => '${e.key.toLowerCase()}:${e.value.trim()}')
            .toList()
          ..sort();
    final signedHeaders = headers.keys.map((k) => k.toLowerCase()).toList()
      ..sort();

    final canonicalRequest = [
      method,
      path,
      '', // query string
      canonicalHeaders.join('\n'),
      '',
      signedHeaders.join(';'),
      'UNSIGNED-PAYLOAD',
    ].join('\n');

    final stringToSign = [
      algorithm,
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');

    final signingKey = _getSignatureKey(dateStamp, region, service);
    final signature = Hmac(
      sha256,
      signingKey,
    ).convert(utf8.encode(stringToSign)).toString();

    return '$algorithm Credential=$_accessKey/$credentialScope, '
        'SignedHeaders=${signedHeaders.join(';')}, Signature=$signature';
  }

  List<int> _getSignatureKey(String dateStamp, String region, String service) {
    final kDate = Hmac(
      sha256,
      utf8.encode('AWS4$_secretKey'),
    ).convert(utf8.encode(dateStamp)).bytes;
    final kRegion = Hmac(sha256, kDate).convert(utf8.encode(region)).bytes;
    final kService = Hmac(sha256, kRegion).convert(utf8.encode(service)).bytes;
    final kSigning = Hmac(
      sha256,
      kService,
    ).convert(utf8.encode('aws4_request')).bytes;
    return kSigning;
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}${_pad(dt.month)}${_pad(dt.day)}';
  }

  String _formatDateTime(DateTime dt) {
    return '${_formatDate(dt)}T${_pad(dt.hour)}${_pad(dt.minute)}${_pad(dt.second)}Z';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
