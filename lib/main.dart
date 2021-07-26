import 'package:flutter/material.dart';
import 'package:my_app/cart/common/theme.dart';
import 'package:my_app/cart/models/cart.dart';
import 'package:my_app/cart/models/catalog.dart';
import 'package:my_app/cart/screen/cart.dart';
import 'package:my_app/comic/models/comic.dart';
import 'package:my_app/photoHttp.dart';
import 'package:my_app/comic/screen/home.dart' as comic;
import 'package:my_app/comic/screen/imageList.dart' as imageList;
import 'package:provider/provider.dart';
import 'cart/screen/catalog.dart';
import 'testFileImage.dart' as TestFileImage;
import 'detail.dart';
import 'cart/screen/login.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (context) => CatalogModel()),
        ChangeNotifierProvider(create: (context) => ComicModel()),
        // Provider<ComicModel>(create: (context) => ComicModel()),
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
          '/': (context) => comic.Home(),
          // '/': (context) => HomeScreen(),
          // '/details': (context) => DetailScreen(),
          '/test-fileImage': (context) => TestFileImage.TestFileImage(),
          '/login': (context) => MyLogin(),
          '/cart': (context) => MyCart(),
          '/catalog': (context) => MyCatalog(),
          '/photoHttp': (context) => PhotoHttp()
        },
        onGenerateRoute: (settings) {
          var uri = Uri.parse(settings.name as String);
          // Handle '/details/:id'
          if (uri.pathSegments.length == 2 &&
              uri.pathSegments.first == 'details') {
            var id = uri.pathSegments[1];
            return MaterialPageRoute(
                builder: (context) => DetailScreen(id: id));
            // Handle '/imageList/:path'
          } else if (uri.pathSegments.length == 2 &&
              uri.pathSegments.first == 'imageList') {
            var path = uri.pathSegments[1];
            return MaterialPageRoute(
                builder: (context) => imageList.ImageList(path: path));
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
          Center(
            child: TextButton(
              child: Text('photoHttp'),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/photoHttp',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
