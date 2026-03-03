import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'tasks_repository.dart';
import 'tasks_pager.dart';
import 'tasks_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();


  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }

  final uid = auth.currentUser!.uid;

  runApp(MyApp(uid: uid));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final repo = TasksRepository();
    final pager = TasksPager(uid: uid, repo: repo);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firestore CRUD',
      theme: ThemeData(useMaterial3: true),
      home: TasksScreen(uid: uid, repo: repo, pager: pager),
    );
  }
}
