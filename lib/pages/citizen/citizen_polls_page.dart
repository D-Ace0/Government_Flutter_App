import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:governmentapp/models/poll.dart';
import 'package:governmentapp/pages/poll_detail_page.dart';
import 'package:governmentapp/services/poll/poll_service.dart';
import 'package:governmentapp/services/notification/notification_service.dart';
import 'package:governmentapp/services/user/route_guard_wrapper.dart';
import 'package:governmentapp/services/user/user_provider.dart';
import 'package:governmentapp/widgets/my_drawer.dart';
import 'package:governmentapp/utils/logger.dart';
import 'package:provider/provider.dart';

class CitizenPollsPage extends StatefulWidget {
  const CitizenPollsPage({super.key});

  @override
  State<CitizenPollsPage> createState() => _CitizenPollsPageState();
}

class _CitizenPollsPageState extends State<CitizenPollsPage> with TickerProviderStateMixin {
  final PollService _pollService = PollService();
  final NotificationService _notificationService = NotificationService();
  List<Poll> _filteredPolls = [];
  bool _isLoading = false;
  String _filter = 'Active';
  
  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  
  // For item animation
  late AnimationController _listItemController;
  
  final Map<String, bool> _showResultsMap = {};
  DateTime _lastCheckTime = DateTime.now().subtract(const Duration(days: 1));
  
