import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:developer' as developer;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:mime/mime.dart';

class GoogleDriveService {
  late drive.DriveApi _driveApi;
  final String folderId = '1Dyd7UjGT0jrRWS9nN0o1dj_Mj4zYS0J_';
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      developer.log('GoogleDriveService already initialized, skipping');
      return;
    }
    
    try {
      developer.log('Starting GoogleDriveService initialization');
      
      // Try to load from both possible locations
      String serviceAccountCredentials;
      try {
        serviceAccountCredentials = await rootBundle.loadString(
          'lib/assets/credentials.json',
        );
        developer.log('Credentials loaded from lib/assets/credentials.json');
      } catch (e) {
        developer.log('Failed to load from lib/assets/credentials.json: $e');
        try {
          serviceAccountCredentials = await rootBundle.loadString(
            'assets/credentials.json',
          );
          developer.log('Credentials loaded from assets/credentials.json');
        } catch (e2) {
          developer.log('Failed to load from assets/credentials.json: $e2');
          throw Exception('Could not load credentials.json from any location');
        }
      }
      
      developer.log('Credentials content length: ${serviceAccountCredentials.length}');
      
      final accountCredentials = ServiceAccountCredentials.fromJson(
        serviceAccountCredentials,
      );
      developer.log('ServiceAccountCredentials created');

      final scopes = [drive.DriveApi.driveFileScope];
      developer.log('Requesting authorization with scopes: $scopes');

      final authClient = await clientViaServiceAccount(
        accountCredentials,
        scopes,
      );
      developer.log('Got authClient, creating DriveApi');
      
      _driveApi = drive.DriveApi(authClient);
      _isInitialized = true;
      developer.log('GoogleDriveService initialization completed successfully');
    } catch (e, stackTrace) {
      developer.log('Error initializing GoogleDriveService: $e', error: e, stackTrace: stackTrace);
      _isInitialized = false;
      rethrow;
    }
  }

  Future<String> uploadImageToDrive(File imageFile, String imageName) async {
    if (!_isInitialized) {
      developer.log('DriveApi not initialized, initializing first');
      await initialize();
    }
    
    try {
      developer.log('Starting image upload: $imageName');
      developer.log('Image file exists: ${imageFile.existsSync()}, size: ${imageFile.lengthSync()} bytes');
      
      final media = drive.Media(imageFile.openRead(), imageFile.lengthSync());
      developer.log('Media created');

      final mimeType = lookupMimeType(imageFile.path) ?? 'application/octet-stream';
      developer.log('Detected mime type: $mimeType');

      final driveFile = drive.File()
        ..name = imageName
        ..parents = [folderId]
        ..mimeType = mimeType;
      developer.log('Drive file object created with parent folder: $folderId');

      developer.log('Starting file upload to Drive');
      final response = await _driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );
      developer.log('File uploaded successfully with ID: ${response.id}');

      // Make file public
      developer.log('Setting public permissions');
      await _driveApi.permissions.create(
        drive.Permission()
          ..type = 'anyone'
          ..role = 'reader',
        response.id!,
      );
      developer.log('Public permissions set');

      // Return public URL
      final url = 'https://drive.google.com/uc?id=${response.id}';
      developer.log('Generated public URL: $url');
      return url;
    } catch (e, stackTrace) {
      developer.log('Error uploading image: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
