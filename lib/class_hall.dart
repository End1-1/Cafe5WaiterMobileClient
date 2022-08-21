import 'package:cafe5_mobile_client/db.dart';

class ClassHall {
  int id;
  String name;

  ClassHall({required this.id, required this.name});
}

class ClassHallList {
  List<ClassHall> _halls = [];
  static late ClassHallList _instance;

  ClassHallList() {
    Db.query("select * from halls").then((map) {
      List.generate(map.length, (i) {

      });
    });
  }

  static List<ClassHall> hallList() {
    if (_instance == null) {
      _instance = ClassHallList();
    }
    return _instance._halls;
  }
}