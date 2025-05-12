import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:governmentapp/models/advertisement.dart';
import 'package:governmentapp/services/google_drive/google_drive_service.dart';

class AdvService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleDriveService _googleDriveService = GoogleDriveService();

  // download image from url
  Future<File> downloadImageFromUrl(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode == 200) {
      final documentDirectory = await getTemporaryDirectory();
      final filePath = join(documentDirectory.path, 'temp_ad_image.jpg');
      final file = File(filePath);
      return await file.writeAsBytes(response.bodyBytes);
    } else {
      throw Exception('Failed to download image');
    }
  }

  // upload image to google drive
  Future<void> createAdvertisement(Advertisement advertisement) async {
    await _googleDriveService.initialize();

    // Download the image first
    File file = await downloadImageFromUrl(advertisement.imageUrl);
    final uploadedImageUrl = await _googleDriveService.uploadImageToDrive(
      file,
      advertisement.title,
    );
    print(uploadedImageUrl);

    final adWithDriveImage = Advertisement(
      advertiserId: advertisement.advertiserId,
      title: advertisement.title,
      description: advertisement.description,
      imageUrl: uploadedImageUrl,
      category: advertisement.category,
    );

    await _firestore.collection('advertisements').add(adWithDriveImage.toMap());
  }

  Future<void> updateAdvertisement(
    String id,
    Advertisement advertisement,
  ) async {
    await _firestore
        .collection('advertisements')
        .doc(id)
        .update(advertisement.toMap());
  }

  Future<void> deleteAdvertisement(String id) async {
    await _firestore.collection('advertisements').doc(id).delete();
  }

  Stream<QuerySnapshot> getAdvertisements() {
    return _firestore.collection('advertisements').snapshots();
  }

  // get approved only advertisements
  Stream<QuerySnapshot> getApprovedAdvertisements() {
    return _firestore
        .collection('advertisements')
        .where('isApproved', isEqualTo: true)
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  // get advertisements for a user
  Stream<QuerySnapshot> getAdvertisementsForUser(String advertiserId) {
    return _firestore
        .collection('advertisements')
        .where('advertiserId', isEqualTo: advertiserId)
        .snapshots();
  }

  // approve advertisement for a user (admin)
  Future<void> approveAdvertisement(String id) async {
    await _firestore.collection('advertisements').doc(id).update({
      'isApproved': true,
    });
  }
}
