Future<int> roll(int num, int delayMs) {
  return Future.delayed(Duration(milliseconds: delayMs), () {
    print("Roll. no. is $num");
    return num; // like resolve(num)
  });
}

Future<void> run() async {
  try {
    await roll(12212, 1000);
    print("wait its getting downloaded");

    await roll(12312, 2000);
    print("wait its getting downloaded");

    await roll(12412, 3000);
    print("wait its almost over");

    await roll(12512, 4000);
    print("Finished download flow");
  } catch (err) {
    print("Error: $err");
  } finally {
    print("Done with viva");
  }
}

Future<void> main() async {
  await run();
}
