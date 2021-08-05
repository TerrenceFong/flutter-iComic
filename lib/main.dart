import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_app/cart/common/theme.dart';
import 'package:my_app/cart/models/cart.dart';
import 'package:my_app/cart/models/catalog.dart';
import 'package:my_app/cart/screen/cart.dart';
import 'package:my_app/comic/models/comic.dart';
import 'package:my_app/photoHttp.dart';
import 'package:my_app/comic/screen/home.dart' as comic;
import 'package:my_app/comic/screen/chapterList.dart' as chapterList;
import 'package:my_app/comic/screen/imageList.dart' as imageList;
import 'package:my_app/comic/screen/previewList.dart' as previewList;
import 'package:my_app/comic/screen/setting.dart' as setting;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'cart/screen/catalog.dart';
import 'testFileImage.dart' as TestFileImage;
import 'detail.dart';
import 'cart/screen/login.dart';

void main() {
  Future<String> localPath() async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> getFile(String fileName) async {
    final path = await localPath();
    final filePath = path + "/" + fileName;

    File file = File(filePath);
    return await file.create();
  }

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      // 转发到zone
      Zone.current.handleUncaughtError(details.exception, details.stack!);
    };

    runApp(MyApp());
  }, (Object error, StackTrace stack) async {
    print('zone _handleError $error stack $stack');
    // 判断文件是否存在，不存在就创建一个
    File file = await getFile('errorInfo.txt');
    file.writeAsString(
      '''
\n
@@split@@
-----------------------------------
Date: ${DateTime.now()}
zone _handleError $error stack $stack
-----------------------------------
''',
      mode: FileMode.append,
    );
    // exit(1);
  });
}

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
          '/setting': (context) => setting.Setting(),
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

            // Handle '/chapterList/:path'
          } else if (uri.pathSegments.length == 2 &&
              uri.pathSegments.first == 'chapterList') {
            var path = uri.pathSegments[1];
            return MaterialPageRoute(
                builder: (context) => chapterList.ChapterList(comicPath: path));

            // Handle '/previewList/:comicPath/:chapterPath/'
          } else if (uri.pathSegments.length == 3 &&
              uri.pathSegments.first == 'previewList') {
            String path = '${uri.pathSegments[1]}/${uri.pathSegments[2]}';
            print(uri.pathSegments);
            return MaterialPageRoute(
              builder: (context) => previewList.PreviewList(
                path: path,
              ),
            );

            // Handle '/imageList/:comicPath/:chapterPath/:page'
          } else if (uri.pathSegments.length == 4 &&
              uri.pathSegments.first == 'imageList') {
            String path = '${uri.pathSegments[1]}/${uri.pathSegments[2]}';
            int page = int.parse(uri.pathSegments[3]);
            print(uri.pathSegments);
            return MaterialPageRoute(
              builder: (context) => imageList.ImageList(
                path: path,
                page: page,
              ),
            );
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
