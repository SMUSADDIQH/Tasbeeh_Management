import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

class AppShareService {
  const AppShareService();

  static bool _isSharing = false;

  static bool get isSharing => _isSharing;

  Future<void> shareApp(
    BuildContext context, {
    PackageInfo? overridePackageInfo,
    Future<void> Function(ShareParams params)? overrideShareFunction,
  }) async {
    if (_isSharing) return;
    _isSharing = true;

    try {
      final PackageInfo packageInfo =
          overridePackageInfo ?? await PackageInfo.fromPlatform();
      final String packageName = packageInfo.packageName.isEmpty
          ? 'com.riontix.tasbeehmanagement'
          : packageInfo.packageName;

      final String playStoreUrl =
          'https://play.google.com/store/apps/details?id=$packageName';

      final String shareText = '''
Tasbeeh Management

Track, reflect and grow in your daily Zikr.

Download Tasbeeh Management from Google Play:
$playStoreUrl''';

      final params = ShareParams(
        text: shareText,
        subject: 'Tasbeeh Management',
      );

      if (overrideShareFunction != null) {
        await overrideShareFunction(params);
      } else {
        await SharePlus.instance.share(params);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share app. Please try again.'),
          ),
        );
      }
    } finally {
      _isSharing = false;
    }
  }
}
