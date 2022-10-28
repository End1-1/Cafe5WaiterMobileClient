import 'package:cafe5_waiter_mobile_client/class_outlinedbutton.dart';
import 'package:cafe5_waiter_mobile_client/translator.dart';
import 'package:flutter/material.dart';

import 'class_dish_comment.dart';

class ClassDishesSpecialCommentDlg {

  static Map<int, List<String>> specialComments = {};

  static void init() {
    for (int i = 0; i < ClassDishComment.list.length; i++) {
      final ClassDishComment cmn = ClassDishComment.list.elementAt(i);
      if (cmn.forid > 0) {
        if (!specialComments.containsKey(cmn.forid)) {
          specialComments[cmn.forid] = [];
        }
        specialComments[cmn.forid]!.add(cmn.name);
      }
    }
  }

  static bool specialCommentForDish(int id) {
    return specialComments.containsKey(id);
  }

  static Future<double?> getComment(BuildContext context, int dishid, String msg) async {

    return showDialog<double?>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr('Dish required comment')),
          content: Container(
              decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffeaeaea))
              ),
              height: 300,
              width: 300,
              child: Flex (
                direction: Axis.vertical,
                children:
                [
                  Flex(direction: Axis.horizontal,
                  children: [
                    ClassOutlinedButton.create((){_result(context, 3);}, "3"),
                    ClassOutlinedButton.create((){_result(context, 4);}, "4"),
                    ClassOutlinedButton.create((){_result(context, 5);}, "5"),
                  ],)
                ],

              )),
          actions: [
            TextButton(
              child: Text(tr("Cancel")),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static void _result(BuildContext context, double v) {
    return Navigator.pop(context, v);
  }
}