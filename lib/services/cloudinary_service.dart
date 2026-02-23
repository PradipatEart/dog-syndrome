import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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