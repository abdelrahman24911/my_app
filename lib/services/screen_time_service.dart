import 'dart:async';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/screen_time_model.dart';

class ScreenTimeService {
  static const MethodChannel _channel = MethodChannel('screen_time_service');
  static const MethodChannel _usageStatsChannel = MethodChannel('com.example.usage_stats/native');
  static ScreenTimeModel? _screenTimeModel;
  static Timer? _usageTimer;

  // Initialize the service
  static Future<void> initialize(ScreenTimeModel screenTimeModel) async {
    _screenTimeModel = screenTimeModel;
    
    // Set up method call handler
    _channel.setMethodCallHandler(_handleMethodCall);
    
    // Start periodic usage tracking
    _startUsageTracking();
  }

  // Handle method calls from native code
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onAppUsageChanged':
        final String packageName = call.arguments['packageName'];
        final String appName = call.arguments['appName'];
        final int usageTimeMinutes = call.arguments['usageTimeMinutes'];
        final String category = call.arguments['category'] ?? 'Unknown';
        
        if (_screenTimeModel != null) {
          await _screenTimeModel!.addAppUsage(
            packageName,
            appName,
            Duration(minutes: usageTimeMinutes),
            category,
          );
        }
        break;
        
      case 'onContentBlocked':
        final String content = call.arguments['content'];
        final String reason = call.arguments['reason'];
        
        // Show notification or handle blocked content
        _showContentBlockedNotification(content, reason);
        break;
        
      case 'onAppBlocked':
        final String packageName = call.arguments['packageName'];
        final String appName = call.arguments['appName'];
        
        // Show notification that app is blocked
        _showAppBlockedNotification(appName);
        break;
    }
  }

  // Start periodic usage tracking
  static void _startUsageTracking() {
    _usageTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _trackCurrentAppUsage();
    });
  }

  // Track current app usage
  static Future<void> _trackCurrentAppUsage() async {
    try {
      final Map<String, dynamic>? result = await _usageStatsChannel.invokeMethod('getCurrentAppUsage');
      
      if (result != null && _screenTimeModel != null) {
        final String packageName = result['packageName'];
        final String appName = result['appName'];
        final int usageTimeMinutes = result['usageTimeMinutes'];
        final String category = result['category'] ?? 'Unknown';
        
        // Only track if app is not blocked
        if (!_screenTimeModel!.isAppBlocked(packageName)) {
          await _screenTimeModel!.addAppUsage(
            packageName,
            appName,
            Duration(minutes: usageTimeMinutes),
            category,
          );
        }
      }
    } catch (e) {
      print('Error tracking app usage: $e');
    }
  }

  // Block an app
  static Future<bool> blockApp(String packageName) async {
    try {
      final bool result = await _channel.invokeMethod('blockApp', {
        'packageName': packageName,
      });
      
      if (result && _screenTimeModel != null) {
        await _screenTimeModel!.blockApp(packageName);
      }
      
      return result;
    } catch (e) {
      print('Error blocking app: $e');
      return false;
    }
  }

  // Unblock an app
  static Future<bool> unblockApp(String packageName) async {
    try {
      final bool result = await _channel.invokeMethod('unblockApp', {
        'packageName': packageName,
      });
      
      if (result && _screenTimeModel != null) {
        await _screenTimeModel!.unblockApp(packageName);
      }
      
      return result;
    } catch (e) {
      print('Error unblocking app: $e');
      return false;
    }
  }

  // Check if content should be blocked
  static Future<bool> checkContentFilter(String content) async {
    try {
      final bool result = await _channel.invokeMethod('checkContentFilter', {
        'content': content,
      });
      
      return result;
    } catch (e) {
      print('Error checking content filter: $e');
      return false;
    }
  }

  // Add NSFW keyword
  static Future<bool> addNsfwKeyword(String keyword) async {
    try {
      final bool result = await _channel.invokeMethod('addNsfwKeyword', {
        'keyword': keyword,
      });
      
      if (result && _screenTimeModel != null) {
        await _screenTimeModel!.addNsfwKeyword(keyword);
      }
      
      return result;
    } catch (e) {
      print('Error adding NSFW keyword: $e');
      return false;
    }
  }

  // Remove NSFW keyword
  static Future<bool> removeNsfwKeyword(String keyword) async {
    try {
      final bool result = await _channel.invokeMethod('removeNsfwKeyword', {
        'keyword': keyword,
      });
      
      if (result && _screenTimeModel != null) {
        await _screenTimeModel!.removeNsfwKeyword(keyword);
      }
      
      return result;
    } catch (e) {
      print('Error removing NSFW keyword: $e');
      return false;
    }
  }

  // Enable anti-removal protection
  static Future<bool> enableAntiRemoval() async {
    try {
      final bool result = await _channel.invokeMethod('enableAntiRemoval');
      return result;
    } catch (e) {
      print('Error enabling anti-removal: $e');
      return false;
    }
  }

  // Disable anti-removal protection
  static Future<bool> disableAntiRemoval() async {
    try {
      final bool result = await _channel.invokeMethod('disableAntiRemoval');
      return result;
    } catch (e) {
      print('Error disabling anti-removal: $e');
      return false;
    }
  }

  // Get real usage statistics from Android
  static Future<List<Map<String, dynamic>>> getRealUsageStats() async {
    try {
      final List<dynamic> result = await _usageStatsChannel.invokeMethod('getUsageStats');
      return result.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting real usage stats: $e');
      return [];
    }
  }

  // Request usage stats permission
  static Future<bool> requestUsageStatsPermission() async {
    try {
      // Use the working parental control channel to open settings
      await _channel.invokeMethod('requestUsageStatsPermission');
      return true;
    } catch (e) {
      print('Error requesting usage stats permission: $e');
      return true; // Still return true to show the dialog
    }
  }

  // Check if usage stats permission is granted
  static Future<bool> checkUsageStatsPermission() async {
    try {
      final bool result = await _usageStatsChannel.invokeMethod('checkUsageStatsPermission');
      return result;
    } catch (e) {
      print('Error checking usage stats permission: $e');
      return false;
    }
  }

  // Get app usage statistics
  static Future<Map<String, dynamic>?> getUsageStats() async {
    try {
      final Map<String, dynamic>? result = await _channel.invokeMethod('getUsageStats');
      return result;
    } catch (e) {
      print('Error getting usage stats: $e');
      return null;
    }
  }

  // Show content blocked notification
  static void _showContentBlockedNotification(String content, String reason) {
    // This would typically show a system notification
    print('Content blocked: $content - Reason: $reason');
  }

  // Show app blocked notification
  static void _showAppBlockedNotification(String appName) {
    // This would typically show a system notification
    print('App blocked: $appName');
  }

  // Cleanup
  static void dispose() {
    _usageTimer?.cancel();
    _usageTimer = null;
  }
}
