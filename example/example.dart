import 'package:mautic_tracking_api/mautic_tracking_api.dart';

void main() async {
  // Start Tracking
  var m = MauticTracking(
    "https://mautic.example.com",
    appName: "MyApp",
    userid: "contact@email.com",
    appVersion: '1.0.0',
    appBundleName: 'com.mydomain.myapp',
  );

  /// Track App Start
  await m.trackAppStart();

  /// Track App Screen
  m.trackScreen("main", "Main Page");

  /// Track App Event
  m.trackEvent('click', 'Click Get Start Button', 'home', 'Home Page');

  /// Add Contact Tag
  m.addTag({'a', 'b'});
}
