import 'package:cafe5_mobile_client/translator.dart';
import 'package:flutter/material.dart';

Widget bottomMenu() {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
          width: 100,
          child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                backgroundColor: Color(0x9766798D),
                side: BorderSide(
                  width: 1.0,
                  color: Colors.black38,
                  style: BorderStyle.solid,
                ),
              ),
              onPressed: () {},
              child: Text(tr("Hall"), style: TextStyle(color: Colors.white)))),
      Container(
        width: 5,
      ),
      SizedBox(
          width: 100,
          child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                backgroundColor: Color(0x9766798D),
                side: BorderSide(
                  width: 1.0,
                  color: Colors.black38,
                  style: BorderStyle.solid,
                ),
              ),
              onPressed: () {},
              child: Text(tr("Tables"), style: TextStyle(color: Colors.white)))),
    ],
  );
}
