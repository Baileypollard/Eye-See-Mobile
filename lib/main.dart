import 'package:eye_see_mobile/scanning_page.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eye See Mobile',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ScanningPage(),
    );
  }
}
