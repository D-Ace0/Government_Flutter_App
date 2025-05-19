import 'package:flutter/material.dart';
import 'package:governmentapp/models/reports.dart';
import 'package:governmentapp/services/report/report_service.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/widgets/my_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:governmentapp/utils/logger.dart';

class GovernmentReportPage extends StatefulWidget {
  const GovernmentReportPage({super.key});

  @override
  State<GovernmentReportPage> createState() => _GovernmentReportPageState();
}

class _GovernmentReportPageState extends State<GovernmentReportPage> {
  int currentIndex = 3; // Set to 3 for "Report" tab in bottom navigation
  final ReportService _reportService = ReportService();
  String statusFilter = 'all';

  void onTap(int index) {
    setState(() {
      currentIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/government_home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/announcements');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/polls');
    } else if (index == 3) {
      // Already on report page - no navigation needed
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/government_message');
    }
  }

  void _showUpdateStatusDialog(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status indicator
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getStatusColor(report.status).withAlpha(26),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getStatusColor(report.status).withAlpha(51),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getStatusIcon(report.status),
                            size: 24,
                            color: _getStatusColor(report.status),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                      'Update Report Status',
                      style: TextStyle(
                                  fontSize: 18,
                        fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(report.status).withAlpha(51),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Current: ${_getStatusText(report.status)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(report.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(26),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.location,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Map preview (smaller)
              Container(
                height: 180,
                margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  ),
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _isValidLocation(report.latitude, report.longitude)
                  ? FlutterMap(
                    key: Key('dialog_map_${report.id}'),
                      options: MapOptions(
                        initialCenter: LatLng(report.latitude, report.longitude),
                      initialZoom: 14.0,
                      interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.governmentapp',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(report.latitude, report.longitude),
                            width: 50,
                            height: 50,
                            child: Column(
                              children: [
                                Container(
                                  height: 30,
                                  width: 30,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(report.status).withAlpha(204),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(51),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                Icons.location_on,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(26),
                                    shape: BoxShape.circle,
                              ),
                            ),
                          ],
                            ),
                        ),
                      ],
                    ),
                    ],
                  )
                  : Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 30,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No valid location data',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ),
                ),
              ),
              
              // Status selection section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select New Status:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatusOption(context, report, 'pending'),
                    const SizedBox(height: 12),
                    _buildStatusOption(context, report, 'in progress'),
                    const SizedBox(height: 12),
                    _buildStatusOption(context, report, 'resolved'),
                    const SizedBox(height: 12),
                    _buildStatusOption(context, report, 'rejected'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withAlpha(77),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber[700],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                      'Status updates will be visible to the citizen who submitted this report.',
                      style: TextStyle(
                        fontSize: 12,
                                color: Colors.amber[900],
                      ),
                            ),
                    ),
                  ],
                ),
              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption(BuildContext context, Report report, String status) {
    final Color statusColor = _getStatusColor(status);
    final IconData statusIcon = _getStatusIcon(status);
    final String statusText = _getStatusText(status);
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          _handleStatusChange(report.id, status);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: statusColor.withAlpha(26),
        highlightColor: statusColor.withAlpha(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: report.status == status
                ? LinearGradient(
                    colors: [
                      statusColor.withAlpha(51),
                      statusColor.withAlpha(26),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: Border.all(
              color: statusColor.withAlpha(report.status == status ? 102 : 77),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor.withAlpha(51),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withAlpha(26),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        if (report.status == status)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(51),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: statusColor.withAlpha(77),
                                width: 1,
                              ),
                            ),
        child: Text(
                              'Current',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusDescription(status),
        style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: statusColor.withAlpha(report.status == status ? 128 : 77),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Waiting to be processed';
      case 'in progress':
        return 'Work has started on this report';
      case 'resolved':
        return 'Issue has been successfully fixed';
      case 'rejected':
        return 'Report was determined invalid or unfeasible';
      default:
        return 'Unknown status';
    }
  }

  Stream<QuerySnapshot> _getFilteredReports() {
    AppLogger.d('Getting government reports with status filter: $statusFilter');
    
    if (statusFilter == 'all') {
      return _reportService.getAllReports();
    } else {
      return _reportService.getReportsByStatus(statusFilter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(role: 'government'),
      appBar: AppBar(
        title: Text(
          "Manage Citizen Reports",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips - Updated to match the app screenshot
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEDF4FB),
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD7E5F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.filter_list,
                        color: Color(0xFF0D3880),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                            "Filter Reports",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D3880),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Filter by status to quickly find relevant reports",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF5A6781),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD7E5F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'ALL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D3880),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Filter chips row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAllReportsFilterChip(context),
                      _buildStatusFilterChip(context, 'pending', 'Pending', const Color(0xFFFFF4E3), const Color(0xFFFFB74D)),
                      _buildStatusFilterChip(context, 'in progress', 'In Progress', const Color(0xFFE3F2FD), const Color(0xFF42A5F5)),
                      _buildStatusFilterChip(context, 'resolved', 'Resolved', const Color(0xFFE8F5E9), const Color(0xFF66BB6A)),
                      _buildStatusFilterChip(context, 'rejected', 'Rejected', const Color(0xFFFFEBEE), const Color(0xFFEF5350)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content - Report list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredReports(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  AppLogger.e('Error in StreamBuilder', snapshot.error);
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 100,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Error loading reports",
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.report_outlined,
                          size: 100,
                          color: Colors.blue[300],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "No citizen reports to display",
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Reports submitted by citizens will appear here",
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final reports = snapshot.data!.docs;
                AppLogger.d('Found ${reports.length} reports');
                
                // Sort reports by timestamp since we're not using orderBy in the query
                reports.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;

                  final aTime = aData['timestamp'] != null
                      ? DateTime.parse(aData['timestamp'])
                      : DateTime.now();
                  final bTime = bData['timestamp'] != null
                      ? DateTime.parse(bData['timestamp'])
                      : DateTime.now();

                  return bTime.compareTo(aTime); // Descending order
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final reportData =
                        reports[index].data() as Map<String, dynamic>;
                    final report = Report.fromMap({
                      'id': reports[index].id,
                      ...reportData,
                    });
                    
                    // Validate coordinates
                    bool hasValidCoordinates = report.latitude != 0.0 && 
                                             report.longitude != 0.0 &&
                                             report.latitude >= -90 && report.latitude <= 90 &&
                                             report.longitude >= -180 && report.longitude <= 180;
                    
                    AppLogger.d('Report ${report.id} map coordinates: Lat=${report.latitude}, Lng=${report.longitude}, Valid=$hasValidCoordinates');
                    
                    // Debug image URLs
                    if (report.imageUrls.isNotEmpty) {
                      AppLogger.d('Report ${report.id} has ${report.imageUrls.length} images: ${report.imageUrls}');
                    }
                    
                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          // Location section
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Location header
                                Row(
                              children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFD7E5F5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: Color(0xFF0D3880),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Location",
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0D3880),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD7E5F5),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        "Map View",
                                  style: TextStyle(
                                          color: Color(0xFF0D3880),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 10,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                                const SizedBox(height: 12),
                                
                                // Map
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                              height: 200,
                              width: double.infinity,
                                    child: Stack(
                                      children: [
                                        FlutterMap(
                                    options: MapOptions(
                                      initialCenter: LatLng(report.latitude, report.longitude),
                                            initialZoom: 14.0,
                                            interactionOptions: const InteractionOptions(
                                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                                      ),
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.governmentapp',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(report.latitude, report.longitude),
                                                  width: 60,
                                                  height: 60,
                                                  child: const Icon(
                                              Icons.location_on,
                                                    color: Colors.orange,
                                              size: 40,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                        Positioned(
                                          top: 12,
                                          left: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withAlpha(10),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on,
                                                  size: 14,
                                                  color: Colors.orange,
                                                ),
                                                const SizedBox(width: 4),
                                                const Text(
                                                  'Incident Location',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                // Action buttons
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showUpdateStatusDialog(context, report),
                                        icon: const Icon(
                                          Icons.update,
                                          color: Colors.white,
                                        ),
                                        label: const Text("Update Status"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2196F3),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: IconButton(
                                        onPressed: () => _showDeleteConfirmation(context, report),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Color(0xFFEF5350),
                                        ),
                                        tooltip: 'Delete Report',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Green status bar (for Resolved status)
                          if (report.status == 'resolved')
                            Container(
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF66BB6A),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(24),
                                  bottomRight: Radius.circular(24),
                                ),
                              ),
                            ),
                          
                          // Report info and description
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Report title with status
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(report.status).withAlpha(26),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getStatusIcon(report.status),
                                        color: _getStatusColor(report.status),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                              Text(
                                            report.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusBackgroundColor(report.status),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _getStatusText(report.status),
                                style: TextStyle(
                                                color: _getStatusColor(report.status),
                                  fontWeight: FontWeight.bold, 
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Metadata section
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                    color: const Color(0xFFF5F7FA),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.person,
                                            size: 16,
                                            color: Color(0xFF0D3880),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Reporter ID: ${report.reporterId.substring(0, 8)}...',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                              color: Color(0xFF5A6781),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: Color(0xFF0D3880),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat('MMM dd, yyyy • h:mm a').format(report.timestamp),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                              color: Color(0xFF5A6781),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Description section
                                const SizedBox(height: 16),
                                Row(
                              children: [
                                    const Icon(
                                      Icons.description,
                                      size: 16,
                                      color: Color(0xFF0D3880),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Description",
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0D3880),
                                      ),
                                ),
                              ],
                            ),
                                const SizedBox(height: 8),
                                Text(
                                  report.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF5A6781),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: MyBottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return const Color(0xFFFFB74D);
      case 'in progress': return const Color(0xFF42A5F5);
      case 'resolved': return const Color(0xFF66BB6A);
      case 'rejected': return const Color(0xFFEF5350);
      default: return Colors.grey;
    }
  }
  
  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return const Color(0xFFFFF4E3);
      case 'in progress': return const Color(0xFFE3F2FD);
      case 'resolved': return const Color(0xFFE8F5E9);
      case 'rejected': return const Color(0xFFFFEBEE);
      default: return Colors.grey[200]!;
    }
  }
  
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
  
  void _handleStatusChange(String reportId, String newStatus) async {
    try {
      AppLogger.d('Changing status of report $reportId to $newStatus');
      await _reportService.updateReportStatus(reportId, newStatus);
      AppLogger.d('Status updated successfully');
    } catch (e) {
      AppLogger.e('Error updating report status', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  void _handleReportAction(Report report, String action) async {
    try {
      AppLogger.d('Handling report action: $action for report ${report.id}');
      switch (action) {
        case 'approve':
          await _reportService.updateReportStatus(report.id, 'approved');
          break;
        case 'reject':
          await _reportService.updateReportStatus(report.id, 'rejected');
          break;
        case 'delete':
          await _reportService.deleteReport(report.id);
          break;
      }
      AppLogger.d('Action completed successfully');
    } catch (e) {
      AppLogger.e('Error handling report action', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to perform action: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _handleReportAction(report, 'delete');
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  bool _isValidLocation(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    if (latitude == 0.0 && longitude == 0.0) return false; // Zero coordinates are likely placeholders
    return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
  }
  
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.hourglass_empty;
      case 'in progress': return Icons.engineering;
      case 'resolved': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      default: return Icons.help_outline;
    }
  }

  Widget _buildAllReportsFilterChip(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D3880),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.grid_view_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'All Reports',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(BuildContext context, String status, String label, Color backgroundColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: backgroundColor,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(40),
          child: InkWell(
            onTap: () {
              setState(() {
                statusFilter = status;
              });
            },
            borderRadius: BorderRadius.circular(40),
            splashColor: textColor.withAlpha(30),
            highlightColor: textColor.withAlpha(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
