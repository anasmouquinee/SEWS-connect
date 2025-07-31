import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String userBoxName = 'userBox';
  static const String settingsBoxName = 'settingsBox';
  static const String tasksBoxName = 'tasksBox';
  static const String notificationsBoxName = 'notificationsBox';
  
  static late Box userBox;
  static late Box settingsBox;
  static late Box tasksBox;
  static late Box notificationsBox;
  
  static Future<void> init() async {
    await Hive.initFlutter();
    
    userBox = await Hive.openBox(userBoxName);
    settingsBox = await Hive.openBox(settingsBoxName);
    tasksBox = await Hive.openBox(tasksBoxName);
    notificationsBox = await Hive.openBox(notificationsBoxName);
  }
  
  // User data methods
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await userBox.put('user', userData);
  }
  
  static Map<String, dynamic>? getUserData() {
    return userBox.get('user');
  }
  
  static Future<void> clearUserData() async {
    await userBox.clear();
  }
  
  // Settings methods
  static Future<void> saveSetting(String key, dynamic value) async {
    await settingsBox.put(key, value);
  }
  
  static T? getSetting<T>(String key) {
    return settingsBox.get(key);
  }
  
  // Tasks methods
  static Future<void> saveTask(String taskId, Map<String, dynamic> task) async {
    await tasksBox.put(taskId, task);
  }
  
  static Map<String, dynamic>? getTask(String taskId) {
    return tasksBox.get(taskId);
  }
  
  static List<Map<String, dynamic>> getAllTasks() {
    return tasksBox.values.cast<Map<String, dynamic>>().toList();
  }
  
  // Notifications methods
  static Future<void> saveNotification(String notificationId, Map<String, dynamic> notification) async {
    await notificationsBox.put(notificationId, notification);
  }
  
  static List<Map<String, dynamic>> getAllNotifications() {
    return notificationsBox.values.cast<Map<String, dynamic>>().toList();
  }
}
