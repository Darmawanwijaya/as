import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Initialize FCM
    await _firebaseMessaging.requestPermission();
    _firebaseMessaging.getToken().then((token) {
      print("FCM Token: $token");
    });
    
    // Configure FCM message handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle the message when the app is in the foreground
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      print('Message notification: ${message.notification}');

      // Handle custom data
      if (message.data.isNotEmpty) {
        _handleCustomData(message.data);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle the user tapping on the notification when the app is in the background or terminated
      print('A new onMessageOpenedApp event was published!');
      print('Message data: ${message.data}');
    });
  }

  void _handleCustomData(Map<String, dynamic> data) {
    // Handle custom data from the FCM payload
    // You can trigger actions or pass data to other parts of your app
  }
}
