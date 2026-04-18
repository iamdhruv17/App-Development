import 'package:flutter/material.dart';

class civic extends StatelessWidget {
  const civic({super.key});

  @override
  Widget build(Object context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Container(
          color: Colors.red,
          width: 400,
          height: 400,
          alignment: Alignment.center,
          child: Text('Hello, World!', style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}