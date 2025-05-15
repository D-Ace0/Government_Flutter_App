import 'package:cloud_firestore/cloud_firestore.dart';
import 'comment.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final DateTime publishDate;
  final DateTime? expiryDate;
  final String? recurringPattern;
  final DateTime? lastRecurrence;
  final String category;
  final List<String> attachments;
  final List<Comment> comments;
  final String authorId;
  final bool isUrgent;
  final bool isDraft;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.publishDate,
    this.expiryDate,
    this.recurringPattern,
    this.lastRecurrence,
    required this.category,
    required this.attachments,
    required this.comments,
    required this.authorId,
    required this.isUrgent,
    required this.isDraft,
  });

  bool get isPublished => DateTime.now().isAfter(publishDate) && !isDraft;
  bool get isExpired => expiryDate != null && DateTime.now().isAfter(expiryDate!);
  bool get isActive => isPublished && !isExpired;
  bool get isScheduled => DateTime.now().isBefore(publishDate) && !isDraft;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': Timestamp.fromDate(date),
      'publishDate': Timestamp.fromDate(publishDate),
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'recurringPattern': recurringPattern,
      'lastRecurrence': lastRecurrence != null ? Timestamp.fromDate(lastRecurrence!) : null,
      'category': category,
      'attachments': attachments,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'authorId': authorId,
      'isUrgent': isUrgent,
      'isDraft': isDraft,
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      publishDate: map['publishDate'] != null 
          ? (map['publishDate'] as Timestamp).toDate()
          : (map['date'] as Timestamp).toDate(),
      expiryDate: map['expiryDate'] != null 
          ? (map['expiryDate'] as Timestamp).toDate()
          : null,
      recurringPattern: map['recurringPattern'],
      lastRecurrence: map['lastRecurrence'] != null 
          ? (map['lastRecurrence'] as Timestamp).toDate() 
          : null,
      category: map['category'] ?? '',
      attachments: List<String>.from(map['attachments'] ?? []),
      comments: (map['comments'] as List<dynamic>?)
          ?.map((comment) => Comment.fromMap(comment))
          .toList() ?? [],
      authorId: map['authorId'] ?? '',
      isUrgent: map['isUrgent'] ?? false,
      isDraft: map['isDraft'] ?? false,
    );
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    DateTime? publishDate,
    DateTime? expiryDate,
    String? recurringPattern,
    DateTime? lastRecurrence,
    String? category,
    List<String>? attachments,
    List<Comment>? comments,
    String? authorId,
    bool? isUrgent,
    bool? isDraft,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      publishDate: publishDate ?? this.publishDate,
      expiryDate: expiryDate ?? this.expiryDate,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      lastRecurrence: lastRecurrence ?? this.lastRecurrence,
      category: category ?? this.category,
      attachments: attachments ?? this.attachments,
      comments: comments ?? this.comments,
      authorId: authorId ?? this.authorId,
      isUrgent: isUrgent ?? this.isUrgent,
      isDraft: isDraft ?? this.isDraft,
    );
  }
} 