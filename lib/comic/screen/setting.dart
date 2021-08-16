import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:i_comic/comic/common/global.dart';
import 'package:i_comic/comic/utils/sqflite_db.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_material_pickers/flutter_material_pickers.dart';

class Setting extends StatefulWidget {
  const Setting({Key? key}) : super(key: key);

  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  int selectedTrans = ACCURATION;

  late TextEditingController _controllerTop;
  late TextEditingController _controllerLeft;
  late TextEditingController _controllerReRender;
  late TextEditingController _controllerConfig1;
  late TextEditingController _controllerConfig2;
  late TextEditingController _controllerConfig3;
  late TextEditingController _controllerConfig4;
  late TextEditingController _controllerConfig5;
  late TextEditingController _controllerConfig6;

  @override
  void initState() {
    selectedTrans = Global.accuration;
    _controllerTop = TextEditingController(text: Global.nearTop.toString());
    _controllerLeft = TextEditingController(text: Global.nearLeft.toString());
    _controllerReRender = TextEditingController(
      text: Global.reRenderPage.toString(),
    );
    _controllerConfig1 = TextEditingController(text: Global.bdTransAppId);
    _controllerConfig2 = TextEditingController(text: Global.bdTransAppKey);
    _controllerConfig3 = TextEditingController(text: Global.ydAppId);
    _controllerConfig4 = TextEditingController(text: Global.ydAppKey);
    _controllerConfig5 = TextEditingController(text: Global.bceApiKey);
    _controllerConfig6 = TextEditingController(text: Global.bceSecretKey);
    super.initState();
  }

  void setAccurate(String value) async {
    var db = await SqfliteManager.getInstance();
    int current = transMap.indexOf(value);

    await db.update(
      SqfliteManager.configTable,
      {
        'accuration': current,
      },
      CONFIG_ID,
    );

    setState(() {
      selectedTrans = current;
      Global.accuration = current;
    });
  }

  void setNearTop(String value) async {
    var db = await SqfliteManager.getInstance();
    var currentVal = int.parse(value);

    await db.update(
      SqfliteManager.configTable,
      {
        'nearTop': currentVal,
      },
      CONFIG_ID,
    );

    setState(() {
      Global.nearTop = currentVal;
    });
  }

  void setNearLeft(String value) async {
    var db = await SqfliteManager.getInstance();
    var currentVal = int.parse(value);

    await db.update(
      SqfliteManager.configTable,
      {
        'nearLeft': currentVal,
      },
      CONFIG_ID,
    );

    setState(() {
      Global.nearLeft = currentVal;
    });
  }

  void setReRender(String value) async {
    var db = await SqfliteManager.getInstance();
    var currentVal = int.parse(value);

    await db.update(
      SqfliteManager.configTable,
      {
        'reRenderPage': currentVal,
      },
      CONFIG_ID,
    );

    setState(() {
      Global.reRenderPage = currentVal;
    });
  }

  /// 设置 api 配置
  void setApiInput(String value, String key, {bool fill = false}) async {
    var db = await SqfliteManager.getInstance();

    await db.update(
      SqfliteManager.configTable,
      {
        '$key': value,
      },
      CONFIG_ID,
    );

    setState(() {
      if (key == 'bdTransAppId') {
        Global.bdTransAppId = value;
        if (fill) {
          _controllerConfig1 = TextEditingController(text: Global.bdTransAppId);
        }
      } else if (key == 'bdTransAppKey') {
        Global.bdTransAppKey = value;
        if (fill) {
          _controllerConfig2 =
              TextEditingController(text: Global.bdTransAppKey);
        }
      } else if (key == 'ydAppId') {
        Global.ydAppId = value;
        if (fill) {
          _controllerConfig3 = TextEditingController(text: Global.ydAppId);
        }
      } else if (key == 'ydAppKey') {
        Global.ydAppKey = value;
        if (fill) {
          _controllerConfig4 = TextEditingController(text: Global.ydAppKey);
        }
      } else if (key == 'bceApiKey') {
        Global.bceApiKey = value;
        if (fill) {
          _controllerConfig5 = TextEditingController(text: Global.bceApiKey);
        }
      } else if (key == 'bceSecretKey') {
        Global.bceSecretKey = value;
        if (fill) {
          _controllerConfig6 = TextEditingController(text: Global.bceSecretKey);
        }
      }
    });
  }

  void setConfigApi() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;

