import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todo_app_using_hive/models/todo.dart';
import 'package:todo_app_using_hive/screens/home_screen.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(TodoAdapter());

  await Hive.openBox('todo');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}
