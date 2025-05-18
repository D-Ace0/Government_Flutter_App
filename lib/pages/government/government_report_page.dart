import 'package:flutter/material.dart';
import 'package:governmentapp/models/reports.dart';
import 'package:governmentapp/services/report/report_service.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/widgets/my_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update Report Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Citizen Report: ${report.title}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Current Status: ${_getStatusText(report.status)}'),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.location,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Location Map
              Container(
                height: 200,
                width: double.infinity,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(report.latitude, report.longitude),
                    initialZoom: 13.0,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.governmentapp',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(report.latitude, report.longitude),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(),
                    SizedBox(height: 8),
                    Text(
                      'Select New Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    _buildStatusButton(context, report, 'pending'),
                    _buildStatusButton(context, report, 'in progress'),
                    _buildStatusButton(context, report, 'resolved'),
                    _buildStatusButton(context, report, 'rejected'),
                    SizedBox(height: 8),
                    Text(
                      'Status updates will be visible to the citizen who submitted this report.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton(
      BuildContext context, Report report, String status) {
    Color buttonColor = _getStatusColor(status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          minimumSize: Size(double.infinity, 40),
        ),
        onPressed: () async {
          await _reportService.updateReportStatus(report.id, status);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated to $status')),
          );
        },
        child: Text(
          status.toUpperCase(),
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String status, String label, Color color) {
    final isSelected = statusFilter == status;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      onSelected: (selected) {
        setState(() {
          statusFilter = selected ? status : 'all';
        });
      },
    );
  }

  Stream<QuerySnapshot> _getFilteredReports() {
    print('Getting government reports with status filter: $statusFilter');

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
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Citizen Report Management",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text("Filter by status:"),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text(
                        'All',
                        style: TextStyle(
                          color: statusFilter == 'all' ? Colors.white : null,
                          fontWeight:
                              statusFilter == 'all' ? FontWeight.bold : null,
                        ),
                      ),
                      selected: statusFilter == 'all',
                      selectedColor: Colors.purple,
                      onSelected: (selected) {
                        setState(() {
                          statusFilter = 'all';
                        });
                      },
                    ),
                    _buildFilterChip('pending', 'Pending', Colors.orange),
                    _buildFilterChip('in progress', 'In Progress', Colors.blue),
                    _buildFilterChip('resolved', 'Resolved', Colors.green),
                    _buildFilterChip('rejected', 'Rejected', Colors.red),
                  ],
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
                  print('Error in StreamBuilder: ${snapshot.error}');
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
                print('Found ${reports.length} reports');

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
                  padding: EdgeInsets.all(8),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final reportData =
                        reports[index].data() as Map<String, dynamic>;
                    final report = Report.fromMap({
                      'id': reports[index].id,
                      ...reportData,
                    });

                    // Debug image URLs
                    if (report.imageUrls.isNotEmpty) {
                      print(
                          'Report ${report.id} has ${report.imageUrls.length} images: ${report.imageUrls}');
                    }

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and status row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    report.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(report.status),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    _getStatusText(report.status),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),

                            // Reporter and time
                            Row(
                              children: [
                                Icon(Icons.person,
                                    size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  'Reporter ID: ${report.reporterId.substring(0, 8)}...',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                Spacer(),
                                Text(
                                  DateFormat('MMM dd, yyyy - hh:mm a')
                                      .format(report.timestamp),
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),

                            // Location
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    report.location,
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),

                            // Location Map
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FlutterMap(
                                  options: MapOptions(
                                    initialCenter: LatLng(
                                        report.latitude, report.longitude),
                                    initialZoom: 13.0,
                                    interactionOptions: InteractionOptions(
                                      flags: InteractiveFlag.pinchZoom |
                                          InteractiveFlag.drag,
                                    ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.governmentapp',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: LatLng(report.latitude,
                                              report.longitude),
                                          child: Icon(
                                            Icons.location_on,
                                            color: Colors.red,
                                            size: 40,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 16),

                            // Description
                            Text(
                              report.description,
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 16),

                            // Images
                            if (report.imageUrls.isNotEmpty) ...[
                              Text(
                                "Images (${report.imageUrls.length})",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: report.imageUrls.length,
                                  itemBuilder: (context, imgIndex) {
                                    return GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => Dialog(
                                            child: Image.network(
                                              report.imageUrls[imgIndex],
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    value: loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                print(
                                                    'Error loading image: $error');
                                                return Center(
                                                  child: Icon(Icons.error,
                                                      color: Colors.red),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 120,
                                        margin: EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.grey[300]!),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            report.imageUrls[imgIndex],
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              print(
                                                  'Error loading thumbnail: $error');
                                              return Center(
                                                child: Icon(Icons.broken_image,
                                                    color: Colors.grey),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 16),
                            ],

                            // Action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () =>
                                      _showUpdateStatusDialog(context, report),
                                  icon: Icon(Icons.update),
                                  label: Text("Update Status"),
                                ),
                                SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () =>
                                      _confirmDelete(context, report),
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  label: Text("Delete",
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ],
                        ),
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
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
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

  void _confirmDelete(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delete Citizen Report',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                        'Are you sure you want to delete this citizen report?'),
                    SizedBox(height: 8),
                    Text(
                      'Title: ${report.title}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('Status: ${_getStatusText(report.status)}'),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.location,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Location Map
              Container(
                height: 150,
                width: double.infinity,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(report.latitude, report.longitude),
                    initialZoom: 13.0,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.governmentapp',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(report.latitude, report.longitude),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Cancel'),
                        ),
                        SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _reportService.deleteReport(report.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Citizen report deleted')),
                            );
                          },
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: Text('Delete'),
                        ),
                      ],
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
}
