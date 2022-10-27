import 'package:cafe5_waiter_mobile_client/translator.dart';
import 'package:flutter/material.dart';

import 'class_dish_comment.dart';

class ClassDishesSpecialCommentDlg {

  static Future<String?> getComment(BuildContext context, int dishid, String msg) async {
    List<String> comments = [];
    for (int i = 0; i < ClassDishComment.list.length; i++) {
      final ClassDishComment cmn = ClassDishComment.list.elementAt(i);
      if (cmn.forid != dishid) {
        continue;
      }
      comments.add(cmn.name);
    }
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr('Dish required comment')),
          content: SingleChildScrollView(
            child: ListView.builder(
          itemCount: comments.length,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: (){
                Navigator.of(context).pop(comments[index]);
              },
              child: SizedBox(
                width: double.infinity,
                  height: 50,
                  child: Align(
                alignment: Alignment.center,
                child: Text(comments[index], style: const TextStyle())
              ))
            ) ;
          },
          )),
          actions: [
            TextButton(
              child: Text(tr("Ok")),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

}