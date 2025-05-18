import 'package:flutter/material.dart';
import 'package:governmentapp/models/reports.dart';
import 'package:governmentapp/services/auth/auth_service.dart';
import 'package:governmentapp/services/report/report_service.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/widgets/my_drawer.dart';
import 'package:governmentapp/widgets/report_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CitizenReportHistoryPage extends StatefulWidget {
  const CitizenReportHistoryPage({super.key});

  @override
  State<CitizenReportHistoryPage> createState() => _CitizenReportHistoryPageState();
}

class _CitizenReportHistoryPageState extends State<CitizenReportHistoryPage> {
  int currentIndex = 3; // Set to 3 for "Report" tab in bottom navigation
  final ReportService _reportService = ReportService();
  final AuthService _authService = AuthService();
  String statusFilter = 'all';

  void onTap(int index) {
    setState(() {
      currentIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/citizen_home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/citizen_announcements');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/citizen_polls');
    } else if (index == 3) {
      // Already in the reports section, but we need to decide which page to show
      Navigator.pushReplacementNamed(context, '/citizen_report');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/citizen_messages');
    }
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
    final userId = _authService.getCurrentUser()!.uid;
    print('Getting reports for user: $userId with status filter: $statusFilter');
    
    if (statusFilter == 'all') {
      return _reportService.getReportsForUser(userId);
    } else {
      return _reportService.getUserReportsByStatus(userId, statusFilter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(role: 'citizen'),
      appBar: AppBar(
        title: Text(
          "My Reports",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Add New Report',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/citizen_report');
            },
          ),
        ],
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
                  "My Report History",
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
                          fontWeight: statusFilter == 'all' ? FontWeight.bold : null,
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
                          "No reports to display",
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            "You haven't submitted any reports yet.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
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
                    final reportData = reports[index].data() as Map<String, dynamic>;
                    print('Report data for index $index: $reportData');
                    
                    final report = Report.fromMap({
                      'id': reports[index].id,
                      ...reportData,
                    });
                    
                    // Debug image URLs
                    if (report.imageUrls.isNotEmpty) {
                      print('Report ${report.id} has ${report.imageUrls.length} images: ${report.imageUrls}');
                    }
                    
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
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
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(report.status),
                                    borderRadius: BorderRadius.circular(12),
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
                            SizedBox(height: 8),
                            
                            // Location and time
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
                                Text(
                                  DateFormat('MMM dd, yyyy').format(report.timestamp),
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            
                            // Description
                            Text(report.description),
                            SizedBox(height: 12),
                            
                            // Images
                            if (report.imageUrls.isNotEmpty) ...[
                              Text(
                                "Images (${report.imageUrls.length})",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              SizedBox(
                                height: 100,
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
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded / 
                                                            loadingProgress.expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) {
                                                print('Error loading image: $error');
                                                return Center(
                                                  child: Icon(Icons.error, color: Colors.red),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 100,
                                        margin: EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            report.imageUrls[imgIndex],
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded / 
                                                          loadingProgress.expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              print('Error loading thumbnail: $error');
                                              return Center(
                                                child: Icon(Icons.broken_image, color: Colors.grey),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            
                            // Actions
                            if (report.status == 'pending')
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _confirmDelete(context, report),
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  label: Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
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
      case 'pending': return Colors.orange;
      case 'in progress': return Colors.blue;
      case 'resolved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }
  
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Pending';
      case 'in progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'rejected': return 'Rejected';
      default: return status;
    }
  }
  
  void _confirmDelete(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Report'),
        content: Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reportService.deleteReport(report.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Report deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
} 