import 'package:freezed_annotation/freezed_annotation.dart';

part 'http_error.freezed.dart';
part 'http_error.g.dart';

@freezed
abstract class HttpError with _$HttpError {
  const factory HttpError({
    @Default("ERROR") String code,
    required String message,
    required String? stack,
  }) = _HttpError;

  factory HttpError.fromJson(Map<String, dynamic> json) =>
      _$HttpErrorFromJson(json);
}