import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';

import '../../../core/utils/logger_utils.dart';

class FileUploadService extends GetxService {
  final dio.Dio _dio;
  final String _baseUploadUrl = '/api/upload'; // Configurable base URL

  FileUploadService({dio.Dio? dioClient}) 
    : _dio = dioClient ?? dio.Dio(
        dio.BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )
      );

  // Upload a single file
  Future<String?> uploadFile(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(
          file.path, 
          filename: fileName,
        ),
      });

      LoggerUtils.info('Uploading file: $fileName');

      final response = await _dio.post(
        _baseUploadUrl, 
        data: formData,
        options: dio.Options(
          contentType: 'multipart/form-data',
        ),
      );

      // Assuming the response contains a file identifier or upload token
      final fileId = response.data['fileId'] ?? response.data['token'];
      LoggerUtils.info('File uploaded successfully: $fileId');
      return fileId;
    } on dio.DioException catch (e, stackTrace) {
      LoggerUtils.error('File upload error', e, stackTrace);
      return null;
    } catch (e, stackTrace) {
      LoggerUtils.error('Unexpected file upload error', e, stackTrace);
      return null;
    }
  }

  // Upload multiple files
  Future<List<String>> uploadFiles(List<File> files) async {
    final uploadedFiles = <String>[];

    LoggerUtils.info('Attempting to upload ${files.length} files');

    for (var file in files) {
      final uploadedFile = await uploadFile(file);
      if (uploadedFile != null) {
        uploadedFiles.add(uploadedFile);
      }
    }

    LoggerUtils.info('Successfully uploaded ${uploadedFiles.length} files');
    return uploadedFiles;
  }

  // Get download URL for an uploaded file
  String getDownloadUrl(String fileId) {
    final downloadUrl = '$_baseUploadUrl/download/$fileId';
    LoggerUtils.debug('Generated download URL: $downloadUrl');
    return downloadUrl;
  }

  // Optional: Delete uploaded file
  Future<bool> deleteFile(String fileId) async {
    try {
      LoggerUtils.info('Attempting to delete file: $fileId');
      await _dio.delete('$_baseUploadUrl/$fileId');
      LoggerUtils.info('File deleted successfully: $fileId');
      return true;
    } on dio.DioException catch (e, stackTrace) {
      LoggerUtils.error('File deletion network error', e, stackTrace);
      return false;
    } catch (e, stackTrace) {
      LoggerUtils.error('Unexpected file deletion error', e, stackTrace);
      return false;
    }
  }
}
