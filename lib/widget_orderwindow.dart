import 'dart:typed_data';

import 'package:cafe5_waiter_mobile_client/socket_message.dart';
import 'package:cafe5_waiter_mobile_client/widget_setcar.dart';
import 'package:cafe5_waiter_mobile_client/widget_tables.dart';
import 'package:flutter/cupertino.dart';
import 'package:cafe5_waiter_mobile_client/base_widget.dart';
import 'package:flutter/material.dart';
import 'package:cafe5_waiter_mobile_client/translator.dart';
import 'package:cafe5_waiter_mobile_client/config.dart';
import 'package:cafe5_waiter_mobile_client/db.dart';
import 'package:cafe5_waiter_mobile_client/class_table.dart';
import 'package:cafe5_waiter_mobile_client/class_car_model.dart';
import 'package:cafe5_waiter_mobile_client/widget_tables.dart';

class WidgetOrderWindow extends StatefulWidget {
  final ClassTable table;

  WidgetOrderWindow({required this.table});

  @override
  State<StatefulWidget> createState() {
    return WidgetOrderWindowState();
  }
}

class WidgetOrderWindowState extends BaseWidgetState<WidgetOrderWindow> {
  bool _dataLoading = false;
  bool _dataError = false;
  String _dataErrorString = "";

  ClassCarModel? _carModel;

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
          case SocketMessage.op_open_table:
            break;
          case SocketMessage.op_unlock_table:
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => WidgetTables(hall: widget.table.hallid)), (route) => false);
            break;
        }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      SocketMessage m = SocketMessage(messageId: SocketMessage.messageNumber(), command: SocketMessage.c_dllplugin);
      m.addString(SocketMessage.waiterclientp);
      m.addInt(SocketMessage.op_open_table);
      m.addByte(3);
      m.addInt(widget.table.id);
      m.addString(Config.getString(key_session_id));
      sendSocketMessage(m);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        height: 5,
      ),
      Visibility(
          visible: _dataErrorString.isNotEmpty,
          child: Align(
            alignment: Alignment.center,
            child: Text(_dataErrorString),
          )),
      Row(children: [
        Container(
            width: 36,
            height: 36,
            margin: EdgeInsets.only(left: 5),
            child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.all(2),
                ),
                onPressed: () {
                  SocketMessage m = SocketMessage(messageId: SocketMessage.messageNumber(), command: SocketMessage.c_dllplugin);
                  m.addString(SocketMessage.waiterclientp);
                  m.addInt(SocketMessage.op_unlock_table);
                  m.addByte(3);
                  m.addInt(widget.table.id);
                  m.addString(Config.getString(key_session_id));
                  sendSocketMessage(m);
                },
                child: Image.asset("images/back.png", width: 36, height: 36))),
        Expanded(child: Container()),
        Container(child: Text(widget.table.name))
      ]),
      Row(
        children: [
          Expanded(child: Container(
            margin: EdgeInsets.only(left: 5, top: 2, right: 5),
            height: 36,
              child: OutlinedButton (
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.only(left: 5),
              ),
              onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => WidgetSetCar(table: widget.table)));
                if (result == null) {
                  return;
                }
              },
              child: Row(children: [
                Image.asset("images/car.png"),
    Text(_getCarTitle()),
              ]
              )))
          ),
        ],
      )
    ])));
  }

  String _getCarTitle() {
    String result = "";
    result += _carModel == null ? "" : _carModel!.name;
    return result;
  }
}
