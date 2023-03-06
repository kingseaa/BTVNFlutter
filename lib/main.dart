import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_btvn/firebase_options.dart';

import 'BTVN/students.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove the debug banner
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
          textTheme: Theme.of(context).textTheme.apply(
                fontSizeFactor: 1.2,
              ),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: Color.fromARGB(255, 86, 85, 85),
          )),
      title: 'Flutter connect to Firebasee',
      home: StudentsView(),
    );
  }
}
