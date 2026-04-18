// import 'package:flutter/material.dart';

// class MyGrid extends StatelessWidget {
//   const MyGrid({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: Text("Grid View")),
//         body: GridView(
//           gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
//             maxCrossAxisExtent: 350,
//             crossAxisSpacing: 10,
//             mainAxisSpacing: 10,
//           ),
//           children: [
//             Container(color: Colors.red, child: Text("Hello")),
//             Container(color: Colors.blue, child: Text("World")),
//             Container(color: Colors.green, child: Text("Flutter")),
//             Container(color: Colors.yellow, child: Text("Grid")),
//             Container(color: Colors.red, child: Text("Hello")),
//             Container(color: Colors.blue, child: Text("World")),
//             Container(color: Colors.green, child: Text("Flutter")),
//             Container(color: Colors.yellow, child: Text("Grid")),
//             // Container(color: Colors.red, child: Text("Hello")),
//             // Container(color: Colors.blue, child: Text("World")),
//             // Container(color: Colors.green, child: Text("Flutter")),
//             // Container(color: Colors.yellow, child: Text("Grid")),
//             // Container(color: Colors.red, child: Text("Hello")),
//             // Container(color: Colors.blue, child: Text("World")),
//             // Container(color: Colors.green, child: Text("Flutter")),
//             // Container(color: Colors.yellow, child: Text("Grid")),
//             // Container(color: Colors.red, child: Text("Hello")),
//             // Container(color: Colors.blue, child: Text("World")),
//             // Container(color: Colors.green, child: Text("Flutter")),
//             // Container(color: Colors.yellow, child: Text("Grid")),
//             // Container(color: Colors.red, child: Text("Hello")),
//             // Container(color: Colors.blue, child: Text("World")),
//             // Container(color: Colors.green, child: Text("Flutter")),
//             // Container(color: Colors.yellow, child: Text("Grid")),
//             // Container(color: Colors.yellow, child: Text("Grid")),
//             // Container(color: Colors.red, child: Text("Hello")),
//             // Container(color: Colors.blue, child: Text("World")),
//             // Container(color: Colors.green, child: Text("Flutter")),
//             // Container(color: Colors.yellow, child: Text("Grid")),
//             // Container(color: Colors.red, child: Text("Hello")),
//             // Container(color: Colors.blue, child: Text("World")),
//             // Container(color: Colors.green, child: Text("Flutter")),
//             // Container(color: Colors.yellow, child: Text("Grid")),
//             // Container(color: Colors.red, child: Text("Hello")),
//             // Container(color: Colors.blue, child: Text("World")),
//             // Container(color: Colors.green, child: Text("Flutter")),
//             // Container(color: Colors.yellow, child: Text("Grid")),
//             // Container(color: Colors.yellow, child: Text("Grid")),
//             // Container(color: Colors.red, child: Text("Hello")),
//             // Container(color: Colors.blue, child: Text("World")),
//             // Container(color: Colors.green, child: Text("Flutter")),
//             // Container(color: Colors.yellow, child: Text("Grid")),
//             // Container(color: Colors.red, child: Text("Hello")),
//             // Container(color: Colors.blue, child: Text("World")),
//             // Container(color: Colors.green, child: Text("Flutter")),
//             // Container(color: Colors.yellow, child: Text("Grid")),
//             // Container(color: Colors.red, child: Text("Hello")),
//             // Container(color: Colors.blue, child: Text("World")),
//             // Container(color: Colors.green, child: Text("Flutter")),
//             // Container(color: Colors.yellow, child: Text("Grid")),
//           ],        ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class GridScreen extends StatefulWidget {
  const GridScreen({super.key});

  @override
  State<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> {
  final List<String> images = [
    'img/gemini.png',
    'img/gemini.png',
    'img/gemini.png',
    'img/gemini.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 54, 244, 101),
        title: const Text('Home'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Image.asset(images[index], fit: BoxFit.cover);
        },
      ),
    );
  }
}