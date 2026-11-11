import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:retrofit/retrofit.dart';

part '../../../../gen/features/settings/data/datasources/models_api.freezed.dart';
part '../../../../gen/features/settings/data/datasources/models_api.g.dart';

/// `GET {baseUrl}/models` — the same shape on OpenAI, Anthropic and most
/// OpenAI-compatible gateways: `{"data": [{"id": "..."}]}`.
@RestApi()
abstract class ModelsApi {
  factory ModelsApi(Dio dio, {String? baseUrl}) = _ModelsApi;

  @GET('models')
  Future<ModelListDto> list({@Query('limit') int? limit});
}

@freezed
abstract class ModelListDto with _$ModelListDto {
  const factory ModelListDto({@Default(<ModelDto>[]) List<ModelDto> data}) =
      _ModelListDto;

  factory ModelListDto.fromJson(Map<String, dynamic> json) =>
      _$ModelListDtoFromJson(json);
}

@freezed
abstract class ModelDto with _$ModelDto {
  const factory ModelDto({required String id}) = _ModelDto;

  factory ModelDto.fromJson(Map<String, dynamic> json) =>
      _$ModelDtoFromJson(json);
}
