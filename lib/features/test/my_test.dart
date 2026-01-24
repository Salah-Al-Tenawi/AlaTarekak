import 'package:flutter/material.dart';
import 'package:alatarekak/core/utils/widgets/my_button.dart';

class MyTest extends StatefulWidget {
  const MyTest({super.key});

  @override
  State<MyTest> createState() => _MyTestState();
}

class _MyTestState extends State<MyTest> {
  // Position? myPosition;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: MyButton(
          onPressed: () async {
            // myPosition = await LocationService.getCurrentLocation();
            // if (myPosition != null) {
            //   print("myPosition!.accuracy========================");
            //   print(myPosition!.accuracy);
            //   print("myPosition!.altitude========================");
            //   print(myPosition!.altitude);
            // }
          },
          child: const Text("get My location"),
        ),
      ),
    );
  }
}
