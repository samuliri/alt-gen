import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'alt_gen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIOverlays([]);
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AltGen',
      theme: ThemeData(
        brightness: Brightness.dark,
        canvasColor: Color(0xFF2D2F41),
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AltGen(),
    );
  }
}
