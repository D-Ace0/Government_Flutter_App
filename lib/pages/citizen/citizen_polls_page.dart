import 'package:flutter/material.dart';
import 'package:governmentapp/models/poll.dart';
import 'package:governmentapp/pages/poll_detail_page.dart';
import 'package:governmentapp/services/poll/poll_service.dart';
import 'package:governmentapp/services/notification/notification_service.dart';
import 'package:governmentapp/services/user/route_guard_wrapper.dart';
import 'package:governmentapp/services/user/user_provider.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/widgets/my_drawer.dart';
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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  final Map<String, bool> _showResultsMap = {};
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
    _tabController = TabController(length: 2, vsync: this);
    _loadPolls();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPolls() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Rather than using getPolls, get specific poll types to avoid query issues
      List<Poll> polls = [];
      
      if (_filter == 'Active') {
        polls = await _pollService.getActivePolls();
      } else {
        polls = await _pollService.getEndedPolls();
      }
      
      // Check for new polls and show notifications using the context
      _notificationService.checkForNewPolls(polls, _lastCheckTime, context);
      
      // Update last check time to now
      _lastCheckTime = DateTime.now();
      
      if (mounted) {
        setState(() {
          _filteredPolls = polls;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Check if the error is related to Firestore indexes
        String errorMessage = 'Error loading polls: $e';
        if (e.toString().contains('failed-precondition') && 
            e.toString().contains('index')) {
          errorMessage = 'Database error: An index is required. Please contact the administrator.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
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
    
    final hasVoted = poll.hasVoted(userId);
    final message = hasVoted ? 'Your vote has been changed' : 'Your vote has been recorded';
    
    try {
      await _pollService.vote(poll.id, userId, voteValue);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
      _loadPolls();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleResults(String pollId) {
    setState(() {
      _showResultsMap[pollId] = !(_showResultsMap[pollId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RouteGuardWrapper(
      allowedRoles: const ['citizen'],
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Public Polls', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            onTap: (index) {
              setState(() {
                _filter = index == 0 ? 'Active' : 'Previous';
              });
              _loadPolls(); // Reload polls with new filter
            },
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Previous'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: Colors.white, width: 3),
              insets: EdgeInsets.symmetric(horizontal: 16),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        drawer: MyDrawer(role: 'citizen'),
        body: RefreshIndicator(
          onRefresh: _loadPolls,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredPolls.isEmpty
                  ? _buildEmptyState()
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredPolls.length,
                        itemBuilder: (context, index) {
                          final poll = _filteredPolls[index];
                          return _buildSimplePollCard(poll);
                        },
                      ),
                    ),
        ),
        bottomNavigationBar: MyBottomNavigationBar(
          currentIndex: 2,  // Polls tab
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
              Icons.poll_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No polls found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _filter != 'Active'
                  ? 'No previous polls available'
                  : 'Check back later for new polls',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplePollCard(Poll poll) {
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
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poll title
                Text(
                  poll.question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Poll description
                Text(
                  poll.description.length > 100
                      ? '${poll.description.substring(0, 100)}...'
                      : poll.description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Voting buttons for active polls
          if (isActive) ...[
            if (!hasVoted)
              // First-time voting buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.thumb_up, color: Colors.white),
                        label: const Text('Yes', style: TextStyle(color: Colors.white)),
                        onPressed: () => _submitVote(poll, 1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
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
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Simplified vote status UI - no Change Vote button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            fontStyle: FontStyle.italic,
                            color: currentVote == 1 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (showResults) ...[
                      const SizedBox(height: 12),
                      _buildResultBar(
                        label: 'Yes',
                        percentage: poll.getYesPercentage(),
                        count: poll.votes.values.where((v) => v == 1).length,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildResultBar(
                        label: 'No',
                        percentage: poll.getNoPercentage(),
                        count: poll.votes.values.where((v) => v == -1).length,
                        color: Colors.red,
                      ),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: Icon(
                            showResults ? Icons.visibility_off : Icons.bar_chart,
                            color: Colors.grey[600],
                            size: 16,
                          ),
                          label: Text(
                            showResults ? 'Hide Results' : 'View Results',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          onPressed: () => _toggleResults(poll.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ] else
            // Closed polls UI
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasVoted 
                            ? 'You have voted on this poll' 
                            : 'This poll is closed',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(
                          showResults ? Icons.visibility_off : Icons.bar_chart,
                          color: Colors.grey[600],
                        ),
                        label: Text(
                          showResults ? 'Hide Results' : 'View Results',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        onPressed: () => _toggleResults(poll.id),
                      ),
                    ],
                  ),
                ),
                // Display results if toggled
                if (showResults)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        _buildResultBar(
                          label: 'Yes',
                          percentage: poll.getYesPercentage(),
                          count: poll.votes.values.where((v) => v == 1).length,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 8),
                        _buildResultBar(
                          label: 'No',
                          percentage: poll.getNoPercentage(),
                          count: poll.votes.values.where((v) => v == -1).length,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          
          // Footer row with View Details instead of Comments
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                TextButton.icon(
                  icon: const Icon(
                    Icons.arrow_forward,
                    size: 16,
                  ),
                  label: const Text('View Details'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PollDetailPage(poll: poll),
                      ),
                    ).then((_) => _loadPolls());
                  },
                ),
                const Spacer(),
                Icon(
                  Icons.how_to_vote_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${poll.getTotalVotes()} votes',
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
              '$count votes (${percentage.toStringAsFixed(1)}%)',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            // Background
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // Foreground
            Container(
              height: 16,
              width: percentage * MediaQuery.of(context).size.width / 130, // Adjusted to fit better in card
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/citizen_announcements');
    } else if (index == 2) {
      // Already on Polls page
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/citizen_report');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/citizen_message');
    }
  }
} 