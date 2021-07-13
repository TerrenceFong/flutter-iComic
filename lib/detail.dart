import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  final String id;

  DetailScreen({
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('test pop'),
      ),
      body: Center(
        child: TextButton(
          child: Text('Viewing details for item $id'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
