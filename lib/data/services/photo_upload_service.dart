import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

import '../api/api_client.dart';

/// Max dimension for uploaded images; larger images are scaled down.
const int _kMaxImageDimension = 1200;

/// JPEG quality for compressed uploads (0–100).
const int _kUploadJpegQuality = 85;

class UploadResult {
  const UploadResult({required this.photoUrl, required this.key});
  final String photoUrl;
  final String key;
}

class PhotoUploadService {
  PhotoUploadService({required this.api});
  final ApiClient api;

  /// Compresses an image file for upload (JPEG, max dimension and quality capped).
  /// Returns compressed bytes, or original file bytes if compression fails.
  Future<List<int>> _compressImage(String localPath) async {
    final file = File(localPath);
    if (!file.existsSync()) {
      debugPrint('[PhotoUpload] File not found: $localPath');
      throw Exception('Photo file not found: $localPath');
    }
    // Use absolute path; compressWithFile can return null on macOS with relative paths.
    final path = file.absolute.path;
    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        path,
        minWidth: _kMaxImageDimension,
        minHeight: _kMaxImageDimension,
        quality: _kUploadJpegQuality,
        format: CompressFormat.jpeg,
      );
      if (compressed != null && compressed.isNotEmpty) {
        debugPrint(
          '[PhotoUpload] Compressed ${file.lengthSync()} → ${compressed.length} bytes',
        );
        return compressed;
      }
      // compressWithFile can return null on macOS; try compressWithList as fallback.
      final bytes = await file.readAsBytes();
      final fromList = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: _kMaxImageDimension,
        minHeight: _kMaxImageDimension,
        quality: _kUploadJpegQuality,
        format: CompressFormat.jpeg,
      );
      if (fromList.isNotEmpty) {
        debugPrint(
          '[PhotoUpload] Compressed (list) ${bytes.length} → ${fromList.length} bytes',
        );
        return fromList;
      }
      debugPrint(
        '[PhotoUpload] Compression returned empty, using original file',
      );
    } catch (e) {
      debugPrint('[PhotoUpload] Compression failed, using original: $e');
    }
    return await file.readAsBytes();
  }

  /// Upload a local image file to S3 via presigned URL.
  /// Images are compressed (JPEG, max 1200px, quality 85) before upload.
  /// Returns the CDN URL to store in `photoUrls`.
  Future<UploadResult> uploadPhoto(String localPath) async {
    // Always request JPEG; we compress to JPEG for smaller uploads.
    const contentType = 'image/jpeg';

    debugPrint('[PhotoUpload] Requesting presigned URL for $contentType');
    final response = await api.post(
      '/profile/me/photos/upload-url',
      body: {'contentType': contentType, 'count': 1},
    );

    // Backend may return "urls" or "uploads"
    final list = response['urls'] ?? response['uploads'];
    final uploads = list is List ? list : <dynamic>[];
    if (uploads.isEmpty) throw Exception('No upload URL returned');

    final upload = uploads[0] as Map<String, dynamic>;
    final rawUploadUrl = upload['uploadUrl'] ?? upload['upload_url'];
    final uploadUrl = rawUploadUrl is String ? rawUploadUrl : null;
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw Exception('Missing uploadUrl in response');
    }
    final key = (upload['key'] as String?) ?? '';
    // photoUrl may be omitted; fallback to uploadUrl without query string for display
    final rawPhotoUrl = upload['photoUrl'] ?? upload['photo_url'];
    final photoUrl = rawPhotoUrl is String
        ? rawPhotoUrl
        : uploadUrl.split('?').first;

    final bytes = await _compressImage(localPath);
    debugPrint('[PhotoUpload] Uploading to S3: ${bytes.length} bytes');
    final s3Response = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );

    if (s3Response.statusCode != 200) {
      debugPrint(
        '[PhotoUpload] S3 upload failed: ${s3Response.statusCode} ${s3Response.body}',
      );
      throw Exception('S3 upload failed: ${s3Response.statusCode}');
    }

    // Register photo with backend (POST /profile/me/photos) so profile has the new photo.
    String finalPhotoUrl = photoUrl;
    try {
      final addRes = await api.post('/profile/me/photos', body: {'key': key});
      final fromApi = addRes['photoUrl'] as String?;
      if (fromApi != null && fromApi.isNotEmpty) finalPhotoUrl = fromApi;
    } catch (e) {
      debugPrint('[PhotoUpload] POST /profile/me/photos failed: $e');
      rethrow;
    }

    debugPrint('[PhotoUpload] Upload complete: $finalPhotoUrl');
    return UploadResult(photoUrl: finalPhotoUrl, key: key);
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
