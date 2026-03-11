Future<String> getName() {
  return Future.delayed(Duration(seconds: 2), () {
    return "AJ";
  });
}

Future<void> main() async {
  print("Start");

  try {
    final value = await getName(); // like then(...)
    print("Name is $value");
  } catch (e) {
    // like catchError(...)
    print("Error $e");
  } finally {
    // like whenComplete(...)
    print("Completed");
  }

  print("End");
}
