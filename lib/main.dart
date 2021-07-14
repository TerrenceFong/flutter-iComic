import 'package:flutter/material.dart';
import 'package:my_app/cart/common/theme.dart';
import 'package:my_app/cart/models/cart.dart';
import 'package:my_app/cart/models/catalog.dart';
import 'package:my_app/cart/screen/cart.dart';
import 'package:provider/provider.dart';
import 'cart/screen/catalog.dart';
import 'testFileImage.dart';
import 'detail.dart';
import 'cart/screen/login.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (context) => CatalogModel()),
        ChangeNotifierProxyProvider<CatalogModel, CartModel>(
          create: (context) => CartModel(),
          update: (context, catalog, cart) {
            if (cart == null) throw ArgumentError.notNull('cart');
            cart.catalog = catalog;
            return cart;
          },
        ),
      ],
      child: MaterialApp(
        theme: appTheme,
        routes: {
          '/': (context) => HomeScreen(),
          // '/details': (context) => DetailScreen(),
          '/test-fileImage': (context) => TestFileImage(),
          '/login': (context) => MyLogin(),
          '/cart': (context) => MyCart(),
          '/catalog': (context) => MyCatalog(),
        },
        onGenerateRoute: (settings) {
          // Handle '/details/:id'
          var uri = Uri.parse(settings.name as String);
          if (uri.pathSegments.length == 2 &&
              uri.pathSegments.first == 'details') {
            var id = uri.pathSegments[1];
            return MaterialPageRoute(
                builder: (context) => DetailScreen(id: id));
          }
        },
      ),
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
          Center(
            child: TextButton(
              child: Text('catalog'),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/catalog',
                );
              },
            ),
          ),
          Center(
            child: TextButton(
              child: Text('login'),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/login',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
