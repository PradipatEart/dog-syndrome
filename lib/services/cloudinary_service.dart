import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {

  final cloudinary = CloudinaryPublic('devu1xptz', 'photo_upload', cache: false);

  Future<String?> uploadImage(String filePath) async {
    try{
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(filePath, resourceType: CloudinaryResourceType.Image)
      );
      return response.secureUrl;
    }catch (e) {
      return null;
    }

  }

}