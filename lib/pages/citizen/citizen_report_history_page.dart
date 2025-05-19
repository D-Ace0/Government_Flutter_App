import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:governmentapp/models/reports.dart';
import 'package:governmentapp/services/auth/auth_service.dart';
import 'package:governmentapp/services/report/report_service.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/widgets/my_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:governmentapp/utils/logger.dart';

class CitizenReportHistoryPage extends StatefulWidget {
  const CitizenReportHistoryPage({super.key});

  @override
  State<CitizenReportHistoryPage> createState() => _CitizenReportHistoryPageState();
}

class _CitizenReportHistoryPageState extends State<CitizenReportHistoryPage> with TickerProviderStateMixin {
  int currentIndex = 3; // Set to 3 for "Report" tab in bottom navigation
  final ReportService _reportService = ReportService();
  final AuthService _authService = AuthService();
  String statusFilter = 'all';
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _listItemController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _listItemController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Start animations
    _fadeController.forward();
    _listItemController.forward();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _listItemController.dispose();
    super.dispose();
  }

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

  Widget _buildStatusFilter(String status, String label, IconData icon, Color color) {
    final isSelected = statusFilter == status;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
        selected: isSelected,
        selectedColor: color,
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? Colors.transparent : color.withAlpha(76),
          ),
        ),
        onSelected: (selected) {
          setState(() {
            statusFilter = selected ? status : 'all';
          });
          HapticFeedback.selectionClick();
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredReports() {
    final userId = _authService.getCurrentUser()!.uid;
    AppLogger.d('Getting reports for user: $userId with status filter: $statusFilter');
    
    if (statusFilter == 'all') {
      return _reportService.getReportsForUser(userId);
    } else {
      return _reportService.getUserReportsByStatus(userId, statusFilter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      drawer: MyDrawer(role: 'citizen'),
      appBar: AppBar(
        title: const Text(
          "My Reports",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Submit New Report',
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pushReplacementNamed(context, '/citizen_report');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Report stats and filter header
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.2),
                end: Offset.zero,
              ).animate(_fadeController),
              child: _buildStatsHeaderCard(),
            ),
          ),
          
          // Filter chips with animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(_fadeController),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildStatusFilter(
                        'all',
                        'All',
                        Icons.list_alt,
                        theme.colorScheme.primary,
                      ),
                      _buildStatusFilter(
                        'pending',
                        'Pending',
                        Icons.hourglass_empty,
                        Colors.orange,
                      ),
                      _buildStatusFilter(
                        'in progress',
                        'In Progress',
                        Icons.engineering,
                        Colors.blue,
                      ),
                      _buildStatusFilter(
                        'resolved',
                        'Resolved',
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                      _buildStatusFilter(
                        'rejected',
                        'Rejected',
                        Icons.cancel_outlined,
                        Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Main content - Report list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredReports(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          "Loading reports...",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  AppLogger.e('Error in StreamBuilder', snapshot.error);
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Error Loading Reports",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Please try again later",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {}); // Refresh the stream
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text("Retry"),
                        ),
                      ],
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }
                
                final reports = snapshot.data!.docs;
                AppLogger.d('Found ${reports.length} reports');
                
                // Sort reports by timestamp
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
                
                return RefreshIndicator(
                  onRefresh: () async {
                    // Just trigger a rebuild to refresh the stream
                    setState(() {});
                    return Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final reportData = reports[index].data() as Map<String, dynamic>;
                      
                      final report = Report.fromMap({
                        'id': reports[index].id,
                        ...reportData,
                      });
                      
                      // Create staggered animation for each list item
                      final itemAnimation = Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _listItemController,
                          curve: Interval(
                            (index / reports.length) * 0.6,
                            min(((index + 1) / reports.length) * 0.6 + 0.4, 1.0),
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                      );
                      
                      return SlideTransition(
                        position: itemAnimation,
                        child: _buildReportCard(report),
                      );
                    },
                  ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.pushReplacementNamed(context, '/citizen_report');
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'New Report',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/assets/images/no_reports.png', 
                height: 160,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.report_problem_outlined,
                  size: 120,
                  color: Colors.grey.withAlpha(128),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'No Reports Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                statusFilter == 'all'
                    ? 'You haven\'t submitted any reports yet.'
                    : 'No reports with ${_getStatusText(statusFilter)} status.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pushReplacementNamed(context, '/citizen_report');
                },
                icon: const Icon(Icons.add),
                label: const Text('Submit New Report'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsHeaderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade500, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(64),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _reportService.getReportsForUser(_authService.getCurrentUser()!.uid),
        builder: (context, snapshot) {
          int total = 0;
          int pending = 0;
          int inProgress = 0;
          int resolved = 0;
          int rejected = 0;

          if (snapshot.hasData) {
            final reports = snapshot.data!.docs;
            total = reports.length;
            
            for (var doc in reports) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] as String;
              
              switch (status.toLowerCase()) {
                case 'pending': pending++; break;
                case 'in progress': inProgress++; break;
                case 'resolved': resolved++; break;
                case 'rejected': rejected++; break;
              }
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.insights, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Report Statistics',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total', total, Icons.list_alt),
                  _buildStatItem('Pending', pending, Icons.hourglass_empty),
                  _buildStatItem('In Progress', inProgress, Icons.engineering),
                  _buildStatItem('Resolved', resolved, Icons.check_circle_outline),
                  _buildStatItem('Rejected', rejected, Icons.cancel_outlined),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(200),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildReportCard(Report report) {
    final statusInfo = _getStatusInfo(report.status);
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusInfo.color.withAlpha(76),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category and date row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(report.category).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCategoryIcon(report.category),
                        size: 14,
                        color: _getCategoryColor(report.category),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        report.category,
                        style: TextStyle(
                          color: _getCategoryColor(report.category),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  dateFormat.format(report.timestamp),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Title and status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusInfo.color.withAlpha(76),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusInfo.icon,
                        size: 14,
                        color: statusInfo.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusInfo.label,
                        style: TextStyle(
                          color: statusInfo.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Location
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.location,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Description preview
            Text(
              report.description.length > 120
                  ? '${report.description.substring(0, 120)}...'
                  : report.description,
              style: TextStyle(
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
            
            // Images
            if (report.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                "Images (${report.imageUrls.length})",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.imageUrls.length,
                  itemBuilder: (context, imgIndex) {
                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            child: Stack(
                              children: [
                                Image.network(
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
                                    AppLogger.e('Error loading image', error);
                                    return Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.error, color: Colors.red, size: 48),
                                          const SizedBox(height: 8),
                                          const Text('Failed to load image'),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black.withAlpha(100),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            report.imageUrls[imgIndex],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / 
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              AppLogger.e('Error loading thumbnail', error);
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
            if (report.status.toLowerCase() == 'pending')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _confirmDelete(context, report);
                  },
                  icon: const Icon(Icons.delete_outlined, color: Colors.red, size: 18),
                  label: const Text('Delete Report', style: TextStyle(color: Colors.red)),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  StatusInfo _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return StatusInfo(
          label: 'Pending',
          color: Colors.orange,
          icon: Icons.hourglass_empty,
        );
      case 'in progress':
        return StatusInfo(
          label: 'In Progress',
          color: Colors.blue,
          icon: Icons.engineering,
        );
      case 'resolved':
        return StatusInfo(
          label: 'Resolved',
          color: Colors.green,
          icon: Icons.check_circle_outline,
        );
      case 'rejected':
        return StatusInfo(
          label: 'Rejected',
          color: Colors.red,
          icon: Icons.cancel_outlined,
        );
      default:
        return StatusInfo(
          label: status,
          color: Colors.grey,
          icon: Icons.help_outline,
        );
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'infrastructure':
        return Icons.build;
      case 'safety':
        return Icons.shield;
      case 'environment':
        return Icons.eco;
      case 'public services':
        return Icons.public;
      default:
        return Icons.category;
    }
  }
  
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'infrastructure':
        return Colors.orange;
      case 'safety':
        return Colors.red;
      case 'environment':
        return Colors.green;
      case 'public services':
        return Colors.blue;
      default:
        return Colors.purple;
    }
  }
  
  String _getStatusText(String status) {
    return _getStatusInfo(status).label;
  }
  
  void _confirmDelete(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleReportAction(report, 'delete');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _handleReportAction(Report report, String action) async {
    try {
      AppLogger.d('Handling report action: $action for report ${report.id}');
      switch (action) {
        case 'delete':
          await _reportService.deleteReport(report.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;
      }
      AppLogger.d('Action completed successfully');
    } catch (e) {
      AppLogger.e('Error handling report action', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to perform action: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class StatusInfo {
  final String label;
  final Color color;
  final IconData icon;
  
  const StatusInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
} 