import 'package:cloud_firestore/cloud_firestore.dart';

class TasksRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('tasks');

  Query<Map<String, dynamic>> baseQueryForUid(String uid) {
    return _col.where('uid', isEqualTo: uid).orderBy('createdAt', descending: true);
  }

  Query<Map<String, dynamic>> buildQuery({
    required String uid,
    required int limit,
    String? status,
    String? category,
    String? tag, 
  }) {
    Query<Map<String, dynamic>> q = baseQueryForUid(uid);

    if (status != null && status.isNotEmpty) {
      q = q.where('status', isEqualTo: status);
    }
    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }
    if (tag != null && tag.isNotEmpty) {
      q = q.where('tags', arrayContains: tag);
    }

    return q.limit(limit);
  }

  Future<void> createTask({
    required String uid,
    required String title,
    String? description,
    String status = 'open',
    String category = 'general',
    List<String> tags = const [],
  }) async {
    final now = FieldValue.serverTimestamp();
    await _col.add({
      'uid': uid,
      'title': title.trim(),
      'description': description?.trim(),
      'status': status,
      'category': category,
      'tags': tags.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> updateTask({
    required String taskId,
    required Map<String, dynamic> patch,
  }) async {
    patch['updatedAt'] = FieldValue.serverTimestamp();
    await _col.doc(taskId).update(patch);
  }

  Future<void> deleteTask(String taskId) async {
    await _col.doc(taskId).delete();
  }
}
