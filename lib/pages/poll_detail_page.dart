import 'package:flutter/material.dart';
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
  late Poll _poll;

  @override
  void initState() {
    super.initState();
    _poll = widget.poll;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitVote(int voteValue) async {
    if (_isSubmittingVote || !_poll.isActive) return;
    
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to vote')),
        );
      }
      return;
    }
    
    setState(() {
      _isSubmittingVote = true;
    });
    
    final hasVoted = _poll.hasVoted(userId);
    final message = hasVoted ? 'Your vote has been changed' : 'Your vote has been recorded';
    
    try {
      await _pollService.vote(_poll.id, userId, voteValue);
      
      if (mounted) {
        _animationController.forward();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
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
          const SnackBar(content: Text('You must be logged in to comment')),
        );
      }
      return;
    }
    
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
    final userId = Provider.of<UserProvider>(context).user?.uid ?? '';
    final hasVoted = _poll.hasVoted(userId);
    final isActive = _poll.isActive;
    int? userVote;
    
    if (hasVoted) {
      userVote = _poll.votes[userId];
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Poll Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poll header with category, title, and description
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _poll.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Poll title
                  Text(
                    _poll.question,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Poll description
                  Text(
                    _poll.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Poll metadata (dates and votes)
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Start date: ${DateFormat('MMM d, yyyy').format(_poll.startDate)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Icon(Icons.event, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'End date: ${DateFormat('MMM d, yyyy').format(_poll.endDate)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Icon(Icons.how_to_vote, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${_poll.getTotalVotes()} votes so far',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Results Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Results header with indicators
                  Row(
                    children: [
                      const Text(
                        'Results',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 16,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Poll Closed',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (hasVoted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: userVote == 1 ? Colors.green : Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                userVote == 1 ? Icons.check_circle : Icons.cancel,
                                size: 16,
                                color: userVote == 1 ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'You voted ${userVote == 1 ? 'Yes' : 'No'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: userVote == 1 ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Display results
                  _buildResultBar(
                    label: 'Yes',
                    percentage: _poll.getYesPercentage(),
                    count: _poll.votes.values.where((v) => v == 1).length,
                    color: Colors.green,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildResultBar(
                    label: 'No',
                    percentage: _poll.getNoPercentage(),
                    count: _poll.votes.values.where((v) => v == -1).length,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
            
            // Voting section - only show if poll is active
            if (isActive) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cast Your Vote',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Voting buttons for active polls where user hasn't voted
                    if (!hasVoted)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.thumb_up, color: Colors.white),
                              label: const Text('Vote Yes', style: TextStyle(color: Colors.white)),
                              onPressed: () => _submitVote(1),
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
                              label: const Text('Vote No', style: TextStyle(color: Colors.white)),
                              onPressed: () => _submitVote(-1),
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
                      )
                    else
                      // Change vote buttons for active polls where user has voted
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(
                                Icons.thumb_up,
                                color: userVote == 1 ? Colors.green : Colors.grey,
                              ),
                              label: Text(
                                'Change to Yes',
                                style: TextStyle(
                                  color: userVote == 1 ? Colors.green : Colors.grey[700],
                                ),
                              ),
                              onPressed: userVote == 1 ? null : () => _submitVote(1),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(
                                  color: userVote == 1 ? Colors.green : Colors.grey,
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
                                color: userVote == -1 ? Colors.red : Colors.grey,
                              ),
                              label: Text(
                                'Change to No',
                                style: TextStyle(
                                  color: userVote == -1 ? Colors.red : Colors.grey[700],
                                ),
                              ),
                              onPressed: userVote == -1 ? null : () => _submitVote(-1),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(
                                  color: userVote == -1 ? Colors.red : Colors.grey,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
            
            // Comments section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Comments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            
            // Comment input - only show if poll is active
            if (_poll.isActive)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Comment text field
                    TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 3,
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          // Anonymous checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _isAnonymousComment,
                                onChanged: (value) {
                                  setState(() {
                                    _isAnonymousComment = value ?? false;
                                  });
                                },
                              ),
                              const Text('Comment anonymously'),
                            ],
                          ),
                          const Spacer(),
                          // Submit button
                          ElevatedButton(
                            onPressed: _isSubmittingComment ? null : _submitComment,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
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
                                : const Text('Submit'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Text(
                      'Comments are closed for this poll',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Comments list
            ..._poll.comments.map((comment) => _buildCommentCard(comment)),
            
            // Add padding at bottom
            const SizedBox(height: 32),
          ],
        ),
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
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
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
              width: percentage * MediaQuery.of(context).size.width / 130,
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
  
  Widget _buildCommentCard(Comment comment) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final isCurrentUser = Provider.of<UserProvider>(context).user?.uid == comment.userId;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.grey[200] : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
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
                radius: 14,
                backgroundColor: comment.isAnonymous
                    ? Colors.grey
                    : Colors.primaries[comment.userId.hashCode % Colors.primaries.length],
                child: Text(
                  comment.isAnonymous ? 'A' : comment.userId.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                comment.isAnonymous ? 'Anonymous' : (isCurrentUser ? 'You' : 'User'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                dateFormat.format(comment.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Comment content
          Text(
            comment.content,
            style: TextStyle(
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
} 