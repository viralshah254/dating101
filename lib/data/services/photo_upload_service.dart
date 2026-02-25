import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api/api_client.dart';

class UploadResult {
  const UploadResult({required this.photoUrl, required this.key});
  final String photoUrl;
  final String key;
}

class PhotoUploadService {
  PhotoUploadService({required this.api});
  final ApiClient api;

  /// Upload a local image file to S3 via presigned URL.
  /// Returns the CDN URL to store in `photoUrls`.
  Future<UploadResult> uploadPhoto(String localPath) async {
    final file = File(localPath);
    final ext = localPath.split('.').last.toLowerCase();
    final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';

    debugPrint('[PhotoUpload] Requesting presigned URL for $contentType');
    final response = await api.post('/profile/me/photos/upload-url', body: {
      'contentType': contentType,
      'count': 1,
    });

    final uploads = (response['uploads'] as List);
    if (uploads.isEmpty) throw Exception('No upload URL returned');

    final upload = uploads[0] as Map<String, dynamic>;
    final uploadUrl = upload['uploadUrl'] as String;
    final photoUrl = upload['photoUrl'] as String;
    final key = upload['key'] as String;

    debugPrint('[PhotoUpload] Uploading to S3: ${file.lengthSync()} bytes');
    final bytes = await file.readAsBytes();
    final s3Response = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );

    if (s3Response.statusCode != 200) {
      debugPrint('[PhotoUpload] S3 upload failed: ${s3Response.statusCode} ${s3Response.body}');
      throw Exception('S3 upload failed: ${s3Response.statusCode}');
    }

    debugPrint('[PhotoUpload] Upload complete: $photoUrl');
    return UploadResult(photoUrl: photoUrl, key: key);
  }

  /// Upload multiple local photos, returning CDN URLs for each.
  /// Skips any that are already URLs (http/https).
  Future<List<String>> uploadAll(List<String> paths) async {
    final results = <String>[];
    for (final path in paths) {
      if (path.startsWith('http')) {
        results.add(path);
        continue;
      }
      try {
        final result = await uploadPhoto(path);
        results.add(result.photoUrl);
      } catch (e) {
        debugPrint('[PhotoUpload] Failed to upload $path: $e');
        rethrow;
      }
    }
    return results;
  }

  /// Delete a photo by its S3 key.
  Future<void> deletePhoto(String key) async {
    debugPrint('[PhotoUpload] Deleting photo: $key');
    final encoded = Uri.encodeComponent(key);
    await api.delete('/profile/me/photos/$encoded');
    debugPrint('[PhotoUpload] Delete complete');
  }
}
