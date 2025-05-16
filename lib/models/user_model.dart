class UserModel {
  final String uid;
  final String email;
  final String role;

  UserModel({required this.uid, required this.email, required this.role});


  bool get isAdmin => role == 'government';
  bool get isAdvertiser => role == 'advertiser';
  bool get isCitizen => role == 'citizen';
}
