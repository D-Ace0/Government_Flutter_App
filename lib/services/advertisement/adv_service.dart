import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:governmentapp/models/advertisement.dart';

class AdvService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createAdvertisement(Advertisement advertisement) async {
    await _firestore.collection('advertisements').add(advertisement.toMap());
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

  // approve advertisement for a user (admin)
  Future<void> approveAdvertisement(String id) async {
    await _firestore.collection('advertisements').doc(id).update({
      'isApproved': true,
    });
  }
}
