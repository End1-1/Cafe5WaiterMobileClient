import 'package:shared_preferences/shared_preferences.dart';

const key_server_address = "key_server_address";
const key_server_port = "key_server_port";
const key_server_username = "key_server_username";
const key_server_password = "key_server_password";
const key_database_name = "key_database_name";
const key_session_id = "key_session_id";
const key_fullname = "key_fullname";

List<String> dbCreate = [
  "create table halls (id int primary key, menuid int, servicevalue real, name, text)",
  "create table tables (id int primary key, hall int, state int, name text, q int)",
  "create table dish_part1 (id int primary key, name text)",
  "create table dish_part2 (id int primary key, part1 int, bgcolor int, textcolor int, name text, q int)",
  "create table dish (id int, part2 int, name text, price real)"
];


class Config {

  static late Config _config;
  late SharedPreferences _preferences;

  Config() {
  }

  static Future<void> init() async {
    _config = Config();
    _config._preferences = await SharedPreferences.getInstance();
  }

  static void setString(String key, String value) {
    _config._preferences.setString(key, value);
  }

  static String getString(String key) {
    return _config._preferences.getString(key) ?? "";
  }

  static void setInt(String key, int value) {
    _config._preferences.setInt(key, value);
  }

  static int getInt(String key) {
    return _config._preferences.getInt(key)!;
  }

  static void setDouble(String key, double value) {
    _config._preferences.setDouble(key, value);
  }

  static double getDouble(String key) {
    return _config._preferences.getDouble(key)!;
  }
}