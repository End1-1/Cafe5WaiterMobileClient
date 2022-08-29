import 'package:flutter/material.dart';

class ClassDish {
  int id;
  int part2;
  String name;

  Color bgColor = Colors.white;
  Color textColor = Colors.black54;

  ClassDish(this.id, this.part2, this.name);

  static Map<int, ClassDish> map = Map();
}