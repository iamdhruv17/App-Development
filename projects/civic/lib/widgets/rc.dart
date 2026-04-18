import 'package:flutter/material.dart';

class MyRC extends StatelessWidget {
  const MyRC({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:Scaffold(
        appBar: AppBar(),
        body: Column(
        spacing: 20,
        children: [
          Text("How are you CSA"),
          Text("How are you CSB"),
          Text("How are you CSc"),
          Text("How are you CSd"),
        ],
        ),
      ),
    );
  }
}