  @override
  void initState() {
    super.initState();
    
    // Main fade animation for the whole list
    _fadeController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    // Animation for list items staggered entrance
    _listItemController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Tab controller for Active/Previous polls
    _tabController = TabController(length: 2, vsync: this);
    
    _loadPolls();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _listItemController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPolls() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Poll> polls = [];
      
      if (_filter == 'Active') {
        polls = await _pollService.getActivePolls();
      } else {
        polls = await _pollService.getEndedPolls();
      }
      
      // Check for new polls and show notifications
      _notificationService.checkForNewPolls(polls, _lastCheckTime, context);
      _lastCheckTime = DateTime.now();
      
      if (mounted) {
        setState(() {
          _filteredPolls = polls;
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
        
        AppLogger.e("Error loading polls: $e");
        String errorMessage = 'Error loading polls';
        if (e.toString().contains('failed-precondition') && 
            e.toString().contains('index')) {
          errorMessage = 'Database error: An index is required. Please contact support.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitVote(Poll poll, int voteValue) async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to vote')),
      );
      return;
    }
    
    // Provide haptic feedback for better UX
    HapticFeedback.mediumImpact();
    
    final hasVoted = poll.hasVoted(userId);
    final message = hasVoted ? 'Your vote has been updated' : 'Your vote has been recorded';
    
    try {
      await _pollService.vote(poll.id, userId, voteValue);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'VIEW RESULTS',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _showResultsMap[poll.id] = true;
                });
              },
            ),
          ),
        );
        _loadPolls();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleResults(String pollId) {
    HapticFeedback.selectionClick();
    setState(() {
      _showResultsMap[pollId] = !(_showResultsMap[pollId] ?? false);
    });
  }

  void _navigateToDetails(Poll poll) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PollDetailPage(poll: poll),
      ),
    ).then((_) => _loadPolls());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return RouteGuardWrapper(
      allowedRoles: const ['citizen'],
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text(
            'Public Polls', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            )
          ),
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                HapticFeedback.mediumImpact();
                _loadPolls();
              },
              tooltip: 'Refresh polls',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                onTap: (index) {
                  setState(() {
                    _filter = index == 0 ? 'Active' : 'Previous';
                  });
                  _loadPolls();
                },
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.how_to_vote),
                        SizedBox(width: 8),
                        Text('Active'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.history),
                        SizedBox(width: 8),
                        Text('Previous'),
                      ],
                    ),
                  ),
                ],
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withAlpha(179),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                indicatorSize: TabBarIndicatorSize.tab,
              ),
            ),
          ),
        ),
        drawer: MyDrawer(role: 'citizen'),
        body: RefreshIndicator(
          onRefresh: _loadPolls,
          color: theme.colorScheme.primary,
          backgroundColor: Colors.white,
          child: _isLoading
              ? _buildLoadingState()
              : _filteredPolls.isEmpty
                  ? _buildEmptyState()
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildPollsList(),
                    ),
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
          const SizedBox(height: 16),
          Text(
            'Loading polls...',
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
                _filter == 'Active' ? Icons.how_to_vote_outlined : Icons.history_outlined,
                size: 100,
                color: Colors.grey.withAlpha(128),
              ),
              const SizedBox(height: 24),
              Text(
                'No ${_filter.toLowerCase()} polls found',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _filter == 'Active'
                    ? 'Check back later for new polls or refresh to try again'
                    : 'Previous polls will appear here after they end',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPolls,
                icon: const Icon(Icons.refresh),
                label: const Text('REFRESH'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPollsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredPolls.length,
      itemBuilder: (context, index) {
        final poll = _filteredPolls[index];
        
        // Create staggered animation for each list item
        final itemAnimation = Tween<Offset>(
          begin: const Offset(0.5, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _listItemController,
            curve: Interval(
              (index / _filteredPolls.length) * 0.7,
              min(((index + 1) / _filteredPolls.length) * 0.7 + 0.3, 1.0),
              curve: Curves.easeOutQuart,
            ),
          ),
        );

        return SlideTransition(
          position: itemAnimation,
          child: _buildModernPollCard(poll, index),
        );
      },
    );
  }

  Widget _buildModernPollCard(Poll poll, int index) {
    final userId = Provider.of<UserProvider>(context).user?.uid ?? '';
    final hasVoted = poll.hasVoted(userId);
    final isActive = poll.isActive;
    final showResults = _showResultsMap[poll.id] ?? false;
    
    // Get user's current vote if they've voted
    int? currentVote;
    if (hasVoted) {
      currentVote = poll.votes[userId];
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToDetails(poll),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poll title and description
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poll.question,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    poll.description.length > 100
                        ? '${poll.description.substring(0, 100)}...'
                        : poll.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Category badge if available
            if (poll.category.isNotEmpty && poll.category != 'General')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Chip(
                  label: Text(
                    poll.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            
            const SizedBox(height: 8),
            
            // Voting UI
            if (isActive && !hasVoted)
              _buildVoteButtons(poll)
            else
              _buildVoteStatus(poll, hasVoted, currentVote, showResults),
              
            // Divider
            const Divider(height: 1),
            
            // Footer with details and vote count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(
                      Icons.arrow_forward,
                      size: 16,
                    ),
                    label: const Text('View Details'),
                    onPressed: () => _navigateToDetails(poll),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.how_to_vote_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${poll.getTotalVotes()} ${poll.getTotalVotes() == 1 ? 'vote' : 'votes'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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
  
  Widget _buildVoteButtons(Poll poll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.thumb_up, color: Colors.white),
              label: const Text('Yes', style: TextStyle(color: Colors.white)),
              onPressed: () => _submitVote(poll, 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.thumb_down, color: Colors.white),
              label: const Text('No', style: TextStyle(color: Colors.white)),
              onPressed: () => _submitVote(poll, -1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVoteStatus(Poll poll, bool hasVoted, int? currentVote, bool showResults) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasVoted)
            Row(
              children: [
                Icon(
                  currentVote == 1 ? Icons.thumb_up : Icons.thumb_down,
                  size: 16,
                  color: currentVote == 1 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'You voted ${currentVote == 1 ? "Yes" : "No"}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: currentVote == 1 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            )
          else if (!poll.isActive)
            Text(
              'Poll closed',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            
          if (showResults) ...[
            const SizedBox(height: 16),
            _buildResultBar(
              label: 'Yes',
              percentage: poll.getYesPercentage(),
              count: poll.votes.values.where((v) => v == 1).length,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildResultBar(
              label: 'No',
              percentage: poll.getNoPercentage(),
              count: poll.votes.values.where((v) => v == -1).length,
              color: Colors.red,
            ),
          ],
          
          const SizedBox(height: 8),
          
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: Icon(
                showResults ? Icons.visibility_off : Icons.bar_chart,
                color: Colors.grey[700],
                size: 16,
              ),
              label: Text(
                showResults ? 'Hide Results' : 'View Results',
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
              onPressed: () => _toggleResults(poll.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBar({
    required String label,
    required double percentage,
    required int count,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Spacer(),
            Text(
              '$count ${count == 1 ? 'vote' : 'votes'} (${percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            // Background
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // Animated foreground
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              height: 12,
              width: (percentage / 100) * (MediaQuery.of(context).size.width - 40),
              decoration: BoxDecoration(
                color: color.withAlpha(204),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(77),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
} 