import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:governmentapp/models/reports.dart';
import 'package:governmentapp/services/google_drive/google_drive_service.dart';
import 'package:uuid/uuid.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleDriveService _googleDriveService = GoogleDriveService();
  final _uuid = Uuid();
  
  // Create a new report with images
  Future<String> createReport(Report report, List<File> images) async {
    try {
      // Generate a unique ID for the report
      final String reportId = _uuid.v4();
      
      // Upload images to Google Drive and get URLs
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        try {
          // Initialize GoogleDriveService before uploading
          await _googleDriveService.initialize();
          
          final imageName = 'report_${reportId}_image_$i.jpg';
          final imageUrl = await _googleDriveService.uploadImageToDrive(
            images[i], 
            imageName
          );
          print('Successfully uploaded image $i to Google Drive: $imageUrl');
          imageUrls.add(imageUrl);
        } catch (e) {
          print('Error uploading image $i to Google Drive: $e');
          // Continue with the next image even if this one fails
        }
      }
      
      // Create the report with image URLs
      final reportWithId = Report(
        id: reportId,
        title: report.title,
        description: report.description,
        status: 'pending', // Default status for new reports
        location: report.location,
        reporterId: report.reporterId,
        imageUrls: imageUrls,
        latitude: report.latitude,
        longitude: report.longitude,
      );
      
      // Save report to Firestore
      await _firestore.collection('reports').doc(reportId).set(
        reportWithId.toMap(),
      );
      
      print('Report created successfully with ID: $reportId');
      print('Report contains ${imageUrls.length} images: $imageUrls');
      
      return reportId;
    } catch (e) {
      print('Error creating report: $e');
      rethrow;
    }
  }
  
  // Get all reports - simplified query to avoid index issues
  Stream<QuerySnapshot> getAllReports() {
    return _firestore.collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  
  // Get reports for a specific user - simplified query to avoid index issues
  Stream<QuerySnapshot> getReportsForUser(String userId) {
    return _firestore.collection('reports')
        .where('reporterId', isEqualTo: userId)
        .snapshots();
  }
  
  // Get reports by status - simplified query to avoid index issues
  Stream<QuerySnapshot> getReportsByStatus(String status) {
    return _firestore.collection('reports')
        .where('status', isEqualTo: status)
        .snapshots();
  }
  
  // Get user reports by status - simplified query to avoid index issues
  Stream<QuerySnapshot> getUserReportsByStatus(String userId, String status) {
    return _firestore.collection('reports')
        .where('reporterId', isEqualTo: userId)
        .where('status', isEqualTo: status)
        .snapshots();
  }
  
  // Update report status
  Future<void> updateReportStatus(String reportId, String newStatus) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': newStatus,
      });
      print('Report status updated to $newStatus for report $reportId');
    } catch (e) {
      print('Error updating report status: $e');
      rethrow;
    }
  }
  
  // Delete a report
  Future<void> deleteReport(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).delete();
      print('Report deleted: $reportId');
      // Note: This doesn't delete the images from Google Drive
      // You would need additional code to clean up those files if desired
    } catch (e) {
      print('Error deleting report: $e');
      rethrow;
    }
  }
} 