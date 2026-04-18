import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.amber, title: Text('Home')),
      body: Container(
        height: 100,
        width: 200,
        color: Colors.red,
        alignment: Alignment.center,
        child: Text('Hello World'),
      ),
    );
  }
}
