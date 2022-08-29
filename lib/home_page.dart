import 'dart:io';
import 'dart:typed_data';

import 'package:cafe5_waiter_mobile_client/base_widget.dart';
import 'package:cafe5_waiter_mobile_client/class_car_model.dart';
import 'package:cafe5_waiter_mobile_client/class_dish.dart';
import 'package:cafe5_waiter_mobile_client/class_dishpart2.dart';
import 'package:cafe5_waiter_mobile_client/class_hall.dart';
import 'package:cafe5_waiter_mobile_client/class_menudish.dart';
import 'package:cafe5_waiter_mobile_client/class_table.dart';
import 'package:cafe5_waiter_mobile_client/config.dart';
import 'package:cafe5_waiter_mobile_client/db.dart';
import 'package:cafe5_waiter_mobile_client/client_socket.dart';
import 'package:cafe5_waiter_mobile_client/network_table.dart';
import 'package:cafe5_waiter_mobile_client/socket_message.dart';
import 'package:cafe5_waiter_mobile_client/translator.dart';
import 'package:cafe5_waiter_mobile_client/widget_halls.dart';
import 'package:flutter/material.dart';

class WidgetHome extends StatefulWidget {
  WidgetHome() {
    print("Create WidgetHome");
  }

  @override
  State<StatefulWidget> createState() {
    return WidgetHomeState();
  }
}

