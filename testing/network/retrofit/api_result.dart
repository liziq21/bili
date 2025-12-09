import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'package:f_biuli/network/retrofit/api_result.dart';

extension ApiResultCast<T> on ApiResult<T> {
  
  ApiResultOk<T> get asOk => this as ApiResultOk<T>;

  ApiResultError get asError => this as ApiResultError<T>;
}

extension ApiResultX on ApiResult {
  static Future<ApiResult<T>> fromFile<T>({
    required String jsonDir,
    required String fileName,
    required T Function(Map<String, dynamic>) fromJsonT,
  }) async {
    final json = await getJsonData(jsonDir, fileName);
    return ApiResult<T>.fromJson(json, fromJsonT);
  }
}

Future<Map<String, dynamic>> getJsonData(String dirPath, String fileName) async {
  final String fullPath = path.join(
    Directory.current.path,
    dirPath,
    fileName,
  );

  final File jsonFile = File(fullPath);

  try {
    if (!await jsonFile.exists()) {
      throw FileSystemException('File not found', fullPath);
    }

    final String jsonString = await jsonFile.readAsString();
    final Map<String, dynamic> jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    return jsonData;
  } on PathNotFoundException {
    throw Exception('JSON file not found at: $fullPath');
  } on FileSystemException catch (e) {
    throw Exception('Failed to read JSON file at $fullPath: ${e.message}');
  } on FormatException catch (e) {
    throw Exception('Invalid JSON format in file $fullPath: ${e.message}');
  } on TypeError catch (e) {
    throw Exception('JSON root is not a Map<String, dynamic> in file $fullPath: ${e.toString()}');
  } catch (e) {
    throw Exception('An unexpected error occurred while loading JSON from $fullPath: $e');
  }
}