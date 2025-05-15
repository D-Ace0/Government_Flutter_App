import 'package:flutter/material.dart';
import 'package:governmentapp/models/announcement.dart';
import 'package:governmentapp/pages/announcement_detail_page.dart';
import 'package:governmentapp/services/announcement/announcement_service.dart';
import 'package:governmentapp/services/notification/notification_service.dart';
import 'package:governmentapp/services/user/route_guard_wrapper.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/widgets/my_drawer.dart';
import 'package:intl/intl.dart';

class CitizenAnnouncementsPage extends StatefulWidget {
  const CitizenAnnouncementsPage({super.key});

  @override
  State<CitizenAnnouncementsPage> createState() => _CitizenAnnouncementsPageState();
}

class _CitizenAnnouncementsPageState extends State<CitizenAnnouncementsPage> with SingleTickerProviderStateMixin {
  final AnnouncementService _announcementService = AnnouncementService();
  final NotificationService _notificationService = NotificationService();
  List<Announcement> _announcements = [];
  List<Announcement> _filteredAnnouncements = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  DateTime _lastCheckTime = DateTime.now().subtract(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _loadAnnouncements();
    _searchController.addListener(_filterAnnouncements);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final announcements = await _announcementService.getActiveAnnouncements();
      
      // Check for new announcements and show notifications using context
      _notificationService.checkForNewAnnouncements(
        announcements, 
        _lastCheckTime,
        context
      );
      
      // Update last check time to now
      _lastCheckTime = DateTime.now();
      
      if (mounted) {
        setState(() {
          _announcements = announcements
              .where((a) => !a.isDraft && a.isPublished && !a.isExpired)
              .toList();
          _filteredAnnouncements = List.from(_announcements);
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading announcements: $e')),
        );
      }
    }
  }

  void _filterAnnouncements() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAnnouncements = _announcements.where((announcement) {
        final matchesCategory = _selectedCategory == 'All' || announcement.category == _selectedCategory;
        final matchesQuery = announcement.title.toLowerCase().contains(query) ||
            announcement.content.toLowerCase().contains(query);
        return matchesCategory && matchesQuery;
      }).toList();
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterAnnouncements();
  }

  List<String> _getCategories() {
    final categories = _announcements.map((a) => a.category).toSet().toList();
    categories.insert(0, 'All');
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return RouteGuardWrapper(
      allowedRoles: const ['citizen'],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Announcements', 
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                _showFilterDialog();
              },
            ),
          ],
        ),
        drawer: const MyDrawer(),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search announcements...',
                    prefixIcon: const Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: _searchController.text.isEmpty 
                        ? null 
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          ),
                  ),
                ),
              ),
            ),
            
            // Category chips
            SizedBox(
              height: 50,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: _getCategories().map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _selectCategory(category);
                              }
                            },
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            selectedColor: theme.colorScheme.primaryContainer,
                          ),
                        );
                      }).toList(),
                    ),
            ),
            
            // Announcements list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAnnouncements,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredAnnouncements.isEmpty
                        ? _buildEmptyState()
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredAnnouncements.length,
                              itemBuilder: (context, index) {
                                final announcement = _filteredAnnouncements[index];
                                return _buildAnnouncementCard(announcement);
                              },
                            ),
                          ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: MyBottomNavigationBar(
          currentIndex: 1,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.announcement_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No announcements found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory != 'All' || _searchController.text.isNotEmpty
                  ? 'Try adjusting your filters'
                  : 'Check back later for updates',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedCategory != 'All' || _searchController.text.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Clear Filters'),
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'All';
                    _searchController.clear();
                  });
                  _filterAnnouncements();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');
    final formattedDate = dateFormat.format(announcement.date);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnnouncementDetailPage(
                announcement: announcement,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (announcement.isUrgent)
              Container(
                width: double.infinity,
                color: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: const Center(
                  child: Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          announcement.category,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${announcement.comments.length}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    announcement.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    announcement.content.length > 120
                        ? '${announcement.content.substring(0, 120)}...'
                        : announcement.content,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  
                  // Attachments indicator
                  if (announcement.attachments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.attach_file,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${announcement.attachments.length} attachment${announcement.attachments.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Bottom gradient for visual appeal
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: announcement.isUrgent
                      ? [Colors.red.shade300, Colors.red]
                      : [theme.colorScheme.primary.withValues(alpha: 128), theme.colorScheme.primary],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Announcements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getCategories().map((category) {
                      final isSelected = _selectedCategory == category;
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setStateModal(() {
                            setState(() {
                              _selectedCategory = category;
                            });
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setStateModal(() {
                            setState(() {
                              _selectedCategory = 'All';
                              _searchController.clear();
                            });
                          });
                        },
                        child: const Text('Clear All'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _filterAnnouncements();
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      // Already on Announcements
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/citizen_polls');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/citizen_report');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/citizen_message');
    }
  }
} 