import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../models/poll.dart';
import '../../services/poll/poll_service.dart';
import '../../widgets/my_button.dart';
import '../../widgets/my_dropdown.dart';
import '../../widgets/my_text_field.dart';
import '../../pages/poll_detail_page.dart';
import '../../widgets/my_bottom_navigation_bar.dart';
import '../../widgets/my_action_button.dart';
import 'package:governmentapp/services/user/route_guard_wrapper.dart';

class PollManagementPage extends StatefulWidget {
  const PollManagementPage({super.key});

  @override
  State<PollManagementPage> createState() => _PollManagementPageState();
}

class _PollManagementPageState extends State<PollManagementPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final PollService _pollService = PollService();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();
  String? _selectedCategory;
  bool _isAnonymous = false;
  bool _isLoading = false;

  late TabController _tabController;
  List<Poll> _activePolls = [];
  List<Poll> _draftPolls = [];
  List<Poll> _closedPolls = [];
  List<Poll> _recentPolls = [];

  final List<String> categories = [
    'General',
    'Infrastructure',
    'Health',
    'Education',
    'Environment',
    'Public Safety',
    'Transportation',
    'Policy',
    'Community Services',
  ];

  int _selectedIndex = 2; // Set to 2 for "Polls" tab in the bottom navigation

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPolls();
  }

  Future<void> _loadPolls() async {
    // Don't set loading to true for background refreshes
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final now = DateTime.now();
      final allPolls =
          await _pollService.getPolls(); // Get all polls instead of just active
      final endedPolls = await _pollService.getEndedPolls();

      setState(() {
        // Active polls - already started but not ended
        _activePolls = allPolls
            .where((poll) =>
                poll.startDate.isBefore(now) && poll.endDate.isAfter(now))
            .toList();

        // Draft polls - haven't started yet
        _draftPolls =
            allPolls.where((poll) => poll.startDate.isAfter(now)).toList();

        // Closed polls - already ended
        _closedPolls = endedPolls;

        // Create a list of recent polls (combining active and ended polls, sorted by date)
        _recentPolls = [..._activePolls, ..._closedPolls];
        _recentPolls.sort((a, b) =>
            b.startDate.compareTo(a.startDate)); // Sort by newest first
        if (_recentPolls.length > 5) {
          _recentPolls =
              _recentPolls.sublist(0, 5); // Limit to 5 most recent polls
        }

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading polls: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _descriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      // After selecting the date, show time picker
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _startTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedTime != null) {
        setState(() {
          // Combine the picked date with the picked time
          _startDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _startTime = pickedTime;
          
          // Ensure end date is after start date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
            _endTime = _startTime;
          }
        });
      }
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isAfter(_startDate) ? _endDate : _startDate.add(const Duration(days: 1)),
      firstDate: _startDate.day == DateTime.now().day ? _startDate.add(const Duration(days: 1)) : _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      // After selecting the date, show time picker
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _endTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedTime != null) {
        setState(() {
          // Combine the picked date with the picked time
          _endDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _endTime = pickedTime;
        });
      }
    }
  }

  Future<void> _createPoll() async {
    if (_questionController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Always set start date to tomorrow to ensure the poll is a draft
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      // Ensure end date is after start date
      final pollEndDate = _endDate.isAfter(tomorrow)
          ? _endDate
          : tomorrow.add(const Duration(days: 7));

      // Create poll
      final poll = Poll(
        id: const Uuid().v4(),
        question: _questionController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: tomorrow, // Always create as draft with future start date
        endDate: pollEndDate,
        votes: {},
        comments: [],
        isAnonymous: _isAnonymous,
        creatorId: currentUser.uid,
        category: _selectedCategory!,
      );

      await _pollService.createPoll(poll);

      if (mounted) {
        Navigator.pop(context); // Close the creation modal

        // Automatically switch to the Drafts tab
        _tabController.animateTo(1); // Index 1 is the Drafts tab

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Poll created and saved to drafts. You can publish when ready.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Reset form
        _questionController.clear();
        _descriptionController.clear();
        setState(() {
          _startDate = DateTime.now();
          _endDate = DateTime.now().add(const Duration(days: 7));
          _selectedCategory = null;
          _isAnonymous = false;
        });

        _loadPolls(); // Refresh poll lists
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating poll: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToGovernmentHome() {
    Navigator.pushReplacementNamed(context, '/government_home');
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      _navigateToGovernmentHome();
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/announcements');
    } else if (index == 2) {
      // Already on polls page
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/report');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/government_message');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define a consistent color palette
    final primaryBlue = const Color(0xFF0D47A1);
    final secondaryBlue = const Color(0xFF1976D2);
    final lightBlue = const Color(0xFF42A5F5);
    final activeGreen = const Color(0xFF4CAF50);
    final backgroundColor = Colors.grey[50];
    
    return RouteGuardWrapper(
      allowedRoles: const ['government'],
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              // Back button with styling
              GestureDetector(
                onTap: _navigateToGovernmentHome,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryBlue.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withAlpha(26),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: primaryBlue,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.poll_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Public Polls",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: primaryBlue,
                    size: 20,
                  ),
                ),
                onPressed: _showCreatePollBottomSheet,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Stats Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryBlue,
                    secondaryBlue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withAlpha(26),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.check_circle_outline_rounded,
                    value: _activePolls.length.toString(),
                    label: 'Active Polls',
                    iconColor: Colors.white,
                    valueColor: Colors.white,
                  ),
                  _buildStatItem(
                    icon: Icons.pending_actions_rounded,
                    value: _draftPolls.length.toString(),
                    label: 'Draft Polls',
                    iconColor: Colors.white,
                    valueColor: Colors.white,
                  ),
                  _buildStatItem(
                    icon: Icons.archive_outlined,
                    value: _closedPolls.length.toString(),
                    label: 'Closed Polls',
                    iconColor: Colors.white,
                    valueColor: Colors.white,
                  ),
                ],
              ),
            ),
            
            // Tab bar - modern design
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Draft'),
                  Tab(text: 'Closed'),
                ],
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                indicator: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[700],
                padding: const EdgeInsets.all(4),
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPollList(_activePolls, primaryBlue, activeGreen, lightBlue),
                  _buildPollList(_draftPolls, primaryBlue, activeGreen, lightBlue),
                  _buildPollList(_closedPolls, primaryBlue, activeGreen, lightBlue),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: MyBottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onBottomNavTap,
        ),
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(51), // 0.2 * 255 ≈ 51
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: valueColor.withAlpha(217), // 0.85 * 255 ≈ 217
          ),
        ),
      ],
    );
  }

  Widget _buildPollList(List<Poll> polls, Color primaryColor, Color activeColor, Color lightBlue) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (polls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.poll_outlined,
              size: 70,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No polls available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new poll to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: polls.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => _buildPollPreview(polls[index], primaryColor, activeColor, lightBlue),
    );
  }

  Widget _buildPollPreview(Poll poll, Color primaryColor, Color activeColor, Color lightBlue) {
    final now = DateTime.now();
    final isPollActive =
        poll.startDate.isBefore(now) && poll.endDate.isAfter(now);
    final isPollEnded = poll.endDate.isBefore(now);
    final isPollFuture = poll.startDate.isAfter(now);
    
    // Define color scheme based on poll status
    final headerColors = isPollActive 
        ? [const Color(0xFF43A047), const Color(0xFF66BB6A)]
        : isPollEnded
            ? [const Color(0xFFE53935), const Color(0xFFEF5350)]
            : [primaryColor, lightBlue];
    
    final statusColor = isPollActive 
        ? activeColor
        : isPollEnded
            ? Colors.red
            : primaryColor;
    
    // Calculate total votes and percentages
    final totalVotes = poll.votes.length;
    int yesVotes = 0;

    poll.votes.forEach((_, value) {
      if (value == 1) yesVotes++;
    });

    final yesPercentage =
        totalVotes > 0 ? (yesVotes / totalVotes * 100).round() : 0;
    final noPercentage = totalVotes > 0 ? 100 - yesPercentage : 0;
    
    // Format the dates with time
    final startDateTimeFormatted = DateFormat('MMM dd, yyyy • h:mm a').format(poll.startDate);
    final endDateTimeFormatted = DateFormat('MMM dd, yyyy • h:mm a').format(poll.endDate);
    
    // Calculate days left or days since ended
    final daysLeft = isPollEnded 
        ? 'Ended ${now.difference(poll.endDate).inDays} days ago'
        : isPollActive
            ? '${poll.endDate.difference(now).inDays + 1} days left'
            : 'Starts in ${poll.startDate.difference(now).inDays + 1} days';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 * 255 ≈ 13
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category and status
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: headerColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Category pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(77), // 0.3 * 255 ≈ 77
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Environment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  // Status indicator
                  Row(
                    children: [
                      Icon(
                        isPollActive 
                            ? Icons.how_to_vote_rounded
                            : isPollEnded
                                ? Icons.event_busy_rounded
                                : Icons.schedule_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPollActive ? 'Active' : isPollEnded ? 'Closed' : 'Draft',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Poll content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question
                Text(
                  poll.question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Description
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(
                    poll.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Date range
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.date_range_outlined,
                            size: 16,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(51), // 0.2 * 255 ≈ 51
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              daysLeft,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Start:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                Text(
                                  startDateTimeFormatted,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'End:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                Text(
                                  endDateTimeFormatted,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Poll statistics
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Yes votes
                        _buildVoteIndicator(
                          label: 'Yes',
                          percentage: yesPercentage,
                          icon: Icons.check_circle_outline,
                          color: activeColor,
                        ),
                        
                        // Divider
                        Container(
                          height: 30,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        
                        // No votes
                        _buildVoteIndicator(
                          label: 'No',
                          percentage: noPercentage,
                          icon: Icons.cancel_outlined,
                          color: Colors.red[400]!,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Total votes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$totalVotes total ${totalVotes == 1 ? 'vote' : 'votes'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        if (poll.isAnonymous)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(51), // 0.2 * 255 ≈ 51
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility_off_outlined,
                                  size: 10,
                                  color: Colors.orange[700],
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Anonymous',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // View Details
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PollDetailPage(poll: poll),
                      ),
                    ).then((_) => _loadPolls());
                  },
                  icon: Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: primaryColor,
                  ),
                  label: Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryColor,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                
                // Action buttons
                Row(
                  children: [
                    if (isPollFuture) ...[
                      // Edit button for draft polls
                      IconButton(
                        onPressed: () => _editPoll(poll),
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: primaryColor,
                        ),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      // Publish button for draft polls
                      TextButton.icon(
                        onPressed: () => _publishPoll(poll),
                        icon: const Icon(
                          Icons.publish,
                          size: 18,
                          color: Colors.green,
                        ),
                        label: const Text(
                          'Publish',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                    
                    // Close button for active polls
                    if (isPollActive) 
                      TextButton.icon(
                        onPressed: () => _closePoll(poll),
                        icon: const Icon(
                          Icons.cancel_outlined,
                          size: 18,
                          color: Colors.orange,
                        ),
                        label: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    
                    // Reactivate button for closed polls
                    if (isPollEnded)
                      TextButton.icon(
                        onPressed: () => _republishPoll(poll),
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: Colors.green,
                        ),
                        label: const Text(
                          'Reactivate',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    
                    // Delete button for all polls
                    IconButton(
                      onPressed: () => _showDeleteDialog(poll),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVoteIndicator({
    required String label,
    required int percentage,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          // Percentage indicator with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // Progress bar
          Container(
            width: 120,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  width: 120 * percentage / 100,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePollBottomSheet() {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.poll_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Create New Poll',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Form fields
              const Text(
                'Question',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              MyTextfield(
                hintText: 'What would you like to ask?',
                controller: _questionController,
                obSecure: false,
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Provide additional context about this poll',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              MyDropdownField(
                hintText: 'Select a category',
                value: _selectedCategory,
                items: categories,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Duration',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectStartDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withAlpha(128)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Start Date & Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy • h:mm a').format(_startDate),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectEndDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withAlpha(128)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'End Date & Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy • h:mm a').format(_endDate),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Voting settings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Voting Settings',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: StatefulBuilder(
                        builder: (context, setStateLocal) => Row(
                          children: [
                            Transform.scale(
                              scale: 1.1,
                              child: Checkbox(
                                value: _isAnonymous,
                                activeColor: theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (bool? value) {
                                  setStateLocal(() {
                                    _isAnonymous = value ?? false;
                                  });
                                  setState(() {
                                    _isAnonymous = value ?? false;
                                  });
                                },
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Enable anonymous voting',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Voter identities will not be visible in results',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Submit button
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ElevatedButton.icon(
                      onPressed: _createPoll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text(
                        'CREATE POLL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _editPoll(Poll poll) {
    // Set the form values to the poll's current values
    _questionController.text = poll.question;
    _descriptionController.text = poll.description;
    _startDate = poll.startDate;
    _endDate = poll.endDate;
    _selectedCategory = poll.category;
    _isAnonymous = poll.isAnonymous;

    // Show the edit dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and close button
              Row(
                children: [
                  const Text(
                    'Edit Poll',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                      // Reset form
                      _questionController.clear();
                      _descriptionController.clear();
                      setState(() {
                        _startDate = DateTime.now();
                        _endDate = DateTime.now().add(const Duration(days: 7));
                        _selectedCategory = null;
                        _isAnonymous = false;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Form fields (reused from create poll form)
              MyTextfield(
                hintText: 'Question',
                controller: _questionController,
                obSecure: false,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              MyDropdownField(
                hintText: 'Category',
                value: _selectedCategory,
                items: categories,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectStartDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withAlpha(128)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start Date & Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy • h:mm a').format(_startDate),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectEndDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withAlpha(128)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'End Date & Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy • h:mm a').format(_endDate),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: StatefulBuilder(
                  builder: (context, setStateLocal) => Row(
                    children: [
                      Transform.scale(
                        scale: 1.1,
                        child: Checkbox(
                          value: _isAnonymous,
                          activeColor: Colors.blue,
                          onChanged: (bool? value) {
                            setStateLocal(() {
                              _isAnonymous = value ?? false;
                            });
                            setState(() {
                              _isAnonymous = value ?? false;
                            });
                          },
                        ),
                      ),
                      const Text(
                        'Enable anonymous voting',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Tooltip(
                        message:
                            'When enabled, voter identities will not be visible in the results',
                        child: Icon(Icons.info_outline,
                            size: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Submit button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
                child: MyButton(
                  text: 'Save Changes',
                  onTap: () => _updatePoll(poll.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updatePoll(String pollId) async {
    if (_questionController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get the existing poll to preserve votes and comments
      final existingPoll = [..._activePolls, ..._draftPolls, ..._closedPolls]
          .firstWhere((p) => p.id == pollId);

      // Create updated poll
      final updatedPoll = Poll(
        id: pollId,
        question: _questionController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        votes: existingPoll.votes,
        comments: existingPoll.comments,
        isAnonymous: _isAnonymous,
        creatorId: existingPoll.creatorId,
        category: _selectedCategory!,
      );

      await _pollService.updatePoll(updatedPoll);

      if (mounted) {
        Navigator.pop(context); // Close the edit dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poll updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        _questionController.clear();
        _descriptionController.clear();
        setState(() {
          _startDate = DateTime.now();
          _endDate = DateTime.now().add(const Duration(days: 7));
          _selectedCategory = null;
          _isAnonymous = false;
        });

        _loadPolls(); // Refresh poll lists
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating poll: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _deletePoll(Poll poll) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Poll'),
        content: Text('Are you sure you want to delete "${poll.question}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              try {
                await _pollService.deletePoll(poll.id);
                
                if (mounted) {
                  // Immediately update local state for UI refresh
                  setState(() {
                    // Remove the poll from all local lists
                    _activePolls.removeWhere((p) => p.id == poll.id);
                    _draftPolls.removeWhere((p) => p.id == poll.id);
                    _closedPolls.removeWhere((p) => p.id == poll.id);
                    _recentPolls.removeWhere((p) => p.id == poll.id);
                    _isLoading = false;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Poll deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Refresh data from server in background
                  _loadPolls();
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting poll: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _closePoll(Poll poll) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Poll'),
        content: const Text(
            'Are you sure you want to close this poll? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              try {
                // Update the poll end date to now
                final updatedPoll = Poll(
                  id: poll.id,
                  question: poll.question,
                  description: poll.description,
                  startDate: poll.startDate,
                  endDate: DateTime.now(), // Set to now to close
                  votes: poll.votes,
                  comments: poll.comments,
                  isAnonymous: poll.isAnonymous,
                  creatorId: poll.creatorId,
                  category: poll.category,
                );

                await _pollService.updatePoll(updatedPoll);

                if (mounted) {
                  // Immediately update local state for UI refresh
                  setState(() {
                    // Remove the poll from active list
                    _activePolls.removeWhere((p) => p.id == poll.id);
                    // Add to closed polls
                    _closedPolls.add(updatedPoll);
                    _isLoading = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Poll closed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Refresh data from server in background
                  _loadPolls();
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error closing poll: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Close Poll'),
          ),
        ],
      ),
    );
  }

  Future<void> _publishPoll(Poll poll) async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Draft Poll'),
        content: const Text(
            'Are you sure you want to publish this draft poll? It will become active immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          StandardActionButton(
            label: 'Publish',
            icon: Icons.publish_rounded,
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              try {
                // Update the poll's start date to now to make it active immediately
                final updatedPoll = Poll(
                  id: poll.id,
                  question: poll.question,
                  description: poll.description,
                  startDate: DateTime.now(), // Set to now to make it active
                  endDate: poll.endDate,
                  votes: poll.votes,
                  comments: poll.comments,
                  isAnonymous: poll.isAnonymous,
                  creatorId: poll.creatorId,
                  category: poll.category,
                );

                await _pollService.updatePoll(updatedPoll);

                if (mounted) {
                  // Immediately update local state for UI refresh
                  setState(() {
                    // Remove from drafts
                    _draftPolls.removeWhere((p) => p.id == poll.id);
                    // Add to active polls
                    _activePolls.add(updatedPoll);
                    _isLoading = false;
                  });

                  // Automatically switch to Active tab after publishing
                  _tabController.animateTo(0); // Index 0 is Active tab

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Poll published and is now active!'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Refresh data from server in background
                  _loadPolls();
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error publishing poll: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ActionButtonStyle.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _republishPoll(Poll poll) async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reactivate Closed Poll'),
        content: const Text('Are you sure you want to reactivate this poll? It will be active for 7 days from now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              try {
                // Set new start and end dates for the republished poll
                final now = DateTime.now();
                final newEndDate = now.add(const Duration(days: 7));

                final updatedPoll = Poll(
                  id: poll.id,
                  question: poll.question,
                  description: poll.description,
                  startDate: now, // Start now
                  endDate: newEndDate, // End in 7 days
                  votes: {}, // Reset votes for the new poll period
                  comments: poll.comments, // Keep existing comments
                  isAnonymous: poll.isAnonymous,
                  creatorId: poll.creatorId,
                  category: poll.category,
                );

                await _pollService.updatePoll(updatedPoll);

                if (mounted) {
                  // Immediately update local state for UI refresh
                  setState(() {
                    // Remove from closed polls
                    _closedPolls.removeWhere((p) => p.id == poll.id);
                    // Add to active polls
                    _activePolls.add(updatedPoll);
                    _isLoading = false;
                  });

                  // Automatically switch to Active tab after republishing
                  _tabController.animateTo(0); // Index 0 is Active tab

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Poll reactivated and is now active for 7 days!'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Refresh data from server in background
                  _loadPolls();
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error reactivating poll: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Reactivate',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Poll poll) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Poll'),
        content: Text('Are you sure you want to delete "${poll.question}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePoll(poll);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
