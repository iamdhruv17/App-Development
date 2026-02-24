// void main(){
//   print("Hello World");
// }

import 'dart:io';

void main(){
  // String a=stdin.readLineSync()!;
  // String?a;
  // a ??= "Dhruv";
  // print(a);

  // String ? s=stdin.readLineSync(); 

	print(""); 
  print("CASE 5");
	// CASE 5: Custom Exception
	try {
		depositMoney(-200);
	} catch (e) {
		print(e);
	} finally {
		// Code
	}
}

class DepositException implements Exception {
	String errorMessage() {
		return "You cannot enter amount less than 0";
	}

  String toString() {
    return errorMessage();
  } 
}

void depositMoney(int amount) {
	if (amount < 0) {
		throw new DepositException();
	}
}


