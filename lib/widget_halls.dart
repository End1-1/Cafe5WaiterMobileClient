import 'package:cafe5_mobile_client/widget_bottom_menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:cafe5_mobile_client/base_widget.dart';
import 'package:flutter/material.dart';

class WidgetHalls extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return WidgetHallsState();
  }
}

class WidgetHallsState extends BaseWidgetState {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: Column(children: [
      Expanded(
        child: SingleChildScrollView (
          child: Text("DD"),
        ),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: bottomMenu()
        )
      )
    ],)));
  }
}
