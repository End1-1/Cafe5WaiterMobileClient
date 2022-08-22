import 'package:cafe5_waiter_mobile_client/widget_bottom_menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:cafe5_waiter_mobile_client/base_widget.dart';
import 'package:flutter/material.dart';
import 'package:cafe5_waiter_mobile_client/translator.dart';
import 'package:cafe5_waiter_mobile_client/config.dart';
import 'package:cafe5_waiter_mobile_client/db.dart';
import 'package:cafe5_waiter_mobile_client/class_table.dart';
import 'package:cafe5_waiter_mobile_client/widget_orderwindow.dart';
import 'package:cafe5_waiter_mobile_client/widget_halls.dart';

class WidgetTables extends StatefulWidget {
  int hall;

  WidgetTables({required this.hall});

  @override
  State<StatefulWidget> createState() {
    return WidgetTablesState();
  }
}

class WidgetTablesState extends BaseWidgetState<WidgetTables> {
  List<ClassTable> _tables = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Db.rawQuery("select * from tables where hall=${widget.hall} order by q").then((map) {
        List.generate(map.length, (i) {
          ClassTable ct = ClassTable(id: map[i]["id"], name: map[i]["name"], stateid: map[i]["state"], hallid: map[i]["hall"]);
          _tables.add(ct);
        });
        setState(() {});
      });
    });
    super.initState();
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
                  child: Image.asset("images/back.png", width: 36, height: 36)))
        ]),
        Expanded(child: SingleChildScrollView(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: _listOfTables())))
      ],
    )));
  }

  Widget _listOfTables() {
    if (_tables.isEmpty) {
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
    for (int i = 0; i < _tables.length; i++) {
      final ClassTable t = _tables.elementAt(i);
      DataCell dc = DataCell(Container(
        color: _tableStateColor(t.stateid),
          margin: EdgeInsets.only(right: 3, bottom: 3),
          width: columnWidth,
          height: columnWidth,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => WidgetOrderWindow(table: t)), (route) => false);
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
}