    File file = File(path + "/apiConfig.json");
    try {
      final contents = await file.readAsString();

      var jsonConfig = jsonDecode(contents);

      String bdTransAppId = jsonConfig['bdTransAppId'];
      String bdTransAppKey = jsonConfig['bdTransAppKey'];
      String ydAppId = jsonConfig['ydAppId'];
      String ydAppKey = jsonConfig['ydAppKey'];
      String bceApiKey = jsonConfig['bceApiKey'];
      String bceSecretKey = jsonConfig['bceSecretKey'];

      setApiInput(bdTransAppId, 'bdTransAppId', fill: true);
      setApiInput(bdTransAppKey, 'bdTransAppKey', fill: true);
      setApiInput(ydAppId, 'ydAppId', fill: true);
      setApiInput(ydAppKey, 'ydAppKey', fill: true);
      setApiInput(bceApiKey, 'bceApiKey', fill: true);
      setApiInput(bceSecretKey, 'bceSecretKey', fill: true);
    } catch (e) {
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('错误'),
          content: Text('读取 apiConfig.json 文件失败，请确保在存储根目录下有该配置文件: $e'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, '确认');
              },
              child: const Text('确认'),
            ),
          ],
        ),
      );
    }
  }

  void errorLogDialog() async {
    Future<List<String>> getInfo(String fileName) async {
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final filePath = path + "/" + fileName;

      File file = File(filePath);
      file = await file.create();

      final contents = await file.readAsString();
      var contentList = contents.split("@@split@@");
      contentList.removeAt(0);
      // 反转 优先展示最新数据
      return contentList.reversed.toList();
    }

    showDialog<String>(
      context: context,
      builder: (BuildContext context1) => Dialog(
        child: FutureBuilder<List<String>>(
          future: getInfo('errorInfo.txt'),
          builder: (context, AsyncSnapshot<List<String>> snapshot) {
            if (snapshot.hasData) {
              return Column(
                children: <Widget>[
                  ListTile(title: Text("错误信息")),
                  Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          title: Text(snapshot.data![index]),
                        );
                      },
                    ),
                  ),
                ],
              );
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }

  /// 还原默认配置
  void resetConfigDialog() {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('重置'),
        content: Text('是否还原默认配置?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context, '取消');
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              var db = await SqfliteManager.getInstance();
              await SqfliteManager.reCreateConfigTable(db.db!);
              await SqfliteManager.configTableInsertData(db.db!);
              Global.reset();
              resetSettingPage();

              Navigator.pop(context, '确认');
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  /// 还原 setting 页面的信息
  void resetSettingPage() {
    setState(() {
      selectedTrans = Global.accuration;
      _controllerTop.text = Global.nearTop.toString();
      _controllerLeft.text = Global.nearLeft.toString();
      _controllerReRender.text = Global.reRenderPage.toString();
      _controllerConfig1.text = Global.bdTransAppId;
      _controllerConfig2.text = Global.bdTransAppKey;
      _controllerConfig3.text = Global.ydAppId;
      _controllerConfig4.text = Global.ydAppKey;
      _controllerConfig5.text = Global.bceApiKey;
      _controllerConfig6.text = Global.bceSecretKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Setting',
          style: TextStyle(fontSize: 17),
        ),
        toolbarHeight: 44,
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text(
              '文字识别方式',
            ),
            onTap: () {
              showMaterialRadioPicker<String>(
                context: context,
                // title: 'Pick Your State',
                items: transMap,
                selectedItem: transMap[selectedTrans],
                onChanged: setAccurate,
              );
            },
            trailing: Text(transMap[selectedTrans]),
          ),
          ListTile(
            title: TextField(
              controller: _controllerTop,
              decoration: InputDecoration(labelText: "算法相邻顶部的值"),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
              onChanged: (String value) {
                setNearTop(value);
              },
            ),
          ),
          ListTile(
            title: TextField(
              controller: _controllerLeft,
              decoration: InputDecoration(labelText: "算法相邻左侧的值"),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
              onChanged: (String value) {
                setNearLeft(value);
              },
            ),
          ),
          ListTile(
            title: TextField(
              controller: _controllerReRender,
              decoration: InputDecoration(labelText: "预渲染页数"),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
              onChanged: (String value) {
                setReRender(value);
              },
            ),
          ),
          ListTile(
            title: TextField(
              controller: _controllerConfig1,
              decoration: InputDecoration(labelText: "百度翻译 AppId"),
              onChanged: (String value) {
                setApiInput(value, 'bdTransAppId');
              },
            ),
          ),
          ListTile(
            title: TextField(
              controller: _controllerConfig2,
              decoration: InputDecoration(labelText: "百度翻译 AppKey"),
              onChanged: (String value) {
                setApiInput(value, 'bdTransAppKey');
              },
            ),
          ),
          ListTile(
            title: TextField(
              controller: _controllerConfig3,
              decoration: InputDecoration(labelText: "有道智云 AppId"),
              onChanged: (String value) {
                setApiInput(value, 'ydAppId');
              },
            ),
          ),
          ListTile(
            title: TextField(
              controller: _controllerConfig4,
              decoration: InputDecoration(labelText: "有道智云 AppKey"),
              onChanged: (String value) {
                setApiInput(value, 'ydAppKey');
              },
            ),
          ),
          ListTile(
            title: TextField(
              controller: _controllerConfig5,
              decoration: InputDecoration(labelText: "百度智能云 ApiKey"),
              onChanged: (String value) {
                setApiInput(value, 'bceApiKey');
              },
            ),
          ),
          ListTile(
            title: TextField(
              controller: _controllerConfig6,
              decoration: InputDecoration(labelText: "百度智能云 SecretKey"),
              onChanged: (String value) {
                setApiInput(value, 'bceSecretKey');
              },
            ),
          ),
          ListTile(
            title: Text(
              '使用本地 apiConfig.json 设置上述密钥',
            ),
            trailing: IconButton(
              icon: Icon(Icons.assignment),
              onPressed: () {
                setConfigApi();
              },
            ),
          ),
          ListTile(
            title: Text(
              '查看错误信息',
            ),
            trailing: IconButton(
              icon: Icon(Icons.assignment),
              onPressed: () {
                errorLogDialog();
              },
            ),
          ),
          ListTile(
            title: Text(
              '初始化配置信息',
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                resetConfigDialog();
              },
            ),
          ),
        ],
      ),
    );
  }
}
