import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitness Pro',
      theme: ThemeData(
        fontFamily: 'Poppins',
      ),
      home: LandingScreen(),
    );
  }
}

// ================= LANDING PAGE =================
class LandingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5F2C82), Color(0xFF49A09D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, size: 120, color: Colors.white),
              SizedBox(height: 20),
              Text(
                "Fitness Pro",
                style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              SizedBox(height: 10),
              Text(
                "Transform Your Lifestyle",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  backgroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => HomeScreen()));
                },
                child: Text("Get Started",
                    style: TextStyle(color: Colors.black)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ================= HOME =================
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  final screens = [BMIScreen(), ActivityScreen(), TipsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text("Fitness Pro"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: screens[index],
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
              colors: [Color(0xFF5F2C82), Color(0xFF49A09D)]),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.monitor_weight), label: "BMI"),
            BottomNavigationBarItem(
                icon: Icon(Icons.directions_run), label: "Activity"),
            BottomNavigationBarItem(
                icon: Icon(Icons.lightbulb), label: "Tips"),
          ],
        ),
      ),
    );
  }
}

// ================= GLASS CARD =================
Widget glassCard({required Widget child}) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 10),
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: Colors.white.withOpacity(0.15),
      boxShadow: [
        BoxShadow(
          blurRadius: 10,
          color: Colors.black26,
          offset: Offset(0, 5),
        )
      ],
    ),
    child: child,
  );
}

// ================= BMI =================
class BMIScreen extends StatefulWidget {
  @override
  _BMIScreenState createState() => _BMIScreenState();
}

class _BMIScreenState extends State<BMIScreen> {
  final h = TextEditingController();
  final w = TextEditingController();
  String result = "";

  void calc() {
    double? height = double.tryParse(h.text);
    double? weight = double.tryParse(w.text);

    if (height == null || weight == null) {
      result = "Invalid Input";
    } else {
      double bmi = weight / ((height / 100) * (height / 100));
      result = "BMI: ${bmi.toStringAsFixed(2)}";
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
        ),
      ),
      child: Column(
        children: [
          glassCard(
            child: Column(
              children: [
                TextField(
                  controller: h,
                  decoration: InputDecoration(labelText: "Height (cm)"),
                ),
                TextField(
                  controller: w,
                  decoration: InputDecoration(labelText: "Weight (kg)"),
                ),
                SizedBox(height: 10),
                ElevatedButton(onPressed: calc, child: Text("Calculate")),
              ],
            ),
          ),
          glassCard(
            child: Text(result,
                style: TextStyle(fontSize: 22, color: Colors.white)),
          )
        ],
      ),
    );
  }
}

// ================= ACTIVITY =================
class ActivityScreen extends StatefulWidget {
  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<Map> list = [
    {"name": "Running", "done": false},
    {"name": "Walking", "done": false},
  ];

  void add() {
    TextEditingController c = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text("Add"),
              content: TextField(controller: c),
              actions: [
                TextButton(
                    onPressed: () {
                      setState(() {
                        list.add({"name": c.text, "done": false});
                      });
                      Navigator.pop(context);
                    },
                    child: Text("Add"))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient:
            LinearGradient(colors: [Color(0xFFFF512F), Color(0xFFDD2476)]),
      ),
      child: Column(
        children: [
          ElevatedButton(onPressed: add, child: Text("Add Activity")),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      list[i]["done"] = !list[i]["done"];
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.all(10),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: list[i]["done"]
                          ? Colors.greenAccent
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(list[i]["name"],
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// ================= TIPS =================
class TipsScreen extends StatelessWidget {
  final tips = ["Drink Water", "Exercise", "Sleep", "Healthy Diet"];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient:
            LinearGradient(colors: [Color(0xFF11998e), Color(0xFF38ef7d)]),
      ),
      child: GridView.builder(
        padding: EdgeInsets.all(15),
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemCount: tips.length,
        itemBuilder: (_, i) {
          return Hero(
            tag: tips[i],
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DetailScreen(tips[i])));
              },
              child: glassCard(
                child: Center(
                    child: Text(tips[i],
                        style:
                            TextStyle(color: Colors.white, fontSize: 18))),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================= DETAIL =================
class DetailScreen extends StatelessWidget {
  final String text;
  DetailScreen(this.text);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFF8360c3), Color(0xFF2ebf91)])),
        child: Center(
          child: Hero(
            tag: text,
            child: Material(
              color: Colors.transparent,
              child: Text(text,
                  style: TextStyle(fontSize: 30, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}