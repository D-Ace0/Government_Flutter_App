import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:governmentapp/models/announcement.dart';
import 'package:governmentapp/pages/announcement_detail_page.dart';
import 'package:governmentapp/services/announcement/announcement_service.dart';
import 'package:governmentapp/services/notification/notification_service.dart';
import 'package:governmentapp/services/user/route_guard_wrapper.dart';
import 'package:governmentapp/widgets/my_drawer.dart';
import 'package:governmentapp/utils/logger.dart';
import 'package:intl/intl.dart';

class CitizenAnnouncementsPage extends StatefulWidget {
  const CitizenAnnouncementsPage({super.key});

  @override
  State<CitizenAnnouncementsPage> createState() => _CitizenAnnouncementsPageState();
}

class _CitizenAnnouncementsPageState extends State<CitizenAnnouncementsPage> with TickerProviderStateMixin {
  final AnnouncementService _announcementService = AnnouncementService();
  final NotificationService _notificationService = NotificationService();
  List<Announcement> _announcements = [];
  List<Announcement> _filteredAnnouncements = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _listItemController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _searchBarAnimation;
  late Animation<double> _chipAnimation;
  DateTime _lastCheckTime = DateTime.now().subtract(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    
    // Main fade animation for content
    _fadeController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    // Search bar and filters animation
    _searchBarAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0, 0.6, curve: Curves.easeOutQuad),
      ),
    );
    
    _chipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutQuad),
      ),
    );
    
    // List items animation controller
    _listItemController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _loadAnnouncements();
    _searchController.addListener(_filterAnnouncements);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _listItemController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final announcements = await _announcementService.getActiveAnnouncements();
      
      // Check for new announcements and show notifications
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
          
          // Sort announcements by urgency and date
          _announcements.sort((a, b) {
            if (a.isUrgent && !b.isUrgent) return -1;
            if (!a.isUrgent && b.isUrgent) return 1;
            return b.date.compareTo(a.date); // Newer first
          });
          
          _filteredAnnouncements = List.from(_announcements);
          _isLoading = false;
        });
        
        // Start animations
        _fadeController.forward();
        _listItemController.reset();
        _listItemController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        AppLogger.e("Error loading announcements: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading announcements'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
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
    if (_selectedCategory == category) return;
    
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategory = category;
    });
    _filterAnnouncements();
  }

  List<String> _getCategories() {
    final categories = _announcements.map((a) => a.category).toSet().toList();
    categories.sort(); // Sort alphabetically
    categories.insert(0, 'All');
    return categories;
  }

  void _navigateToAnnouncementDetail(Announcement announcement) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementDetailPage(
          announcement: announcement,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return RouteGuardWrapper(
      allowedRoles: const ['citizen'],
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Announcements', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                HapticFeedback.mediumImpact();
                _showFilterDialog();
              },
              tooltip: 'Filter',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                HapticFeedback.mediumImpact();
                _loadAnnouncements();
              },
              tooltip: 'Refresh',
            ),
          ],
        ),
        drawer: MyDrawer(role: 'citizen'),
        body: Column(
          children: [
            // Search bar with animation
            FadeTransition(
              opacity: _searchBarAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.2),
                  end: Offset.zero,
                ).animate(_fadeController),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(77),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: 'Search announcements...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Icon(
                          Icons.search,
                          color: theme.colorScheme.primary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        suffixIcon: _searchController.text.isEmpty 
                            ? null 
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  _searchController.clear();
                                },
                                color: Colors.grey.shade600,
                              ),
                      ),
                      onChanged: (_) => _filterAnnouncements(),
                    ),
                  ),
                ),
              ),
            ),
            
            // Category chips with animation
            FadeTransition(
              opacity: _chipAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(_fadeController),
                child: SizedBox(
                  height: 56,
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: _getCategories().map((category) {
                            final isSelected = _selectedCategory == category;
                            // Different colors for different categories
                            Color chipColor;
                            IconData? chipIcon;
                            
                            switch (category) {
                              case 'Emergency':
                                chipColor = Colors.red.shade700;
                                chipIcon = Icons.warning_amber_rounded;
                                break;
                              case 'Education':
                                chipColor = Colors.blue.shade600;
                                chipIcon = Icons.school;
                                break;
                              case 'Infrastructure':
                                chipColor = Colors.amber.shade800;
                                chipIcon = Icons.construction;
                                break;
                              case 'All':
                                chipColor = theme.colorScheme.primary;
                                chipIcon = Icons.all_inbox;
                                break;
                              default:
                                chipColor = theme.colorScheme.primary;
                                chipIcon = Icons.label;
                            }
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      chipIcon,
                                      size: 16,
                                      color: isSelected ? Colors.white : chipColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(category),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    _selectCategory(category);
                                  }
                                },
                                backgroundColor: Colors.white,
                                selectedColor: chipColor,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : chipColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                elevation: isSelected ? 2 : 0,
                                pressElevation: 4,
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
            ),
            
            // Announcements list with animations
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAnnouncements,
                color: theme.colorScheme.primary,
                backgroundColor: Colors.white,
                child: _isLoading
                    ? _buildLoadingState()
                    : _filteredAnnouncements.isEmpty
                        ? _buildEmptyState()
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildAnnouncementsList(),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Loading announcements...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
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
              Icon(
                _selectedCategory == 'All' 
                    ? Icons.campaign_outlined 
                    : Icons.search_off_outlined,
                size: 100,
                color: Colors.grey.withAlpha(128),
              ),
              const SizedBox(height: 24),
              Text(
                'No announcements found',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _selectedCategory != 'All' || _searchController.text.isNotEmpty
                    ? 'Try adjusting your search filters'
                    : 'Check back later for new announcements',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              if (_selectedCategory != 'All' || _searchController.text.isNotEmpty)
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('CLEAR FILTERS'),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _selectedCategory = 'All';
                      _searchController.clear();
                    });
                    _filterAnnouncements();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredAnnouncements.length,
      itemBuilder: (context, index) {
        final announcement = _filteredAnnouncements[index];
        
        // Create staggered animation for each list item
        final itemAnimation = Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _listItemController,
            curve: Interval(
              (index / _filteredAnnouncements.length) * 0.6,
              min(((index + 1) / _filteredAnnouncements.length) * 0.6 + 0.4, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );

        return SlideTransition(
          position: itemAnimation,
          child: _buildAnnouncementCard(announcement),
        );
      },
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMM yyyy');
    final formattedDate = dateFormat.format(announcement.date);
    
    // Color scheme based on category
    Color categoryColor;
    IconData categoryIcon;
    
    switch (announcement.category) {
      case 'Emergency':
        categoryColor = Colors.red.shade700;
        categoryIcon = Icons.warning_amber_rounded;
        break;
      case 'Education':
        categoryColor = Colors.blue.shade600;
        categoryIcon = Icons.school;
        break;
      case 'Infrastructure':
        categoryColor = Colors.amber.shade800;
        categoryIcon = Icons.construction;
        break;
      default:
        categoryColor = theme.colorScheme.primary;
        categoryIcon = Icons.notifications;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: announcement.isUrgent ? 3 : 2,
      shadowColor: announcement.isUrgent 
          ? Colors.red.withAlpha(77)
          : Colors.black.withAlpha(153),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: announcement.isUrgent
            ? BorderSide(color: Colors.red.shade200.withAlpha(255), width: 1)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToAnnouncementDetail(announcement),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (announcement.isUrgent)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.priority_high,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'URGENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category, date and comments
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: categoryColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              categoryIcon,
                              size: 14,
                              color: categoryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              announcement.category,
                              style: TextStyle(
                                color: categoryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${announcement.comments.length}',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Title with proper styling
                  Text(
                    announcement.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: announcement.isUrgent ? Colors.red.shade800 : Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Content preview
                  Text(
                    announcement.content.length > 120
                        ? '${announcement.content.substring(0, 120)}...'
                        : announcement.content,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                  
                  // Display first image if attachments exist
                  if (announcement.attachments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.network(
                              announcement.attachments.first,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              cacheHeight: 360,
                              cacheWidth: 720,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey[400],
                                      size: 32,
                                    ),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 180,
                                  width: double.infinity,
                                  color: Colors.grey[100],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / 
                                            loadingProgress.expectedTotalBytes!
                                          : null,
                                      strokeWidth: 2,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Optional gradient overlay for better text visibility
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 60,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withAlpha(153),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Attachments indicator
                  if (announcement.attachments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  size: 14,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${announcement.attachments.length} attachment${announcement.attachments.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
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
            
            // Card footer action button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(
                      Icons.arrow_forward,
                      size: 16,
                    ),
                    label: const Text('View Details'),
                    onPressed: () => _navigateToAnnouncementDetail(announcement),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.filter_list),
                      const SizedBox(width: 8),
                      const Text(
                        'Filter Announcements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        splashRadius: 24,
                      ),
                    ],
                  ),
                  
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Filter chips
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _getCategories().map((category) {
                      final isSelected = _selectedCategory == category;
                      
                      // Different colors for different categories
                      Color chipColor;
                      IconData? chipIcon;
                      
                      switch (category) {
                        case 'Emergency':
                          chipColor = Colors.red.shade700;
                          chipIcon = Icons.warning_amber_rounded;
                          break;
                        case 'Education':
                          chipColor = Colors.blue.shade600;
                          chipIcon = Icons.school;
                          break;
                        case 'Infrastructure':
                          chipColor = Colors.amber.shade800;
                          chipIcon = Icons.construction;
                          break;
                        case 'All':
                          chipColor = Theme.of(context).colorScheme.primary;
                          chipIcon = Icons.all_inbox;
                          break;
                        default:
                          chipColor = Theme.of(context).colorScheme.primary;
                          chipIcon = Icons.label;
                      }
                      
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              chipIcon,
                              size: 16,
                              color: isSelected ? Colors.white : chipColor,
                            ),
                            const SizedBox(width: 6),
                            Text(category),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          HapticFeedback.selectionClick();
                          setStateModal(() {
                            setState(() {
                              _selectedCategory = category;
                            });
                          });
                        },
                        backgroundColor: Colors.grey.shade100,
                        selectedColor: chipColor,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : chipColor,
                          fontWeight: FontWeight.w500,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected ? chipColor : Colors.grey.shade300,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          setStateModal(() {
                            setState(() {
                              _selectedCategory = 'All';
                              _searchController.clear();
                            });
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('CLEAR ALL'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _filterAnnouncements();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('APPLY FILTERS'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
} 