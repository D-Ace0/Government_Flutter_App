import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

class GoogleDriveService {
  late drive.DriveApi _driveApi;
  final String folderId = '1Dyd7UjGT0jrRWS9nN0o1dj_Mj4zYS0J_';
  // Replace with your actual folder ID

  Future<void> initialize() async {
    try {
      final serviceAccountCredentials = await rootBundle.loadString(
        'lib/assets/credentials.json',
      );
      print('Credentials loaded successfully');

      final accountCredentials = ServiceAccountCredentials.fromJson(
        serviceAccountCredentials,
      );

      final scopes = [drive.DriveApi.driveFileScope];

      final authClient = await clientViaServiceAccount(
        accountCredentials,
        scopes,
      );
      _driveApi = drive.DriveApi(authClient);
    } catch (e) {
      print('Error loading credentials: $e');
    }
  }

  Future<String> uploadImageToDrive(File imageFile, String imageName) async {
    final media = drive.Media(imageFile.openRead(), imageFile.lengthSync());

    final mimeType =
        lookupMimeType(imageFile.path) ?? 'application/octet-stream';

    final driveFile =
        drive.File()
          ..name = imageName
          ..parents = [folderId]
          ..mimeType = mimeType;

    final response = await _driveApi.files.create(
      driveFile,
      uploadMedia: media,
    );

    // Make file public
    await _driveApi.permissions.create(
      drive.Permission()
        ..type = 'anyone'
        ..role = 'reader',
      response.id!,
    );

    // Return public URL
    return 'https://drive.google.com/uc?id=${response.id}';
  }
}
