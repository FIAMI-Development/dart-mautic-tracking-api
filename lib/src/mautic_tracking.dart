library mautic_tracking_api;

import 'package:universal_io/io.dart';

/// API to User Monitoring and Tracking using Mautic
class MauticTracking {
  /// Constructor
  MauticTracking(
    this._base_url, {
    this.userid,
    this.appName,
    this.appVersion,
    this.appBundleName,
    this.closeConnectionAfterRequest = true,
  });

  /// Mautic Base URL
  String _base_url;

  /// Mautic Contact userid
  String userid;

  /// App Name
  String appName;

  /// App Version
  String appVersion;

  /// App Bundle Name
  String appBundleName;

  /// Close Connection to Tracking after Request?
  /// Use [true] to Close Connection or [false] to make connection opened beetween requests
  final bool closeConnectionAfterRequest;


  /// Mautic Contact Cookie
  Cookie contactCookie = Cookie('mtc_id', '');

  /// Mautic Session Cookie
  Cookie sessionCookie = Cookie('mtc_sid', '');

  /// Mautic Device Cookie
  Cookie deviceCookie = Cookie('mtc_device_id', '');

  /// Mautic Tracking gif URL
  String get _tracking_url => parseURL(_base_url);

  /// Parse a URL [_url] and return authority domain
  String parseURL(String _url) {
    return _url
        .replaceAllMapped(RegExp('http(s)?:\/\/'), (match) {
          return '';
        })
        .replaceAll('/', '')
        .toLowerCase()
        .trim();
  }

  /// Return the App Name to Display on Contact Timeline
  String _getAppName() {
    return ((appName == null)
        ? ((appVersion == null) ? 'App' : 'App ($appVersion): ')
        : ((appVersion == null) ? '$appName ' : '$appName ($appVersion): '));
  }

  /// Make Request to Tracking
  Future<void> _makeRequest({Map<String, String> params}) async {
    if (userid != null) {
      params.addEntries({MapEntry('userid', userid)});
    }

    if (appBundleName != null) {
      params.addEntries({MapEntry('page_referrer', appBundleName)});
    }

    var _uri = Uri.http(_tracking_url, 'mtracking.gif', params);

    var client = HttpClient();

    await client.getUrl(_uri).then((HttpClientRequest request) {
      /// Prepare Request
      request.headers.set('Accept-Language', 'de');

      /// Setting Up Cookies
      if (contactCookie.value.isNotEmpty) {
        request.cookies.add(contactCookie);
        request.cookies.add(deviceCookie);
        request.cookies.add(sessionCookie);
      }

      /// Make Request
      return request.close();
    }).then((HttpClientResponse response) {
      /// Return Response
      for (var i = 0; i < response.cookies.length; i++) {
        var _cookie = response.cookies[i];
        if (_cookie.name.contains('mtc_sid')) {
          sessionCookie.value = _cookie.value;
          sessionCookie.httpOnly = false;
        }
        if (_cookie.name.contains('mautic_device_id')) {
          deviceCookie.value = _cookie.value;
          deviceCookie.httpOnly = false;
        }
        if (_cookie.name.contains('mtc_id')) {
          contactCookie.value = _cookie.value;
          contactCookie.httpOnly = false;
        }
      }
    });
    client.close(force: closeConnectionAfterRequest);
  }

  /// Track the App Start
  ///
  /// Example:
  ///
  /// ```dart
  /// // Track the App Start
  /// await trackAppStart();
  /// ```
  Future<void> trackAppStart() async {
    await _makeRequest(
      params: {
        'page_url': 'app_started',
        'page_title': '${_getAppName()} Started',
      },
    );
  }

  /// Send App Screen info to Tracking
  ///
  /// Use [screenPath] to register your unique **Screen Route Path** and [screenName] as **Screen Label**.
  ///
  /// Examples:
  ///
  /// ```dart
  /// // Send only Screem Path
  /// trackScreen('dashboard');
  /// ```
  /// ```dart
  /// // Send Screen Path and Timeline Name
  /// trackScreen('view_contact', 'View Contact Info');
  /// ```
  Future<void> trackScreen(String screenPath, [String screenName]) async {
    if (screenName == null) {
      await _makeRequest(
        params: {
          'page_url': screenPath,
          'page_title': '${_getAppName()} Navigation',
        },
      );
    } else {
      await _makeRequest(
        params: {
          'page_url': screenPath,
          'page_title': '${_getAppName()} Navigation: $screenName',
        },
      );
    }
  }

  /// Send App Event info to Tracking
  ///
  /// Use [eventKey] to register your unique Event Key and [eventName] as Event Label,
  /// and [screenPath] to register your Routes and [screenName] as Label.
  ///
  /// Examples:
  ///
  /// ```dart
  /// // Sent Event Key, Event Label and Screen Path
  /// trackEvent('click_total', 'Click Dashboard Total Button', 'dashboard');
  /// ```
  /// ```dart
  /// // Sent Event Key, Evebt Label, Screen Path and Screen Name
  /// trackEvent('change_password', 'Change User Password', 'user_info', 'User Info');
  /// ```
  Future<void> trackEvent(
    String eventKey,
    String eventName,
    String screenPath, [
    String screenName,
  ]) async {
    if (screenName == null) {
      await _makeRequest(
        params: {
          'page_url': 'screen_${screenPath}_event_${eventKey}',
          'page_title': '${_getAppName()} Event: $eventName'
        },
      );
    } else {
      await _makeRequest(
        params: {
          'page_url': 'screen_${screenPath}_event_${eventKey}',
          'page_title': '${_getAppName()} Event: $screenName / $eventName'
        },
      );
    }
  }

  /// Modify Contact Tags
  Future<void> _changeTag(Set<String> _tags, {bool addOperation = true}) async {
    _tags = _tags
        .map(
          (item) => (addOperation) ? item : '-$item',
        )
        .toSet();
    await _makeRequest(params: {
      'page_title': ('${_getAppName()} ' +
          (addOperation ? 'Added Tags: ' : 'Removed Tags: ') +
          _tags.join(',')),
      'tags': _tags.join(',')
    });
  }

  /// Add Contact Tags
  ///
  /// Examples:
  ///
  /// ```dart
  /// // Sent Event Key, Event Label and Screen Path
  /// addTag({'tag1', 'tag2'});
  /// ```
  Future<void> addTag(Set<String> _tags) async {
    await _changeTag(_tags);
  }

  /// Remove Contact Tags
  ///
  /// Examples:
  ///
  /// ```dart
  /// // Sent Event Key, Event Label and Screen Path
  /// removeTag({'tag1', 'tag2'});
  /// ```
  Future<void> removeTag(Set<String> _tags) async {
    await _changeTag(_tags, addOperation: false);
  }
}
