import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/comic/common/global.dart';
import 'package:my_app/comic/utils/sqflite_db.dart';
import 'package:my_app/comic/utils/utils.dart';

class Setting extends StatefulWidget {
  const Setting({Key? key}) : super(key: key);

  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  bool isAccurate = true;
  late TextEditingController _controllerTop;
  late TextEditingController _controllerLeft;

  @override
  void initState() {
    isAccurate = Global.accuration == 0 ? true : false;
    _controllerTop = TextEditingController(text: Global.nearTop.toString());
    _controllerLeft = TextEditingController(text: Global.nearLeft.toString());
    super.initState();
  }

  void setIsAccurate(bool value) async {
    var db = await SqfliteManager.getInstance();
    int current = value == true ? 0 : 1;
    await db.update(
      SqfliteManager.configTable,
      {
        'accuration': value == true ? 0 : 1,
      },
      CONFIG_ID,
    );

    setState(() {
      isAccurate = value;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setting'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text(
              '高精度识别',
            ),
            trailing: Switch(
              value: isAccurate,
              onChanged: (value) {
                setIsAccurate(value);
              },
            ),
          ),
          ListTile(
            title: TextField(
              controller: _controllerTop,
              decoration: InputDecoration(labelText: "算法相邻顶部的值"),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
              onSubmitted: (String value) {
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
              onSubmitted: (String value) {
                setNearLeft(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
