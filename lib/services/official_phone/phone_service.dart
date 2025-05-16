import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:governmentapp/models/official_phone.dart';

class PhoneService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new official phone number (for government user)
  Future<void> addOfficialPhone(OfficialPhone phone) async {
    final docRef = await _firestore
        .collection('official_phones')
        .add(phone.toMap());
    await docRef.update({'id': docRef.id});
  }

  // Get all official phone numbers (for citizens)
  Stream<QuerySnapshot> getOfficialPhones() {
    return _firestore
        .collection('official_phones')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Update an official phone number (for government user)
  Future<void> updateOfficialPhone(OfficialPhone phone) async {
    await _firestore
        .collection('official_phones')
        .doc(phone.id)
        .update(phone.toMap());
  }

  // Delete an official phone number (for government user)
  Future<void> deleteOfficialPhone(String id) async {
    await _firestore.collection('official_phones').doc(id).delete();
  }
}
