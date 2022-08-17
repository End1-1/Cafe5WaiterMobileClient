import 'dart:typed_data';

import 'package:cafe5_mobile_client/base_widget.dart';
import 'package:cafe5_mobile_client/config.dart';
import 'package:cafe5_mobile_client/network_table.dart';
import 'package:cafe5_mobile_client/socket_message.dart';
import 'package:cafe5_mobile_client/translator.dart';
import 'package:flutter/material.dart';

import 'client_socket.dart';

class WidgetHome extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return WidgetHomeState();
  }
}

class WidgetHomeState extends BaseWidgetState with TickerProviderStateMixin {
  bool _dataLoading = false;
  bool _dataError = false;
  bool _allDataLoaded = false;
  NetworkTable _networkTable = NetworkTable();
  String _dataErrorString = "";
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
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  void handler(Uint8List data) {
    _dataLoading = false;
    SocketMessage m = SocketMessage(messageId: 0, command: 0);
    m.setBuffer(data);
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
          _dataError = true;
          _dataErrorString = m.getString();
          return;
        }
        switch (dllop) {

        }
        break;
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
            child: Container(margin: EdgeInsets.only(top: 5), child: Visibility(visible: _dataErrorString.isNotEmpty, child: Text(_dataErrorString))),
          )
        ])));
  }

  void _login() {
    if (_dataLoading) {
      return;
    }
    setState(() {
      _dataLoading = true;
      _dataErrorString = "";
      _dataError = false;
    });
    SocketMessage m = SocketMessage(messageId: SocketMessage.messageNumber(), command: SocketMessage.c_dllop);
    m.addString("waiterclient");
    m.addInt(SocketMessage.op_login);
    m.addString(Config.getString(key_database_name));
    m.addString(_usernameController.text);
    m.addString(_passwordController.text);
    ClientSocket.send(m.data());
  }
}