class WidgetHomeState extends BaseWidgetState with TickerProviderStateMixin {
  bool _dataLoading = false;
  String _progressString = "";
  late AnimationController animationController;
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    Config.setInt(key_protocol_version, 3);
    animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..addListener(() {
        setState(() {});
      });
    animationController.repeat(reverse: false);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (Config.getString(key_session_id).isNotEmpty) {
        SocketMessage m = SocketMessage.dllplugin(SocketMessage.op_login_pashhash);
        m.addString(Config.getString(key_session_id));
        sendSocketMessage(m);
      }
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  void handler(Uint8List data) async {
    _dataLoading = false;
    SocketMessage m = SocketMessage(messageId: 0, command: 0);
    m.setBuffer(data);
    if (!checkSocketMessage(m)) {
      return;
    }
    print("command ${m.command}");
    if (m.command == SocketMessage.c_dllplugin) {
      int op = m.getInt();
      int dllok = m.getByte();
      if (dllok == 0) {
        sd(m.getString());
        return;
      }
      switch (op) {
        case SocketMessage.op_login:
          Config.setString(key_session_id, m.getString());
          Config.setString(key_fullname, m.getString());
          if (Config.getBool(key_data_dont_update)) {
            _startWithoutDataLoad();
            return;
          }
          m = SocketMessage.dllplugin(SocketMessage.op_get_hall_list);
          sendSocketMessage(m);
          setState(() {
            _progressString = tr("Loading list of halls");
          });
          break;
        case SocketMessage.op_get_hall_list:
          NetworkTable nt = NetworkTable();
          nt.readFromSocketMessage(m);
          Db.delete("delete from halls");
          for (int i = 0; i < nt.rowCount; i++) {
            Db.insert("insert into halls (id, name, menuid, servicevalue) values (?,?,?,?)", [nt.getRawData(i, 0), nt.getRawData(i, 1), nt.getRawData(i, 2), nt.getRawData(i, 3)]);
          }
          setState(() {
            _progressString = tr("Loading list of tables");
          });
          m = SocketMessage.dllplugin(SocketMessage.op_get_table_list);
          sendSocketMessage(m);
          break;
        case SocketMessage.op_get_table_list:
          NetworkTable nt = NetworkTable();
          nt.readFromSocketMessage(m);
          Db.delete("delete from tables");
          for (int i = 0; i < nt.rowCount; i++) {
            Db.insert("insert into tables (id, hall, state, name, orderid, q) values (?,?,?,?,?,?)", [nt.getRawData(i, 0), nt.getRawData(i, 1), nt.getRawData(i, 2), nt.getRawData(i, 3), nt.getRawData(i, 4), i]);
          }
          setState(() {
            _progressString = tr("Loading list of dish part 1");
          });
          m = SocketMessage.dllplugin(SocketMessage.op_get_dish_part1_list);
          sendSocketMessage(m);
          break;
        case SocketMessage.op_get_dish_part1_list:
          NetworkTable nt = NetworkTable();
          nt.readFromSocketMessage(m);
          Db.delete("delete from dish_part1");
          for (int i = 0; i < nt.rowCount; i++) {
            Db.insert("insert into dish_part1 (id, name) values (?,?)", [nt.getRawData(i, 0), nt.getRawData(i, 1)]);
          }
          m = SocketMessage.dllplugin(SocketMessage.op_get_dish_part2_list);
          sendSocketMessage(m);
          setState(() {
            _progressString = tr("Loading list of dish part 2");
          });
          break;
        case SocketMessage.op_get_dish_part2_list:
          NetworkTable nt = NetworkTable();
          nt.readFromSocketMessage(m);
          Db.delete("delete from dish_part2");
          for (int i = 0; i < nt.rowCount; i++) {
            Db.insert("insert into dish_part2 (id, parentid, part1, textcolor, bgcolor, name, q) values (?,?,?,?,?,?,?)",
                [nt.getRawData(i, 0), nt.getRawData(i, 1), nt.getRawData(i, 2), nt.getRawData(i, 3), nt.getRawData(i, 4), nt.getRawData(i, 5), nt.getRawData(i, 6)]);
          }
          setState(() {
            _progressString = tr("Loading dishes");
          });
          m = SocketMessage.dllplugin(SocketMessage.op_get_dish_dish_list);
          sendSocketMessage(m);
          break;
        case SocketMessage.op_get_dish_dish_list:
          NetworkTable nt = NetworkTable();
          nt.readFromSocketMessage(m);
          Db.delete("delete from dish");
          for (int i = 0; i < nt.rowCount; i++) {
            Db.insert("insert into dish (id, part2, bgcolor, textcolor, name, q) values (?,?,?,?,?,?)",
                [nt.getRawData(i, 0), nt.getRawData(i, 1), nt.getRawData(i, 2), nt.getRawData(i, 3), nt.getRawData(i, 4), nt.getRawData(i, 5)]);
          }
          setState(() {
            _progressString = tr("Loading menu");
          });
          m = SocketMessage.dllplugin(SocketMessage.op_dish_menu);
          sendSocketMessage(m);
          break;
        case SocketMessage.op_dish_menu:
          NetworkTable nt = NetworkTable();
          nt.readFromSocketMessage(m);
          Db.delete("delete from dish_menu");
          for (int i = 0; i < nt.rowCount; i++) {
            Db.insert("insert into dish_menu (id, menuid, typeid, dishid, price, storeid, print1, print2) values (?,?,?,?,?,?,?,?)",
                [i + 1, nt.getRawData(i, 0), nt.getRawData(i, 1), nt.getRawData(i, 2), nt.getRawData(i, 3), nt.getRawData(i, 4), nt.getRawData(i, 5), nt.getRawData(i, 6)]);
          }
          setState(() {
            _progressString = tr("Loading car models");
          });
          m = SocketMessage.dllplugin(SocketMessage.op_car_model);
          sendSocketMessage(m);
          break;
        case SocketMessage.op_login_pashhash:
          if (Config.getBool(key_data_dont_update)) {
            _startWithoutDataLoad();
            return;
          }
          m = SocketMessage.dllplugin(SocketMessage.op_get_hall_list);
          sendSocketMessage(m);
          setState(() {
            _progressString = tr("Loading list of halls");
          });
          break;
        case SocketMessage.op_car_model:
          NetworkTable nt = NetworkTable();
          nt.readFromSocketMessage(m);
          Db.delete("delete from car_model");
          ClassCarModel.carModels.clear();
          for (int i = 0; i < nt.rowCount; i++) {
            Db.insert("insert into car_model (id, name) values (?,?)", [nt.getRawData(i, 0), nt.getRawData(i, 1)]);
          }

          Config.setBool(key_data_dont_update, true);
          _startWithoutDataLoad();
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Column(
                //mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Container(
              child: Align(
                  alignment: Alignment.center,
                  child: Container(
                      margin: EdgeInsets.only(top: 20, bottom: 20),
                      child: Text(
                        tr("Sign in"),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      )))),
          Align(
              alignment: Alignment.center,
              child: Container(
                  margin: EdgeInsets.only(top: 5),
                  width: 252,
                  decoration: BoxDecoration(border: Border.all(color: Colors.black38)),
                  child: Row(children: [
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Image.asset(
                        "images/user.png",
                        width: 40,
                        height: 40,
                      ),
                    ),
                    SizedBox(
                      height: 50,
                      width: 200,
                      child: TextFormField(
                        controller: _usernameController,
                        style: TextStyle(fontSize: 20),
                        decoration: InputDecoration(
                          hintText: tr("Username"),
                          hintStyle: TextStyle(color: Colors.black12),
                          border: InputBorder.none,
                        ),
                      ),
                    )
                  ]))),
          Align(
              alignment: Alignment.center,
              child: Container(
                  margin: EdgeInsets.only(top: 5),
                  width: 252,
                  decoration: BoxDecoration(border: Border.all(color: Colors.black38)),
                  child: Row(children: [
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Image.asset(
                        "images/lock.png",
                        width: 40,
                        height: 40,
                      ),
                    ),
                    SizedBox(
                      height: 50,
                      width: 200,
                      child: TextFormField(
                        obscureText: true,
                        controller: _passwordController,
                        style: TextStyle(fontSize: 20),
                        decoration: InputDecoration(
                          hintText: tr("********"),
                          hintStyle: TextStyle(color: Colors.black12),
                          border: InputBorder.none,
                        ),
                      ),
                    )
                  ]))),
          Align(
              alignment: Alignment.center,
              child: Container(
                  margin: EdgeInsets.only(top: 5),
                  width: 252,
                  height: 50,
                  child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                        backgroundColor: Colors.blueGrey,
                        side: BorderSide(
                          width: 1.0,
                          color: Colors.black38,
                          style: BorderStyle.solid,
                        ),
                      ),
                      onPressed: _login,
                      child: Text(tr("Login"), style: TextStyle(color: Colors.white))))),
          Align(
              child: Container(
                  margin: EdgeInsets.only(top: 5),
                  child: Visibility(
                      visible: _dataLoading,
                      child: CircularProgressIndicator(
                        value: animationController.value,
                      )))),
          Align(
            child: Container(margin: EdgeInsets.only(top: 5), child: Visibility(visible: _progressString.isNotEmpty, child: Text(_progressString))),
          )
        ])));
  }

  void _login() {
    if (_dataLoading) {
      return;
    }
    setState(() {
      _dataLoading = true;
      _progressString = "";
    });
    SocketMessage m = SocketMessage.dllplugin(SocketMessage.op_login);
    m.addString(_usernameController.text);
    m.addString(_passwordController.text);
    sendSocketMessage(m);
  }

  void _startWithoutDataLoad() async {
    if (ClassHall.list.isEmpty) {
      await Db.query("halls").then((map) {
        List.generate(map.length, (i) {
          ClassHall ch = ClassHall(id: map[i]["id"], name: map[i]["name"], menu: map[i]["menuid"], servicevalue: map[i]["servicevalue"]);
          ClassHall.list.add(ch);
        });
     });
    }
    if (ClassTable.list.isEmpty) {
      Db.query("tables", orderBy: "q").then((map) {
        List.generate(map.length, (i) {
          ClassTable ct = ClassTable(id: map[i]["id"], name: map[i]["name"], stateid: map[i]["state"], hallid: map[i]["hall"]);
          ClassTable.list.add(ct);
        });
        setState(() {});
      });
    }
    if (ClassCarModel.carModels.isEmpty) {
      await Db.query("car_model").then((map) {
        List.generate(map.length, (i) {
          ClassCarModel cm = ClassCarModel(id: map[i]["id"], name: map[i]["name"]);
          ClassCarModel.carModels.add(cm);
        });
      });
    }
    if (ClassDishPart2.list.isEmpty) {
      await Db.query("dish_part2", orderBy: "q").then((map) {
        List.generate(map.length, (i) {
          ClassDishPart2 cd = ClassDishPart2(map[i]["id"], map[i]["parentid"], map[i]["part1"], map[i]["name"]);
          cd.bgColor = Color(map[i]["bgcolor"]);
          cd.textColor = Color(map[i]["textcolor"]);
          ClassDishPart2.list.add(cd);
        });
      });
    }
    if (ClassDish.map.isEmpty) {
      await Db.query("dish").then((map) {
        List.generate(map.length, (i){
          ClassDish cd = ClassDish(map[i]["id"], map[i]["part2"], map[i]["name"]);
          cd.bgColor = Color(map[i]["bgcolor"]);
          cd.textColor = Color(map[i]["textcolor"]);
          ClassDish.map[cd.id] = cd;
        });
      });
    }
    if (ClassMenuDish.list.isEmpty) {
      await Db.query("dish_menu", orderBy: "id").then((map) {
        List.generate(map.length, (i) {
          ClassMenuDish cm = ClassMenuDish(map[i]["menuid"], map[i]["typeid"], map[i]["dishid"], map[i]["price"], map[i]["print1"], map[i]["print2"], map[i]["storeid"]);
          ClassMenuDish.list.add(cm);
        });
        ClassMenuDish.buildPart2();
      });
    }
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => WidgetHalls()), (route) => false);
  }
}
