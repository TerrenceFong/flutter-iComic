import 'package:flutter/material.dart';

class MyLogin extends StatefulWidget {
  MyLogin({Key? key}) : super(key: key);

  @override
  _MyLogin createState() => _MyLogin();
}

class _MyLogin extends State<MyLogin> {
  final TextEditingController _controller1 = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome',
                style: Theme.of(context).textTheme.headline1,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Username',
                ),
                controller: _controller1,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Password',
                ),
                obscureText: true,
                controller: _controller2,
              ),
              const SizedBox(
                height: 24,
              ),
              ElevatedButton(
                child: const Text('ENTER'),
                onPressed: () {
                  print(_controller1.text);
                  print(_controller2.text);
                  Navigator.pushReplacementNamed(context, '/catalog');
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.yellow,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
