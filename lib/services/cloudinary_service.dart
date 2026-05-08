import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = "dnlaaetzs";
  static const String uploadPreset = "hotel_unsigned_preset";

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      final request = http.MultipartRequest("POST", url);

      request.fields["upload_preset"] = uploadPreset;

      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          imageFile.path,
        ),
      );

      final response = await request.send();

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data["secure_url"];
      } else {
        print("Cloudinary upload failed");
        print("Status code: ${response.statusCode}");
        print("Response: $responseBody");
        return null;
      }
    } catch (e) {
      print("Cloudinary error: $e");
      return null;
    }
  }
}