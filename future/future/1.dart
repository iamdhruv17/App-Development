void main() {
  print("1) Start");

  Future.delayed(Duration(seconds: 2000), () {
    print("2) After 2 seconds");
  });

  print("3) End");
}


// console.log("1) Start");

// setTimeout(() => {
//   console.log("2) After 2 seconds");
// }, 2000);

// console.log("3) End");