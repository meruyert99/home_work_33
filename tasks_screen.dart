import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'task_model.dart';
import 'tasks_repository.dart';
import 'tasks_pager.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({
    super.key,
    required this.uid,
    required this.repo,
    required this.pager,
  });

  final String uid;
  final TasksRepository repo;
  final TasksPager pager;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _statusOptions = const ['', 'open', 'done'];
  final _categoryOptions = const ['', 'general', 'work', 'personal'];

  String _status = '';
  String _category = '';
  String _tag = '';

  @override
  void initState() {
    super.initState();
    widget.pager.addListener(_onPagerChanged);
  }

  @override
  void dispose() {
    widget.pager.removeListener(_onPagerChanged);
    super.dispose();
  }

  void _onPagerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openCreateDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String status = 'open';
    String category = 'general';
    final tagsCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая задача'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('open')),
                  DropdownMenuItem(value: 'done', child: Text('done')),
                ],
                onChanged: (v) => status = v ?? 'open',
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: category,
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('general')),
                  DropdownMenuItem(value: 'work', child: Text('work')),
                  DropdownMenuItem(value: 'personal', child: Text('personal')),
                ],
                onChanged: (v) => category = v ?? 'general',
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tagsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tags (через запятую)',
                  hintText: 'flutter, school',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );

    if (ok != true) return;

    final title = titleCtrl.text.trim();
    if (title.isEmpty) {
      _toast('Title не может быть пустым');
      return;
    }

    final tags = tagsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    try {
      await widget.repo.createTask(
        uid: widget.uid,
        title: title,
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        status: status,
        category: category,
        tags: tags,
      );
    } catch (e) {
      _toast('Не удалось создать: $e');
    }
  }

  Future<void> _openEditDialog(TaskModel t) async {
    final titleCtrl = TextEditingController(text: t.title);
    final descCtrl = TextEditingController(text: t.description ?? '');
    String status = t.status;
    String category = t.category;
    final tagsCtrl = TextEditingController(text: t.tags.join(', '));

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('open')),
                  DropdownMenuItem(value: 'done', child: Text('done')),
                ],
                onChanged: (v) => status = v ?? t.status,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: category,
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('general')),
                  DropdownMenuItem(value: 'work', child: Text('work')),
                  DropdownMenuItem(value: 'personal', child: Text('personal')),
                ],
                onChanged: (v) => category = v ?? t.category,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tagsCtrl,
                decoration: const InputDecoration(labelText: 'Tags (через запятую)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok != true) return;

    final newTitle = titleCtrl.text.trim();
    if (newTitle.isEmpty) {
      _toast('Title не может быть пустым');
      return;
    }

    final tags = tagsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    try {
      await widget.repo.updateTask(taskId: t.id, patch: {
        'title': newTitle,
        'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        'status': status,
        'category': category,
        'tags': tags,
      });
    } catch (e) {
      _toast('Не удалось сохранить: $e');
    }
  }

  Future<void> _deleteTask(TaskModel t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: Text('“${t.title}”'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await widget.repo.deleteTask(t.id);
    } catch (e) {
      _toast('Не удалось удалить: $e');
    }
  }

  void _applyFilters() {
    widget.pager.setFilters(
      status: _status,
      category: _category,
      tag: _tag.trim(),
    );
  }

  void _resetFilters() {
    setState(() {
      _status = '';
      _category = '';
      _tag = '';
    });
    widget.pager.setFilters(status: null, category: null, tag: null);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.pager.buildQuery();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks (Firestore)'),
        actions: [
          IconButton(
            tooltip: 'Сбросить фильтры',
            onPressed: _resetFilters,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // ФИЛЬТРЫ
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: _statusOptions
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.isEmpty ? 'any' : s),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _status = v ?? ''),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: _categoryOptions
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.isEmpty ? 'any' : c),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v ?? ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Tag (array-contains)',
                          hintText: 'flutter',
                        ),
                        onChanged: (v) => _tag = v,
                        controller: TextEditingController(text: _tag)
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: _tag.length),
                          ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _applyFilters,
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // СПИСОК
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Ошибка: ${snap.error}'));
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('Пусто: задач нет по текущим фильтрам'));
                }

                final tasks = docs.map(TaskModel.fromDoc).toList();

                return ListView.separated(
                  itemCount: tasks.length + 1,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    if (i == tasks.length) {
                      // "Load more"
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        child: OutlinedButton(
                          onPressed: widget.pager.loadMore,
                          child: Text('Загрузить ещё (+${TasksPager.pageSize}) • сейчас: ${widget.pager.limit}'),
                        ),
                      );
                    }

                    final t = tasks[i];
                    return ListTile(
                      title: Text(t.title),
                      subtitle: Text('${t.status} • ${t.category} • tags: ${t.tags.join(", ")}'),
                      onTap: () => _openEditDialog(t),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteTask(t),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
