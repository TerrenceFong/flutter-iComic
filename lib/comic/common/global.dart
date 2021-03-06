import 'package:i_comic/comic/utils/sqflite_db.dart';

/// 配置信息常量
const CONFIG_ID = 1;
const AUTOTRANS = 1;
const ACCURATION = 0;
const NEAR_TOP = 5;
const NEAR_LEFT = 7;
const RE_RENDER_PAGE = 4;

const List<String> transMap = ["有道", "百度-高精度", "百度-通用版"];

class Global {
  static late int autoTrans;
  static late int accuration;
  static late int nearTop;
  static late int nearLeft;
  static late int reRenderPage;
  static String bdTransAppId = '';
  static String bdTransAppKey = '';
  static String ydAppId = '';
  static String ydAppKey = '';
  static String bceApiKey = '';
  static String bceSecretKey = '';

  /// 百度 api 的 access-token
  static String bdAccessToken = '';

  // 初始化全局信息 在 home.dart 初始化时执行
  static Future<void> init() async {
    var db = await SqfliteManager.getInstance();
    var config = (await db.query(
      SqfliteManager.configTable,
      where: 'id = ?',
      whereArgs: [CONFIG_ID],
    ))[0];

    autoTrans = config['autoTrans'] ?? 1;
    accuration = config['accuration'];
    nearTop = config['nearTop'];
    nearLeft = config['nearLeft'];
    reRenderPage = config['reRenderPage'] ?? 4;
    bdTransAppId = config['bdTransAppId'] ?? '';
    bdTransAppKey = config['bdTransAppKey'] ?? '';
    ydAppId = config['ydAppId'] ?? '';
    ydAppKey = config['ydAppKey'] ?? '';
    bceApiKey = config['bceApiKey'] ?? '';
    bceSecretKey = config['bceSecretKey'] ?? '';
  }

  static void reset() {
    autoTrans = AUTOTRANS;
    accuration = ACCURATION;
    nearTop = NEAR_TOP;
    nearLeft = NEAR_LEFT;
    reRenderPage = RE_RENDER_PAGE;
    bdTransAppId = '';
    bdTransAppKey = '';
    ydAppId = '';
    ydAppKey = '';
    bceApiKey = '';
    bceSecretKey = '';
  }
}
