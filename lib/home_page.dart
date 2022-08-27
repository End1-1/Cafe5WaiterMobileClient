import 'dart:io';
import 'dart:typed_data';

import 'package:cafe5_waiter_mobile_client/base_widget.dart';
import 'package:cafe5_waiter_mobile_client/class_car_model.dart';
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
        SocketMessage m = SocketMessage(messageId: SocketMessage.messageNumber(), command: SocketMessage.c_dllplugin);
        m.addString(SocketMessage.waiterclientp);
        m.addInt(SocketMessage.op_login_pashhash);
        m.addByte(3);
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
          m = SocketMessage(messageId: SocketMessage.messageNumber(), command: SocketMessage.c_dllop);
          m.addString("waiterclient");
          m.addInt(SocketMessage.op_get_hall_list);
          m.addString(Config.getString(key_database_name));
          m.addByte(3);
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
            Db.insert("insert into halls (id, name, menuid, servicevalue) values (?,?,?,?)", [
              nt.getRawData(i, 0), nt.getRawData(i, 1), nt.getRawData(i, 2), nt.getRawData(i, 3)
            ]);
          }
          setState(() {
            _progressString = tr("Loading list of tables");
          });
          m = SocketMessage(messageId: SocketMessage.messageNumber(), command: SocketMessage.c_dllop);
          m.addString("waiterclient");
          m.addInt(SocketMessage.op_get_table_list);
          m.addString(Config.getString(key_database_name));
          m.addByte(3);
          sendSocketMessage(m);
          break;
        case SocketMessage.op_get_table_list:
          NetworkTable nt = NetworkTable();
          nt.readFromSocketMessage(m);
          Db.delete("delete from tables");
          for (int i = 0; i < nt.rowCount; i++) {
            Db.insert("insert into tables (id, hall, state, name, orderid, q) values (?,?,?,?,?,?)", [
              nt.getRawData(i, 0), nt.getRawData(i, 1), nt.getRawData(i, 2), nt.getRawData(i, 3), nt.getRawData(i, 3), i
            ]);
          }
          setState(() {
            _progressString = tr("Loading list of dish part 1");
          });
          m = SocketMessage(messageId: SocketMessage.messageNumber(), command: SocketMessage.c_dllop);
          m.addString("waiterclient");
          m.addInt(SocketMessage.op_get_dish_part1_list);
          m.addString(Config.getString(key_database_name));
          m.addByte(3);
          sendSocketMessage(m);
          break;
        case SocketMessage.op_get_dish_part1_list:
          NetworkTable nt = NetworkTable();
          nt.readFromSocketMessage(m);
          Db.delete("delete from dish_part1");
          for (int i = 0; i < nt.rowCount; i++) {
            Db.insert("insert into dish_part1 (id, name) values (?,?)", [
              nt.getRawData(i, 0), nt.getRawData(i, 1)
            ]);
          }
          m = SocketMessage(messageId: SocketMessage.messageNumber(), command: SocketMessage.c_dllop);
          m.addString("waiterclient");
          m.addInt(SocketMessage.op_get_dish_part2_list);
          m.addString(Config.getString(key_database_name));
          m.addByte(3);
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
            Db.insert("insert into dish_part2 (id, part1, textcolor, bgcolor, name, q) values (?,?,?,?,?,?)", [
              nt.getRawData(i, 0), nt.getRawData(i, 1), nt.getRawData(i, 2), nt.getRawData(i, 3), nt.getRawData(i, 4), nt.getRawData(i, 5)
            ]);
          }
          setState(() {
            _progressString = tr("Loading car models");
          });
          m = SocketMessage(messageId: SocketMessage.messageNumber(), command: SocketMessage.c_dllop);
          m.addString("waiterclient");
          m.addInt(SocketMessage.op_car_model);
          m.addString(Config.getString(key_database_name));
          m.addByte(3);
          sendSocketMessage(m);
          break;
        case SocketMessage.op_login_pashhash:
          if (Config.getBool(key_data_dont_update)) {
            _startWithoutDataLoad();
            return;
          }
          m = SocketMessage(messageId: SocketMessage.messageNumber(), command: SocketMessage.c_dllop);
          m.addString("waiterclient");
          m.addInt(SocketMessage.op_get_hall_list);
          m.addString(Config.getString(key_database_name));
          m.addByte(3);
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
            Db.insert("insert into car_model (id, name) values (?,?)", [
              nt.getRawData(i, 0), nt.getRawData(i, 1)
            ]);
            ClassCarModel cm = ClassCarModel(id: nt.getRawData(i, 0), name: nt.getRawData(i, 1));
            ClassCarModel.carModels.add(cm);
          }

          Config.setBool(key_data_dont_update, true);
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => WidgetHalls()), (route) => false);
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
    SocketMessage m = SocketMessage(messageId: SocketMessage.messageNumber(), command: SocketMessage.c_dllplugin);
    m.addString(SocketMessage.waiterclientp);
    m.addInt(SocketMessage.op_login);
    m.addByte(3);
    m.addString(_usernameController.text);
    m.addString(_passwordController.text);
    sendSocketMessage(m);
  }

  void _startWithoutDataLoad() async {
    if (ClassCarModel.carModels.length == 0) {
      await Db.query("car_model").then((map) {
        List.generate(map.length, (i) {
          ClassCarModel cm = ClassCarModel(id: map[i]["id"], name: map[i]["name"]);
          ClassCarModel.carModels.add(cm);
        });
      });
    }
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => WidgetHalls()), (route) => false);
  }
}
