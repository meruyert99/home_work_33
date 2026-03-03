import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  TaskModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.status,
    required this.category,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String uid;
  final String title;
  final String? description;
  final String status;  
  final String category; 
  final List<String> tags;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  static TaskModel fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return TaskModel(
      id: doc.id,
      uid: (d['uid'] ?? '') as String,
      title: (d['title'] ?? '') as String,
      description: d['description'] as String?,
      status: (d['status'] ?? 'open') as String,
      category: (d['category'] ?? 'general') as String,
      tags: ((d['tags'] ?? []) as List).map((e) => e.toString()).toList(),
      createdAt: d['createdAt'] as Timestamp?,
      updatedAt: d['updatedAt'] as Timestamp?,
    );
  }
}
