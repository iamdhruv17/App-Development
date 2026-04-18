import 'package:flutter/material.dart';

class MyWidgett extends StatelessWidget {
  const MyWidgett({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text("ZOZOApp"),
          centerTitle: true,
          backgroundColor: Colors.purple,
          actions: [Icon(Icons.shopping_cart), Icon(Icons.search)],
          leading: Icon(Icons.menu),
        ),

        body: Text("Hello , My name is dhruv singhal amd i am nineteen year old ."),
      ),
    );
  }
}