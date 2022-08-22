import 'dart:typed_data';

import 'package:cafe5_waiter_mobile_client/socket_message.dart';
import 'package:cafe5_waiter_mobile_client/widget_tables.dart';
import 'package:flutter/cupertino.dart';
import 'package:cafe5_waiter_mobile_client/base_widget.dart';
import 'package:flutter/material.dart';
import 'package:cafe5_waiter_mobile_client/translator.dart';
import 'package:cafe5_waiter_mobile_client/config.dart';
import 'package:cafe5_waiter_mobile_client/db.dart';
import 'package:cafe5_waiter_mobile_client/class_table.dart';
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

  @override
  void handler(Uint8List data) {
    _dataLoading = false;
    SocketMessage m = SocketMessage(messageId: 0, command: 0);
    m.setBuffer(data);
    if (!checkSocketMessage(m)) {
      return;
    }
    print("command widget_orderwindow ${m.command}");
    int dllok = m.getByte();
    switch (dllok) {
      case 0:
        setState(() {
          _dataErrorString = "Required dll not found on server.";
          _dataError = true;
        });
        break;
      case 1:
        setState(() {
          _dataErrorString = "Required dll function not found on server.";
          _dataError = true;
        });
        break;
      case 2:
        int dllop = m.getInt();
        int dlloperror = m.getByte();
        if (dlloperror == 0) {
          setState((){
            _dataError = true;
            _dataErrorString = m.getString();
          });
          return;
        }
        switch (dllop) {
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
      SocketMessage m = SocketMessage(messageId: SocketMessage.messageNumber(), command: SocketMessage.c_dllop);
      m.addString("waiterclient");
      m.addInt(SocketMessage.op_open_table);
      m.addString(Config.getString(key_database_name));
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
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 5,
                  ),
                  Visibility(
                    visible: _dataErrorString.isNotEmpty,
                      child: Align(alignment: Alignment.center, child: Text(_dataErrorString),)
                  ),
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
                              SocketMessage m = SocketMessage(messageId: SocketMessage.messageNumber(), command: SocketMessage.c_dllop);
                              m.addString("waiterclient");
                              m.addInt(SocketMessage.op_unlock_table);
                              m.addString(Config.getString(key_database_name));
                              m.addByte(3);
                              m.addInt(widget.table.id);
                              m.addString(Config.getString(key_session_id));
                              sendSocketMessage(m);
                            },
                            child: Image.asset("images/back.png", width: 36, height: 36))),
                    Expanded(child: Container(

                    )),
                    Container(
                        child: Text(widget.table.name)
                    )
                  ]),
                ])));
  }
  }