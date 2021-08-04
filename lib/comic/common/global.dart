import 'package:my_app/comic/utils/sqflite_db.dart';
import 'package:my_app/comic/utils/utils.dart';

class Global {
  static int accuration = 0;
  static int nearTop = 5;
  static int nearLeft = 7;

  // 初始化全局信息 在 home.dart 初始化时执行
  static void init() async {
    var db = await SqfliteManager.getInstance();
    var config = (await db.query(
      SqfliteManager.configTable,
      where: 'id = ?',
      whereArgs: [CONFIG_ID],
    ))[0];

    accuration = config['accuration'];
    nearTop = config['nearTop'];
    nearLeft = config['nearLeft'];
  }
}
