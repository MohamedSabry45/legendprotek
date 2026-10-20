import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:reservation_workshop/constants/app_constants.dart';
import 'package:reservation_workshop/core/network/api_endpoints.dart';

import '../models/job_order_details_response_model.dart';
import '../models/job_order_status_model.dart';

class JobOrderDetailsRemoteDataSource {
  final http.Client _client;

  JobOrderDetailsRemoteDataSource({http.Client? client})
    : _client = client ?? http.Client();

  Future<JobOrderDetailsResponseModel> getJobOrderDetails({
    required int jobOrderId,
    required String phoneLast4,
  }) async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final uri = Uri.parse('$baseUrl${ApiEndpoints.checkPhoneJobOrder}').replace(
      queryParameters: <String, String>{
        'id': jobOrderId.toString(),
        'phone': phoneLast4.trim(),
      },
    );

    final res = await _client.get(uri);
    final decoded = _decodeJson(res.body);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }
    final ok = decoded['success'] != null;
    if (!ok) {
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }

    return JobOrderDetailsResponseModel.fromJson(decoded);
  }

  Future<String> saveProduct({
    required int jobOrderId,
    required List<int> productIds,
    String? token,
  }) async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final encodedPairs = <String>[
      'job_order_id=${Uri.encodeQueryComponent(jobOrderId.toString())}',
      ...productIds.map(
        (e) => 'product_ids[]=${Uri.encodeQueryComponent(e.toString())}',
      ),
      if (token != null && token.trim().isNotEmpty)
        'token=${Uri.encodeQueryComponent(token.trim())}',
    ];
    final uri = Uri.parse(
      '$baseUrl${ApiEndpoints.saveProduct}?${encodedPairs.join('&')}',
    );

    debugPrint('saveProduct REQUEST -> $uri');
    final res = await _client.get(uri);
    final decoded = _decodeJson(res.body);
    debugPrint('saveProduct RESPONSE -> status: ${res.statusCode}');
    debugPrint('saveProduct RESPONSE -> body: ${res.body}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }

    final error = decoded['error']?.toString();
    if (error != null && error.trim().isNotEmpty) {
      throw Exception(error);
    }
    final warning = decoded['warning']?.toString();
    if (warning != null && warning.trim().isNotEmpty) {
      throw Exception(warning);
    }

    final msg =
        decoded['message']?.toString() ?? decoded['success']?.toString();
    if (msg == null || msg.trim().isEmpty) {
      throw Exception('Request failed');
    }
    return msg;
  }

  Future<List<JobOrderStatusModel>> getStatuses() async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final uri = Uri.parse('$baseUrl${ApiEndpoints.contactStatus}');

    final res = await _client.get(uri);
    final decoded = _decodeJson(res.body);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_extractMessage(decoded) ?? 'Request failed');
    }

    final list = decoded['status'];
    if (list is! List) return const <JobOrderStatusModel>[];

    return list
        .whereType<Map>()
        .map((e) => JobOrderStatusModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Map<String, dynamic> _decodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String? _extractMessage(Map<String, dynamic> decoded) {
    final msg = decoded['message']?.toString();
    if (msg != null && msg.trim().isNotEmpty) return msg;
    final warn = decoded['warning']?.toString();
    if (warn != null && warn.trim().isNotEmpty) return warn;
    return null;
  }
}
