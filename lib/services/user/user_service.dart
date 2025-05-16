import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('Users').doc(user.uid).get();
    return doc.data()?['role'];
  }

  String? getCurrentUid() {
    return _auth.currentUser?.uid;
  }

  String? getCurrentEmail() {
    return _auth.currentUser?.email;
  }
}
