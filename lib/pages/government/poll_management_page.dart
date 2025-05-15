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

class _PollManagementPageState extends State<PollManagementPage> with SingleTickerProviderStateMixin {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  final PollService _pollService = PollService();
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
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
      final allPolls = await _pollService.getActivePolls();
      final endedPolls = await _pollService.getEndedPolls();
      
      setState(() {
        // Active polls - already started but not ended
        _activePolls = allPolls.where((poll) => 
          poll.startDate.isBefore(now) && poll.endDate.isAfter(now)).toList();
        
        // Draft polls - haven't started yet
        _draftPolls = allPolls.where((poll) => 
          poll.startDate.isAfter(now)).toList();
        
        // Closed polls - already ended
        _closedPolls = endedPolls;
        
        // Create a list of recent polls (combining active and ended polls, sorted by date)
        _recentPolls = [..._activePolls, ..._closedPolls];
        _recentPolls.sort((a, b) => b.startDate.compareTo(a.startDate)); // Sort by newest first
        if (_recentPolls.length > 5) {
          _recentPolls = _recentPolls.sublist(0, 5); // Limit to 5 most recent polls
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
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Ensure end date is after start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isAfter(_startDate) ? _endDate : _startDate.add(const Duration(days: 1)),
      firstDate: _startDate.add(const Duration(days: 1)),
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
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
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
      final pollEndDate = _endDate.isAfter(tomorrow) ? _endDate : tomorrow.add(const Duration(days: 7));

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
            content: Text('Poll created and saved to drafts. You can publish when ready.'),
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

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/government_home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/announcements');
    } else if (index == 2) {
      // Already on polls page
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/government_message');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RouteGuardWrapper(
      allowedRoles: const ['government'],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Public Polls'),
          centerTitle: false,
          automaticallyImplyLeading: false,
          actions: [
            // New Poll button in header - styled like the Figma design
            Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
              child: SizedBox(
                height: 36,
                child: StandardActionButton(
                  label: 'New Poll',
                  icon: Icons.add_rounded,
                  onPressed: _showCreatePollBottomSheet,
                  style: ActionButtonStyle.primary,
                  size: ActionButtonSize.small,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Tab bar
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Draft'),
                  Tab(text: 'Closed'),
                ],
                labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.blue.shade600,
                unselectedLabelColor: Colors.grey[700],
                indicatorColor: Colors.blue.shade600,
              ),
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPollList(_activePolls),
                  _buildPollList(_draftPolls),
                  _buildPollList(_closedPolls),
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

  Widget _buildPollPreview(Poll poll) {
    final now = DateTime.now();
    final isPollActive = poll.startDate.isBefore(now) && poll.endDate.isAfter(now);
    final isPollEnded = poll.endDate.isBefore(now);
    final isPollFuture = poll.startDate.isAfter(now);
    
    // Calculate total votes and percentages
    final totalVotes = poll.votes.length;
    int yesVotes = 0;
    
    poll.votes.forEach((_, value) {
      if (value == 1) yesVotes++;
    });
    
    final yesPercentage = totalVotes > 0 ? (yesVotes / totalVotes * 100).round() : 0;
    final noPercentage = totalVotes > 0 ? 100 - yesPercentage : 0;
    
    // For government view, display static "Government" as creator
    final creatorId = "Government";
    
    final createdDate = DateFormat('MMM dd, yyyy').format(poll.startDate);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Question and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    poll.question,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPollActive 
                        ? Colors.green.withAlpha(25)
                        : isPollEnded 
                            ? Colors.red.withAlpha(25)
                            : Colors.grey.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isPollActive ? 'Active' : isPollEnded ? 'Closed' : 'Draft',
                    style: TextStyle(
                      color: isPollActive 
                          ? Colors.green
                          : isPollEnded 
                              ? Colors.red
                              : Colors.grey,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Creator ID and date
            Text(
              'Created by: $creatorId',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            
            Text(
              'Created on: $createdDate',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            
            // Description
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              child: Text(
                poll.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Yes votes
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Yes',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(width: 8),
                Text(
                  '$yesPercentage%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: yesPercentage / 100,
                backgroundColor: Colors.grey[200],
                color: Colors.green,
                minHeight: 8,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // No votes
            Row(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Text(
                  'No',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(width: 8),
                Text(
                  '$noPercentage%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: noPercentage / 100,
                backgroundColor: Colors.grey[200],
                color: Colors.red,
                minHeight: 8,
              ),
            ),
            
            const SizedBox(height: 8),
            Text(
              'Total votes: $totalVotes',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // View Details button
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PollDetailPage(poll: poll),
                      ),
                    ).then((_) => _loadPolls());
                  },
                  icon: const Icon(Icons.description_outlined, size: 18, color: Colors.grey),
                  label: Text(
                    'View Details (${poll.comments.length})',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                
                // Action buttons based on poll status
                if (isPollFuture)
                  Row(
                    children: [
                      StandardActionButton(
                        label: 'Publish',
                        icon: Icons.publish_rounded,
                        onPressed: () => _publishDraftPoll(poll),
                        style: ActionButtonStyle.primary,
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () => _deletePoll(poll),
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  )
                else if (isPollActive)
                  TextButton.icon(
                    onPressed: () => _closePoll(poll),
                    icon: Icon(Icons.timer_off_outlined, size: 18, color: Colors.grey[700]),
                    label: Text('Close Poll', style: TextStyle(color: Colors.grey[700])),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                else if (isPollEnded)
                  Row(
                    children: [
                      RepublishButton(
                        onPressed: () => _republishPoll(poll),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () => _deletePoll(poll),
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  )
                else if (!isPollEnded)
                  TextButton.icon(
                    onPressed: () => _editPoll(poll),
                    icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey[700]),
                    label: Text('Edit', style: TextStyle(color: Colors.grey[700])),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollList(List<Poll> polls) {
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
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No polls available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: polls.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => _buildPollPreview(polls[index]),
    );
  }

  void _showCreatePollBottomSheet() {
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
              const Center(
                child: Text(
                    'Create New Poll',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                  ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                        fillColor: Theme.of(context).colorScheme.secondary,
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
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy').format(_startDate),
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
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'End Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy').format(_endDate),
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
                        message: 'When enabled, voter identities will not be visible in the results',
                        child: Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: MyButton(
                      text: 'Create Poll',
                  onTap: _createPoll,
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
                    fillColor: Theme.of(context).colorScheme.secondary,
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
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy').format(_startDate),
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
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'End Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy').format(_endDate),
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
                        message: 'When enabled, voter identities will not be visible in the results',
                        child: Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Submit button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
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
        content: const Text('Are you sure you want to close this poll? This action cannot be undone.'),
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

  Future<void> _publishDraftPoll(Poll poll) async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Draft Poll'),
        content: const Text('Are you sure you want to publish this draft poll? It will become active immediately.'),
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
        title: const Text('Republish Closed Poll'),
        content: const Text('Are you sure you want to republish this poll? It will be active for 7 days from now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          RepublishButton(
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
                      content: Text('Poll republished and is now active for 7 days!'),
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
                      content: Text('Error republishing poll: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
                    },
                  ),
                ],
            ),
    );
  }
} 