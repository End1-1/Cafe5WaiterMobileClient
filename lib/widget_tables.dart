import 'dart:async';
import 'dart:typed_data';

import 'package:cafe5_waiter_mobile_client/home_page.dart';
import 'package:cafe5_waiter_mobile_client/network_table.dart';
import 'package:cafe5_waiter_mobile_client/socket_message.dart';
import 'package:flutter/cupertino.dart';
import 'package:cafe5_waiter_mobile_client/base_widget.dart';
import 'package:flutter/material.dart';
import 'package:cafe5_waiter_mobile_client/translator.dart';
import 'package:cafe5_waiter_mobile_client/config.dart';
import 'package:cafe5_waiter_mobile_client/db.dart';
import 'package:cafe5_waiter_mobile_client/class_table.dart';
import 'package:cafe5_waiter_mobile_client/widget_orderwindow.dart';
import 'package:cafe5_waiter_mobile_client/widget_halls.dart';
import 'package:sqflite/sqlite_api.dart';

class WidgetTables extends StatefulWidget {
  int hall;

  WidgetTables({required this.hall});

  @override
  State<StatefulWidget> createState() {
    return WidgetTablesState();
  }
}

class WidgetTablesState extends BaseWidgetState<WidgetTables> {
  bool _hideMenu = true;
  double startx = 0;
  int _menuAnimationDuration = 300;
  late Timer _timer;

  @override
  void handler(Uint8List data) async {
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
        case SocketMessage.op_get_table_list:
          NetworkTable nt = NetworkTable();
          nt.readFromSocketMessage(m);
          await Db.db!.transaction((txn) async {
            Batch b = txn.batch();
            for (int i = 0; i < nt.rowCount; i++) {
              b.update("tables", {"state": nt.getRawData(i, 2), "orderid": nt.getRawData(i, 3)}, where: "id=?", whereArgs: [nt.getRawData(i, 0)]);
            }
            await b.commit();
          });

          await Db.query("tables", orderBy: "q").then((map) {
            setState(() {
              ClassTable.list.clear();
              List.generate(map.length, (i) {
                ClassTable ct = ClassTable(id: map[i]["id"], name: map[i]["name"], stateid: map[i]["state"], hallid: map[i]["hall"]);
                ClassTable.list.add(ct);
              });
              print("after load ${ClassTable.list.length}");
            });
          });
          break;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _timer = Timer.periodic(Duration(seconds: 10), (t) {
        SocketMessage m = SocketMessage.dllplugin(SocketMessage.op_get_table_list);
        sendSocketMessage(m);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Stack(children: [
      Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 5,
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
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => WidgetHalls()), (route) => false);
                    },
                    child: Image.asset("images/back.png", width: 36, height: 36))),
            Expanded(child: Container()),
            Container(
                width: 36,
                height: 36,
                margin: EdgeInsets.only(left: 5, right: 5),
                child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.all(2),
                    ),
                    onPressed: () {
                      setState(() {
                        _hideMenu = false;
                        startx = 0;
                        _menuAnimationDuration = 300;
                      });
                    },
                    child: Image.asset("images/menu.png", width: 36, height: 36))),
          ]),
          Expanded(child: SingleChildScrollView(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: _listOfTables())))
        ],
      ),
      _menu()
    ])));
  }

  Widget _listOfTables() {
    if (ClassTable.list.isEmpty) {
      return Align(alignment: Alignment.center, child: Text(tr("List of tables is empty")));
    }

    const int columnsCount = 4;
    double columnWidth = (MediaQuery.of(context).size.width - 40) / columnsCount;
    List<DataColumn> columns = [];
    for (int i = 0; i < columnsCount; i++) {
      columns.add(DataColumn(label: Text("")));
    }

    List<DataRow> rows = [];
    List<DataCell> cells = [];
    int column = 0;
    print("in data ${ClassTable.list.length}");
    for (int i = 0; i < ClassTable.list.length; i++) {
      final ClassTable t = ClassTable.list.elementAt(i);
      if (t.hallid != widget.hall) {
        continue;
      }
      DataCell dc = DataCell(Container(
          color: _tableStateColor(t.stateid),
          margin: EdgeInsets.only(right: 3, bottom: 3),
          width: columnWidth,
          height: columnWidth,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => WidgetOrderWindow(table: t)), (route) => true);
            },
            child: Text(t.name),
          )));
      cells.add(dc);
      column++;
      if (column >= columnsCount) {
        column = 0;
        rows.add(DataRow(cells: cells));
        cells = [];
      }
    }
    if (cells.length > 0) {
      while (cells.length < columnsCount) {
        cells.add(DataCell(Text("")));
      }
      rows.add(DataRow(cells: cells));
    }

    return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: DataTable(
          dividerThickness: 0,
          columnSpacing: 0,
          dataRowHeight: columnWidth,
          columns: columns,
          rows: rows,
        ));
  }

  Color _tableStateColor(int state) {
    switch (state) {
      case 1:
        return Colors.deepOrangeAccent;
    }
    return Colors.white;
  }

  Widget _menu() {
    return AnimatedPositioned(
        duration: Duration(milliseconds: _menuAnimationDuration),
        top: 0,
        right: _hideMenu ? -1 * (MediaQuery.of(context).size.width) : startx,
        bottom: 0,
        width: MediaQuery.of(context).size.width,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _hideMenu = true;
              _menuAnimationDuration = 300;
            });
          },
          onPanStart: (details) {
            setState(() {
              _menuAnimationDuration = 1;
            });
          },
          onPanUpdate: (details) {
            if (startx - details.delta.dx > 0) {
              return;
            }
            setState(() {
              startx -= details.delta.dx;
            });
          },
          onPanEnd: (details) {
            setState(() {
              if (startx < -120) {
                _hideMenu = true;
              } else {
                startx = 0;
              }
              _menuAnimationDuration = 300;
            });
          },
          child: Container(
              color: Colors.white10,
              child: Stack(
                children: [
                  Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      width: MediaQuery.of(context).size.width - (MediaQuery.of(context).size.width / 3),
                      child: Container(
                        color: Color(0XffDDEEAA),
                        child: Column(
                          children: [
                            Container(
                              height: 5,
                            ),
                            Row(
                              children: [
                                Expanded(child: Container()),
                                Container(
                                    width: 36,
                                    height: 36,
                                    margin: EdgeInsets.only(left: 5, right: 5),
                                    child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.all(2),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _hideMenu = true;
                                          });
                                        },
                                        child: Image.asset("images/cancel.png", width: 36, height: 36)))
                              ],
                            ),
                            CheckboxListTile(
                                title: Text(tr("Update data")),
                                value: !Config.getBool(key_data_dont_update),
                                onChanged: (v) {
                                  setState(() {
                                    Config.setBool(key_data_dont_update, !v!);
                                  });
                                }),
                            Container(
                                height: 36,
                                margin: EdgeInsets.only(left: 5, right: 5),
                                child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.all(2),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        sq(tr("Confirm to logout"), () {
                                          Config.setString(key_session_id, "");
                                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => WidgetHome()), (route) => false);
                                        }, () {});
                                      });
                                    },
                                    child: Row(children: [Image.asset("images/lock.png", width: 36, height: 36), Text(tr("Logout"))]))),
                            Expanded(child: Container())
                          ],
                        ),
                      ))
                ],
              )),
        ));
  }
}
