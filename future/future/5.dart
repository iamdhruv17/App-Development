import 'dart:async';
import 'dart:math';

final _rand = Random();

Future<String> placeOrder(String item, Duration delay) {
  return Future.delayed(delay, () {
    final orderId = "ORD${_rand.nextInt(10000)}";
    print("Order placed for: $item | orderId=$orderId");
    return orderId;
  });
}

Future<Map<String, String>> assignRider(String orderId, Duration delay) {
  return Future.delayed(delay, () {
    final riderId = "RID${_rand.nextInt(1000)}";
    print("Rider assigned for $orderId | riderId=$riderId");
    return {"orderId": orderId, "riderId": riderId};
  });
}

Future<Map<String, String>> pickupOrder(
  Map<String, String> data,
  Duration delay,
) {
  return Future.delayed(delay, () {
    print(
      "Order picked up | orderId=${data["orderId"]} riderId=${data["riderId"]}",
    );
    return data;
  });
}

Future<String> deliverOrder(Map<String, String> data, Duration delay) {
  return Future.delayed(delay, () {
    print("Order delivered | orderId=${data["orderId"]}");
    return "Delivered";
  });
}

Future<void> trackOrder() async {
  try {
    final orderId = await placeOrder("Pizza", Duration(seconds: 1));
    print("Order confirmed");

    final data = await assignRider(orderId, Duration(seconds: 2));
    print("Rider assigned");

    await pickupOrder(data, Duration(seconds: 2));
    print("On the way");

    final status = await deliverOrder(data, Duration(seconds: 3));
    print(status); // Delivered
  } catch (e) {
    print("Tracking error: $e");
  } finally {
    print("Tracking closed");
  }
}

Future<void> main() async {
  await trackOrder();
}
