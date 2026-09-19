import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api_client.dart';

class ImageUploadService {
  Future<String> uploadImage(XFile imageFile) async {
    print('uploadImage called with: ${imageFile.name}');

    final bytes = await imageFile.readAsBytes();
    final fileName = imageFile.name;

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    try {
      print('Uploading to: ${ApiClient.dio.options.baseUrl}/images/upload');
      final response = await ApiClient.dio.post(
        '/images/upload',
        data: formData,
        options: Options(responseType: ResponseType.plain),
      );
      print('Upload succeeded: ${response.data}');
      return response.data.toString();
    } on DioException catch (e) {
      print('Upload failed — type: ${e.type}');
      print('Upload failed — message: ${e.message}');
      print('Upload failed — response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Non-Dio error: $e');
      rethrow;
    }
  }
}