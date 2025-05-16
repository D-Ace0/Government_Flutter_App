import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:governmentapp/services/announcement/announcement_service.dart';
import 'package:governmentapp/widgets/my_text_field.dart';

class AnnouncementFeedPage extends StatelessWidget {
  const AnnouncementFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AnnouncementService(); // create instance of service

    return Scaffold(
      appBar: AppBar(title: const Text("Public Announcements")),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getAnnouncements(), // stream all announcements
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final announcements = snapshot.data!.docs;

          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final doc = announcements[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['title'] ?? '', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(data['description'] ?? ''),
                      if (data['attachmentUrl'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Image.network(data['attachmentUrl']),
                        ),
                      const Divider(),
                      _CommentSection(announcementId: doc.id),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CommentSection extends StatefulWidget {
  final String announcementId;
  const _CommentSection({required this.announcementId});

  @override
  State<_CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<_CommentSection> {
  final _controller = TextEditingController();
  bool _anonymous = false;
  final _service = AnnouncementService();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _service.getComments(widget.announcementId), // stream comments
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(data['text'] ?? ''),
                  subtitle: Text(data['senderId'] == 'anonymous' ? 'Anonymous' : data['senderEmail'] ?? ''),
                );
              }).toList(),
            );
          },
        ),
        Row(
          children: [
            Expanded(
              child: MyTextfield(
                controller: _controller,
                hintText: "Add a comment...",
                obSecure: false,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () async {
                if (_controller.text.trim().isNotEmpty) {
                  await _service.postComment(
                    announcementId: widget.announcementId,
                    text: _controller.text.trim(),
                    isAnonymous: _anonymous,
                  );
                  _controller.clear();
                }
              },
            )
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: _anonymous,
              onChanged: (val) => setState(() => _anonymous = val!),
            ),
            const Text("Post anonymously")
          ],
        )
      ],
    );
  }
}
