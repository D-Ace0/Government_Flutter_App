import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/poll.dart';
import '../models/comment.dart';
import '../services/poll/poll_service.dart';
import '../services/user/user_provider.dart';

class PollDetailPage extends StatefulWidget {
  final Poll poll;

  const PollDetailPage({
    super.key,
    required this.poll,
  });

  @override
  State<PollDetailPage> createState() => _PollDetailPageState();
}

class _PollDetailPageState extends State<PollDetailPage> with SingleTickerProviderStateMixin {
  final PollService _pollService = PollService();
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingVote = false;
  bool _isSubmittingComment = false;
  bool _isAnonymousComment = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Poll _poll;

  @override
  void initState() {
    super.initState();
    _poll = widget.poll;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitVote(int voteValue) async {
    if (_isSubmittingVote || !_poll.isActive) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.uid;
    final isGovernmentUser = userProvider.user?.isAdmin ?? false;
    
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to vote'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    // Prevent government users from voting
    if (isGovernmentUser) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Government users cannot vote on polls'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    // Give haptic feedback
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isSubmittingVote = true;
    });
    
    final hasVoted = _poll.hasVoted(userId);
    final message = hasVoted ? 'Your vote has been updated' : 'Your vote has been recorded';
    
    try {
      await _pollService.vote(_poll.id, userId, voteValue);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Reload the poll to get the updated votes
        final updatedPoll = await _pollService.getPoll(_poll.id);
        if (updatedPoll != null && mounted) {
          setState(() {
            _poll = updatedPoll;
          });
        }
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
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingVote = false;
        });
      }
    }
  }
  
  Future<void> _submitComment() async {
    if (_isSubmittingComment || !_poll.isActive) return;
    
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to comment'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    // Give haptic feedback
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isSubmittingComment = true;
    });
    
    try {
      await _pollService.addComment(
        _poll.id,
        userId,
        content,
        _isAnonymousComment,
      );
      
      if (mounted) {
        _commentController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your comment has been added'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Reload the poll to get the updated comments
        final updatedPoll = await _pollService.getPoll(_poll.id);
        if (updatedPoll != null && mounted) {
          setState(() {
            _poll = updatedPoll;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.user?.uid ?? '';
    final isGovernmentUser = userProvider.user?.isAdmin ?? false;
    final hasVoted = _poll.hasVoted(userId);
    final isActive = _poll.isActive;
    final theme = Theme.of(context);
    int? userVote;
    
    if (hasVoted) {
      userVote = _poll.votes[userId];
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Poll Details', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poll header card with all details
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category and status badges
                        Row(
                          children: [
                            // Category chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(26),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _poll.category,
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            
                            const Spacer(),
                            
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green.withAlpha(26) : Colors.grey.withAlpha(26),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isActive ? Icons.schedule : Icons.lock_outline,
                                    size: 14,
                                    color: isActive ? Colors.green.shade700 : Colors.grey[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isActive ? 'Active' : 'Closed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isActive ? Colors.green.shade700 : Colors.grey[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Poll title
                        Text(
                          _poll.question,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Poll description
                        Text(
                          _poll.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // Poll metadata
                        Row(
                          children: [
                            _buildInfoItem(
                              icon: Icons.calendar_today,
                              title: 'Start Date & Time',
                              value: DateFormat('MMM d, yyyy\nh:mm a').format(_poll.startDate),
                            ),
                            _buildInfoItem(
                              icon: Icons.event,
                              title: 'End Date & Time',
                              value: DateFormat('MMM d, yyyy\nh:mm a').format(_poll.endDate),
                            ),
                            _buildInfoItem(
                              icon: Icons.how_to_vote,
                              title: 'Total Votes',
                              value: _poll.getTotalVotes().toString(),
                            ),
                          ],
                        ),
                        
                        // User's vote indicator if voted
                        if (hasVoted) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: userVote == 1 ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: userVote == 1 ? Colors.green.shade200 : Colors.red.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  userVote == 1 ? Icons.check_circle : Icons.cancel,
                                  size: 18,
                                  color: userVote == 1 ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'You voted ${userVote == 1 ? 'Yes' : 'No'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: userVote == 1 ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Results Section Card
                Card(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Results header
                        const Row(
                          children: [
                            Icon(Icons.bar_chart, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Results',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Display results with animated bars
                        _buildResultBar(
                          label: 'Yes',
                          percentage: _poll.getYesPercentage(),
                          count: _poll.votes.values.where((v) => v == 1).length,
                          color: Colors.green.shade600,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildResultBar(
                          label: 'No',
                          percentage: _poll.getNoPercentage(),
                          count: _poll.votes.values.where((v) => v == -1).length,
                          color: Colors.red.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Voting section card - only show if poll is active and user is not government
                if (isActive && !isGovernmentUser)
                  Card(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    elevation: 2,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.how_to_vote, 
                                color: theme.colorScheme.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                hasVoted ? 'Change Your Vote' : 'Cast Your Vote',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Voting buttons based on current vote status
                          _isSubmittingVote 
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : !hasVoted
                              ? _buildInitialVotingButtons()
                              : _buildChangeVoteButtons(userVote),
                        ],
                      ),
                    ),
                  ),
                
                // Government user notice - show only if government user and poll is active
                if (isActive && isGovernmentUser)
                  Card(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    elevation: 2,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber[700],
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Government Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'As a government user, you cannot vote on polls. You can only view the results.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Comments section card
                Card(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Comments header
                        Row(
                          children: [
                            Icon(Icons.comment, 
                              color: theme.colorScheme.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Comments (${_poll.comments.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        
                        const Divider(height: 32),
                        
                        // Comment input - only show if poll is active
                        if (_poll.isActive)
                          _buildCommentInput(),
                        
                        // Comments list
                        if (_poll.comments.isNotEmpty)
                          ..._poll.comments.map((comment) => _buildCommentCard(comment))
                        else
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20, top: 10),
                            child: Center(
                              child: Text(
                                'No comments yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Add padding at bottom
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoItem({required IconData icon, required String title, required String value}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInitialVotingButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.thumb_up, color: Colors.white),
            label: const Text('Vote Yes', style: TextStyle(color: Colors.white)),
            onPressed: () => _submitVote(1),
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
            label: const Text('Vote No', style: TextStyle(color: Colors.white)),
            onPressed: () => _submitVote(-1),
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
    );
  }
  
  Widget _buildChangeVoteButtons(int? userVote) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: Icon(
              Icons.thumb_up,
              color: userVote == 1 ? Colors.green.shade600 : Colors.grey,
            ),
            label: Text(
              'Change to Yes',
              style: TextStyle(
                color: userVote == 1 ? Colors.green.shade600 : Colors.grey[700],
              ),
            ),
            onPressed: userVote == 1 ? null : () => _submitVote(1),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(
                color: userVote == 1 ? Colors.green.shade600 : Colors.grey.shade400,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: Icon(
              Icons.thumb_down,
              color: userVote == -1 ? Colors.red.shade600 : Colors.grey,
            ),
            label: Text(
              'Change to No',
              style: TextStyle(
                color: userVote == -1 ? Colors.red.shade600 : Colors.grey[700],
              ),
            ),
            onPressed: userVote == -1 ? null : () => _submitVote(-1),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(
                color: userVote == -1 ? Colors.red.shade600 : Colors.grey.shade400,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCommentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comment text field
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            hintText: 'Add a comment...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              // Anonymous checkbox
              Row(
                children: [
                  Transform.scale(
                    scale: 0.9,
                    child: Checkbox(
                      value: _isAnonymousComment,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _isAnonymousComment = value ?? false;
                        });
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Anonymous',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Submit button
              ElevatedButton(
                onPressed: _isSubmittingComment || _commentController.text.trim().isEmpty
                    ? null 
                    : _submitComment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 1,
                ),
                child: _isSubmittingComment
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Comment', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const Divider(),
      ],
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
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              '$count ${count == 1 ? 'vote' : 'votes'} (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: percentage),
              builder: (context, value, child) {
                return Container(
                  height: 12,
                  width: (value / 100) * (MediaQuery.of(context).size.width - 72),
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
                );
              },
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildCommentCard(Comment comment) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final isCurrentUser = Provider.of<UserProvider>(context).user?.uid == comment.userId;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment header with author and date
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: comment.isAnonymous
                    ? Colors.grey.shade400
                    : Theme.of(context).colorScheme.primary,
                child: Text(
                  comment.isAnonymous ? 'A' : (isCurrentUser ? 'Y' : comment.userId.substring(0, 1).toUpperCase()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.isAnonymous ? 'Anonymous' : (isCurrentUser ? 'You' : 'User'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    dateFormat.format(comment.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (isCurrentUser) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Your Comment',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // Comment content
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Text(
              comment.content,
              style: TextStyle(
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 