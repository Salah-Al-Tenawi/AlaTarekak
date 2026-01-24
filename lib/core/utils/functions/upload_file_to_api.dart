import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

Future uploadFiletoApi(XFile? image) async {
  if (image != null) {
    return await MultipartFile.fromFile(image.path,
        filename: image.path.split('/').last);
  }
}
