import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'tasks_repository.dart';

class TasksPager extends ChangeNotifier {
  TasksPager({required this.uid, required this.repo});

  final String uid;
  final TasksRepository repo;

  static const int pageSize = 10;

  int _limit = pageSize;

  String? _status;   // open/done/null
  String? _category; // work/personal/general/null
  String? _tag;      // array-contains/null

  int get limit => _limit;
  String? get status => _status;
  String? get category => _category;
  String? get tag => _tag;

  void loadMore() {
    _limit += pageSize;
    notifyListeners();
  }

  void resetPagination() {
    _limit = pageSize;
    notifyListeners();
  }

  void setFilters({String? status, String? category, String? tag}) {
    _status = (status != null && status.isEmpty) ? null : status;
    _category = (category != null && category.isEmpty) ? null : category;
    _tag = (tag != null && tag.isEmpty) ? null : tag;
    _limit = pageSize; 
    notifyListeners();
  }

  Query<Map<String, dynamic>> buildQuery() {
    return repo.buildQuery(
      uid: uid,
      limit: _limit,
      status: _status,
      category: _category,
      tag: _tag,
    );
  }
}
