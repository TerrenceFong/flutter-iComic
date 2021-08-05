import 'dart:async';

import 'package:i_comic/comic/common/global.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteManager {
  /// sql 文件的名字
  static final sqlName = "comicTrans.db";

  /// 配置表名
  static final configTable = "config";

  /// 漫画数据表名
  static final comicTable = "comic";

  /// 翻译表名
  static final translationTable = "translation";

  Database? db;
  static SqfliteManager? _instance;

  /// 创建 config table
  /// id          固定为 1 ，全局只有一条配置
  /// accuration  翻译精度   高精度-0  标准-1
  /// nearTop     算法相邻顶部的值  default 5
  /// nearLeft    算法相邻左侧的值  default 7
  static String _createConfigTable = '''
    create table $configTable (
      id integer primary key,
      accuration integer not null,
      nearTop integer not null,
      nearLeft integer not null,
      reRenderPage integer not null
    )
  ''';

  /// 重建 config 表
  static Future<void> reCreateConfigTable(Database db) async {
    // 删除
    await db.execute('drop table $configTable');
    // 创建
    await db.execute(_createConfigTable);
  }

  /// 插入初始化的数据
  static Future<void> configTableInsertData(Database db) async {
    await db.insert(
      configTable,
      {
        'id': CONFIG_ID,
        'accuration': ACCURATION,
        'nearTop': NEAR_TOP,
        'nearLeft': NEAR_LEFT,
        'reRenderPage': RE_RENDER_PAGE,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 创建 comic table
  /// id
  /// comicName 漫画名
  /// chapter   章节
  /// imgPage   看到哪一页
  static String _createComicTable = '''
    create table $comicTable (
      id integer primary key,
      comicName text not null,
      chapter text not null,
      imgPage text not null
    )
  ''';

  /// 创建 translation table
  /// id
  /// comicName 漫画名
  /// chapter   章节
  /// imgName   当页路径
  /// words     当页翻译
  static String _createTranslationTable = '''
    create table $translationTable (
      id integer primary key,
      comicName text not null,
      chapter text not null,
      imgName text not null,
      words text not null
    )
  ''';

  static Future<SqfliteManager> getInstance() async {
    if (_instance == null) {
      _instance = await _initDataBase();
    }
    return _instance as SqfliteManager;
  }

  /// 打开 数据库 db
  static Future<SqfliteManager> _initDataBase() async {
    SqfliteManager manager = SqfliteManager();
    if (manager.db == null) {
      String dbPath = join(await getDatabasesPath(), sqlName);
      print("init sqlite");

      manager.db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          /// 首次初始化时
          /// 如果不存在当前的表, 就创建需要的表
          if (await manager.isTableExit(db, configTable) == false) {
            await db.execute(_createConfigTable);
            // 初始化配置数据
            await configTableInsertData(db);
          }
          if (await manager.isTableExit(db, comicTable) == false) {
            await db.execute(_createComicTable);
          }
          if (await manager.isTableExit(db, translationTable) == false) {
            await db.execute(_createTranslationTable);
          }
        },
        onOpen: (db) async {
          /// 后续每次首先打开时
          /// 如果不存在当前的表, 就创建需要的表
          if (await manager.isTableExit(db, configTable) == false) {
            await db.execute(_createConfigTable);
            // 初始化配置数据
            await configTableInsertData(db);
          }
          if (await manager.isTableExit(db, comicTable) == false) {
            await db.execute(_createComicTable);
          }
          if (await manager.isTableExit(db, translationTable) == false) {
            await db.execute(_createTranslationTable);
          }
        },
      );
    }
    return manager;
  }

  /// 插入数据
  Future<int> insert(String tableName, Map<String, dynamic> value,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    /// 因为原数据里面有 id 参数，先移除掉
    value.remove("id");

    /// 加断言的原因是会先获取 sqlite 的实例
    /// 如果没有的话会先获取 db
    /// 所以可以断言此时 db 已经初始化成功
    return await db!.insert(
      tableName,
      value,
      nullColumnHack: nullColumnHack,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  /// 查询数据
  Future<List<Map<String, dynamic>>> query(
    String tableName, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return await db!.query(
      tableName,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// 删除一条数据
  Future<int> delete(String tableName, int id) async {
    if (id == 0) {
      return 0;
    }
    return await db!.delete(tableName, where: "id = ?", whereArgs: [id]);
  }

  /// 自定义删除数据
  Future<int> customDelete(
    String tableName,
    String where,
    List<Object> whereArgs,
  ) async {
    return await db!.delete(
      tableName,
      where: where,
      whereArgs: whereArgs,
    );
  }

  /// 更新数据
  Future<int> update(
    String tableName,
    Map<String, dynamic> value,
    int id,
  ) async {
    return await db!.update(
      tableName,
      value,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  /// 判断是否存在 数据库表
  Future<bool> isTableExit(Database db, String tableName) async {
    List<Map<String, Object?>> result = await db.rawQuery(
        "select * from Sqlite_master where type = 'table' and name = '$tableName'");
    return result.length > 0;
  }
}
