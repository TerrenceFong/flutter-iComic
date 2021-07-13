import 'package:flutter/material.dart';
import 'testFileImage.dart';
import 'detail.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/': (context) => HomeScreen(),
        // '/details': (context) => DetailScreen(),
        '/test-fileImage': (context) => TestFileImage(),
      },
      onGenerateRoute: (settings) {
        // Handle '/details/:id'
        var uri = Uri.parse(settings.name as String);
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'details') {
          var id = uri.pathSegments[1];
          return MaterialPageRoute(builder: (context) => DetailScreen(id: id));
        }
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('test detail'),
      ),
      body: Column(
        children: [
          Center(
            child: TextButton(
              child: Text('View Details'),
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) {
                //     return DetailScreen();
                //   }),
                // );
                Navigator.pushNamed(
                  context,
                  '/details/11',
                );
              },
            ),
          ),
          Center(
            child: TextButton(
              child: Text('View test FileImage'),
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) {
                //     return TestFileImage();
                //   }),
                // );
                Navigator.pushNamed(
                  context,
                  '/test-fileImage',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
