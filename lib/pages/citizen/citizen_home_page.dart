import 'package:flutter/material.dart';
import 'package:governmentapp/models/announcement.dart';
import 'package:governmentapp/models/poll.dart';
import 'package:governmentapp/models/message.dart';
import 'package:governmentapp/models/advertisement.dart';
import 'package:governmentapp/services/announcement/announcement_service.dart';
import 'package:governmentapp/services/poll/poll_service.dart';
import 'package:governmentapp/services/chat/chat_service.dart';
import 'package:governmentapp/services/advertisement/adv_service.dart';
import 'package:governmentapp/services/user/route_guard_wrapper.dart';
import 'package:governmentapp/widgets/my_bottom_navigation_bar.dart';
import 'package:governmentapp/widgets/my_drawer.dart';
import 'package:governmentapp/widgets/my_advertisement_tile.dart';
import 'package:governmentapp/utils/logger.dart';
import 'package:intl/intl.dart';

class CitizenHomePage extends StatefulWidget {
  const CitizenHomePage({super.key});

  @override
  State<CitizenHomePage> createState() => _CitizenHomePageState();
}

class _CitizenHomePageState extends State<CitizenHomePage> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  
  // Services
  final AnnouncementService _announcementService = AnnouncementService();
  final PollService _pollService = PollService();
  final ChatService _chatService = ChatService();
  final AdvService _advertisementService = AdvService();
  
  // Data
  List<Announcement> _recentAnnouncements = [];
  List<Poll> _recentPolls = [];
  List<Message> _recentMessages = [];
  List<Advertisement> _recentAdvertisements = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load recent announcements
      final announcements = await _announcementService.getAnnouncements();
      // Load active polls
      final polls = await _pollService.getActivePolls();
      // Load messages
      final messages = await _getRecentMessages();
      // Load advertisements
      final advertisementsSnapshot = await _advertisementService.getApprovedAdvertisements().first;
      final advertisements = advertisementsSnapshot.docs
          .map((doc) => Advertisement.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      if (mounted) {
        setState(() {
          // Sort by date and take most recent
          _recentAnnouncements = announcements
            ..sort((a, b) => b.date.compareTo(a.date));
          if (_recentAnnouncements.length > 3) {
            _recentAnnouncements = _recentAnnouncements.sublist(0, 3);
          }
          
          // Sort polls by end date (closest to end first)
          _recentPolls = polls
            ..sort((a, b) => a.endDate.compareTo(b.endDate));
          if (_recentPolls.length > 3) {
            _recentPolls = _recentPolls.sublist(0, 3);
          }
          
          // Sort messages by timestamp
          _recentMessages = messages;
          
          // Take most recent advertisements (already sorted by timestamp in the query)
          _recentAdvertisements = advertisements;
          if (_recentAdvertisements.length > 3) {
            _recentAdvertisements = _recentAdvertisements.sublist(0, 3);
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.e('Error loading home page data', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Get recent messages for the current user
  Future<List<Message>> _getRecentMessages() async {
    final List<Message> recentMessages = [];
    
    try {
      // Get all chat rooms for the current user
      final chatRoomsSnapshot = await _chatService.getUserChatRooms().first;
      
      // For each chat room, get the latest message
      for (var chatRoom in chatRoomsSnapshot.docs) {
        final String chatRoomId = chatRoom.id;
        
        // Get latest message
        final latestMessageSnapshot = await _chatService
            .getLatestMessageForChatRoom(chatRoomId)
            .first;
        
        if (latestMessageSnapshot.docs.isNotEmpty) {
          final messageData = latestMessageSnapshot.docs.first.data() as Map<String, dynamic>;
          
          // Create message object
          final message = Message(
            messageData['subject'],
            senderId: messageData['senderId'],
            receiverId: messageData['receiverId'],
            senderEmail: messageData['senderEmail'],
            message: messageData['message'],
            timestamp: messageData['timestamp'],
          );
          
          recentMessages.add(message);
        }
      }
      
      // Sort by timestamp (most recent first) and limit to 3
      recentMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return recentMessages.take(3).toList();
    } catch (e) {
      AppLogger.e('Error fetching recent messages', e);
      return [];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the appropriate page when a tab is clicked
    if (index == 0) {
      // Home tab
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      // Announcements tab
      Navigator.pushReplacementNamed(context, '/citizen_announcements');
    } else if (index == 2) {
      // Polls tab
      Navigator.pushReplacementNamed(context, '/citizen_polls');
    } else if (index == 3) {
      // Report tab
      Navigator.pushReplacementNamed(context, '/citizen_report');
    } else if (index == 4) {
      // Messages tab
      Navigator.pushReplacementNamed(context, '/citizen_message');
    }
  }

  void _navigateToSection(String route) {
    AppLogger.d('Navigating to $route');
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return RouteGuardWrapper(
      allowedRoles: const ['citizen'],
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Government Portal"),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 0,
        ),
        drawer: MyDrawer(role: 'citizen'),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to the Citizen Portal',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Access government services and stay informed',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer.withAlpha(204),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Section header
                        Text(
                          'Quick Actions',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        
                        // Services grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.3,
                          children: [
                            _buildServiceCard(
                              context,
                              title: 'Announcements',
                              icon: Icons.campaign_outlined,
                              color: const Color(0xFF1A4480),
                              onTap: () => _navigateToSection('/citizen_announcements'),
                            ),
                            _buildServiceCard(
                              context,
                              title: 'Polls & Voting',
                              icon: Icons.how_to_vote_outlined,
                              color: const Color(0xFF2E8540),
                              onTap: () => _navigateToSection('/citizen_polls'),
                            ),
                            _buildServiceCard(
                              context,
                              title: 'Messages',
                              icon: Icons.message_outlined,
                              color: const Color(0xFF02BFE7),
                              onTap: () => _navigateToSection('/citizen_message'),
                            ),
                            _buildServiceCard(
                              context,
                              title: 'Profile',
                              icon: Icons.person_outline,
                              color: const Color(0xFF8A3FFC),
                              onTap: () => _navigateToSection('/profile'),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Recent advertisements section
                        Text(
                          'Advertisements',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder(
                          stream: _advertisementService.getApprovedAdvertisements(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: \\${snapshot.error}'));
                            }
                            final advertisements = snapshot.data?.docs
                                .map((doc) => Advertisement.fromMap(doc.data() as Map<String, dynamic>))
                                .toList() ?? [];
                            if (advertisements.isEmpty) {
                              return const Center(child: Text('No advertisements available'));
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: advertisements.length,
                              itemBuilder: (context, index) {
                                final advertisement = advertisements[index];
                                return MyAdvertisementTile(
                                  advertisement: advertisement,
                                  onPressedEdit: null,
                                  onPressedDelete: null,
                                  showActions: false,
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Recent activity section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Activity',
                              style: theme.textTheme.titleLarge,
                            ),
                            if (_recentAnnouncements.isEmpty && _recentPolls.isEmpty && _recentMessages.isEmpty)
                              const SizedBox.shrink()
                            else
                              TextButton(
                                onPressed: _loadData,
                                child: const Text('Refresh'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // If there are no recent activities
                        if (_recentAnnouncements.isEmpty && _recentPolls.isEmpty && _recentMessages.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No recent activity',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Check back later for updates',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Recent announcements
                        ..._recentAnnouncements.map((announcement) => 
                          _buildActivityItem(
                            context,
                            title: 'Announcement: ${announcement.title}',
                            description: announcement.content.length > 60 
                                ? '${announcement.content.substring(0, 60)}...' 
                                : announcement.content,
                            time: _formatTimeAgo(announcement.date),
                            icon: Icons.campaign_outlined,
                            onTap: () => _navigateToSection('/citizen_announcements'),
                          ),
                        ),
                        
                        // Recent polls
                        ..._recentPolls.map((poll) => 
                          _buildActivityItem(
                            context,
                            title: 'Poll: ${poll.question}',
                            description: _getRemainingTime(poll.endDate),
                            time: 'Ends on ${DateFormat('MMM d, yyyy').format(poll.endDate)}',
                            icon: Icons.how_to_vote_outlined,
                            onTap: () => _navigateToSection('/citizen_polls'),
                          ),
                        ),
                        
                        // Recent messages
                        ..._recentMessages.map((message) => 
                          _buildActivityItem(
                            context,
                            title: 'Message: ${message.subject}',
                            description: message.message.length > 60 
                                ? '${message.message.substring(0, 60)}...' 
                                : message.message,
                            time: _formatTimeAgo(message.timestamp.toDate()),
                            icon: Icons.message_outlined,
                            onTap: () => _navigateToSection('/citizen_message'),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),
        ),
        bottomNavigationBar: MyBottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
  
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
  
  String _getRemainingTime(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);
    
    if (difference.isNegative) {
      return 'Poll has ended';
    } else if (difference.inDays > 0) {
      return 'Closing in ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
    } else if (difference.inHours > 0) {
      return 'Closing in ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'}';
    } else {
      return 'Closing soon';
    }
  }
  
  Widget _buildServiceCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActivityItem(
    BuildContext context, {
    required String title,
    required String description,
    required String time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(128),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
