import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:reservation_workshop/constants/app_constants.dart';
import 'package:reservation_workshop/core/network/api_endpoints.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/menu/data/models/social_media_model.dart';

class SocialMediaRemoteDataSource {
  final http.Client _client;

  SocialMediaRemoteDataSource({http.Client? client})
    : _client = client ?? http.Client();

  Future<List<SocialMediaItemModel>> getSocialMedia({int businessId = 1}) async {
    final baseUrl = AppConstants.kBaseUrl.trim();
    final token = AppConstants.token ??
        CacheHelper.getData<String>(key: PrefKeys.kAccessToken);

    final uri = Uri.parse(
      '$baseUrl${ApiEndpoints.socialMedia(businessId: businessId)}',
    );
    final res = await _client.get(
      uri,
      headers: <String, String>{
        'Accept': 'application/json',
        if (token != null && token.trim().isNotEmpty)
          'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Request failed');
    }

    final decoded = _decodeJson(res.body);
    final data = decoded['data'];
    if (data is! List) return const <SocialMediaItemModel>[];

    return data
        .whereType<Map>()
        .map(
          (e) => SocialMediaItemModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .where((e) => e.link.trim().isNotEmpty)
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
}
