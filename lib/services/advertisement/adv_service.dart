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

    final adWithDriveImage = Advertisement(
      id: '', // Will be set after document creation
      advertiserId: advertisement.advertiserId,
      title: advertisement.title,
      description: advertisement.description,
      imageUrl: uploadedImageUrl,
      category: advertisement.category,
      status: 'pending',
    );

    // Add document and get its ID
    final docRef = await _firestore
        .collection('advertisements')
        .add(adWithDriveImage.toMap());

    // Update the document with its ID
    await docRef.update({'id': docRef.id});
  }

  // Update specific fields of an advertisement (advertiser user)
  Future<void> updateAdvertisementFields(
    String id, {
    String? title,
    String? description,
    String? imageUrl,
    String? category,
  }) async {
    Map<String, dynamic> updates = {};

    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (imageUrl != null) {
      // If updating image, we need to handle Google Drive upload
      await _googleDriveService.initialize();
      File file = await downloadImageFromUrl(imageUrl);
      final uploadedImageUrl = await _googleDriveService.uploadImageToDrive(
        file,
        title ?? 'Advertisement Image',
      );
      updates['imageUrl'] = uploadedImageUrl;
    }
    if (category != null) updates['category'] = category;

    if (updates.isNotEmpty) {
      await _firestore.collection('advertisements').doc(id).update({
        ...updates,
        'isApproved': false,
        'status': 'pending',
      });
    }
  }

  Future<void> deleteAdvertisement(String id) async {
    await _firestore.collection('advertisements').doc(id).delete();
  }

  // get approved only advertisements (for everyone)
  Stream<QuerySnapshot> getApprovedAdvertisements() {
    return _firestore
        .collection('advertisements')
        .where('status', isEqualTo: 'approved')
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  // get advertisements (for advertiser user)
  Stream<QuerySnapshot> getAdvertisementsForUser(String advertiserId) {
    return _firestore
        .collection('advertisements')
        .where('advertiserId', isEqualTo: advertiserId)
        .snapshots();
  }

  // get all advertisements (for government user)
  Stream<QuerySnapshot> getPendingAdvertisements() {
    return _firestore
        .collection('advertisements')
        .where('status', isEqualTo: 'pending')
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  // get rejected advertisements (government user)
  Stream<QuerySnapshot> getRejectedAdvertisements() {
    return _firestore
        .collection('advertisements')
        .where('status', isEqualTo: 'rejected')
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  // approve advertisement (government user)
  Future<void> approveAdvertisement(String id) async {
    await _firestore.collection('advertisements').doc(id).update({
      'isApproved': true,
      'status': 'approved',
    });
  }

  // reject advertisement (government user)
  Future<void> rejectAdvertisement(String id) async {
    await _firestore.collection('advertisements').doc(id).update({
      'isApproved': false,
      'status': 'rejected',
    });
  }
}
