Future<String> getName() {
  return Future.delayed(Duration(seconds: 2), () {
    return "AJ";
  });
}

void main() {
  print("Start");
  getName()
      .then((value) {
        print("Name is $value");
      })
      .catchError((e) {
        print("Error $e");
      })
      .whenComplete(() {
        print("Completed");
      });
  print("End");
}
