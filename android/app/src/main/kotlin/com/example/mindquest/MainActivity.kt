package com.example.mindquest

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.parental_control/native"
    private val USAGE_STATS_CHANNEL = "com.example.usage_stats/native"
    private val REQUEST_CODE_ENABLE_ADMIN = 1
    private val REQUEST_CODE_USAGE_STATS = 2
    private val REQUEST_CODE_OVERLAY_PERMISSION = 3

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Parental Control Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestAntiRemovalPermission" -> {
                    requestDeviceAdminPermission()
                    result.success("Anti-removal permission requested")
                }
                "blockApp" -> {
                    val appName = call.argument<String>("appName")
                    blockApplication(appName ?: "")
                    result.success("App blocked: $appName")
                }
                "unblockApp" -> {
                    val appName = call.argument<String>("appName")
                    unblockApplication(appName ?: "")
                    result.success("App unblocked: $appName")
                }
                "checkContentFilter" -> {
                    val content = call.argument<String>("content")
                    val isBlocked = checkContentForBlockedKeywords(content ?: "")
                    result.success(isBlocked)
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success("Overlay permission requested")
                }
                "showBlockedContentWarning" -> {
                    val message = call.argument<String>("message")
                    showBlockedContentWarning(message ?: "Content blocked by parental controls")
                    result.success("Warning displayed")
                }
                "requestUsageStatsPermission" -> {
                    requestUsageStatsPermission()
                    result.success("Usage stats permission requested")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Usage Stats Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_STATS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestUsageStatsPermission" -> {
                    requestUsageStatsPermission()
                    result.success("Usage stats permission requested")
                }
                "getUsageStats" -> {
                    val usageStats = getUsageStats()
                    result.success(usageStats)
                }
                "getCurrentAppUsage" -> {
                    val currentApp = getCurrentAppUsage()
                    result.success(currentApp)
                }
                "checkUsageStatsPermission" -> {
                    val hasPermission = checkUsageStatsPermission()
                    result.success(hasPermission)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun requestDeviceAdminPermission() {
        val devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = ComponentName(this, DeviceAdminReceiver::class.java)
        
        if (!devicePolicyManager.isAdminActive(adminComponent)) {
            val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
            intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
            intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, 
                "This app needs device admin permission to prevent uninstallation and control app access")
            startActivityForResult(intent, REQUEST_CODE_ENABLE_ADMIN)
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                intent.data = Uri.parse("package:$packageName")
                startActivityForResult(intent, REQUEST_CODE_OVERLAY_PERMISSION)
            }
        }
    }

    private fun blockApplication(appName: String) {
        Log.d("ParentalControl", "Blocking application: $appName")
        
        // Implementation for blocking apps
        // This could include:
        // 1. Showing a warning dialog
        // 2. Redirecting to a different app
        // 3. Showing educational content
        // 4. Implementing time-based restrictions
        
        // For now, we'll log the action
        // In a real implementation, you would:
        // - Use DevicePolicyManager to disable apps
        // - Show overlay warnings
        // - Redirect to safe apps
    }

    private fun unblockApplication(appName: String) {
        Log.d("ParentalControl", "Unblocking application: $appName")
        
        // Implementation for unblocking apps
        // This would reverse the blocking actions
    }

    private fun checkContentForBlockedKeywords(content: String): Boolean {
        // List of blocked keywords for adult content
        val blockedKeywords = listOf(
            "adult", "porn", "xxx", "sex", "nude", "naked", "explicit",
            "violence", "gore", "blood", "kill", "murder", "suicide",
            "drugs", "cocaine", "heroin", "marijuana", "weed",
            "gambling", "casino", "bet", "lottery"
        )
        
        val lowerContent = content.lowercase()
        return blockedKeywords.any { keyword -> lowerContent.contains(keyword) }
    }

    private fun showBlockedContentWarning(message: String) {
        // Show a system overlay warning
        // This would typically be implemented using a custom overlay service
        Log.d("ParentalControl", "Showing blocked content warning: $message")
        
        // In a real implementation, you would:
        // 1. Create a custom overlay service
        // 2. Show a warning dialog
        // 3. Log the blocked content attempt
        // 4. Notify parents if configured
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        when (requestCode) {
            REQUEST_CODE_ENABLE_ADMIN -> {
                if (resultCode == Activity.RESULT_OK) {
                    Log.d("ParentalControl", "Device admin permission granted")
                } else {
                    Log.d("ParentalControl", "Device admin permission denied")
                }
            }
            REQUEST_CODE_OVERLAY_PERMISSION -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    if (Settings.canDrawOverlays(this)) {
                        Log.d("ParentalControl", "Overlay permission granted")
                    } else {
                        Log.d("ParentalControl", "Overlay permission denied")
                    }
                }
            }
        }
    }
    
    // Usage Stats Methods
    private fun requestUsageStatsPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            startActivityForResult(intent, REQUEST_CODE_USAGE_STATS)
        }
    }
    
    private fun checkUsageStatsPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val time = System.currentTimeMillis()
            val usageStats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                time - 1000 * 60 * 60 * 24, // 24 hours ago
                time
            )
            return usageStats != null && usageStats.isNotEmpty()
        }
        return false
    }
    
    private fun getUsageStats(): List<Map<String, Any>> {
        if (!checkUsageStatsPermission()) {
            return emptyList()
        }
        
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_MONTH, -1)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()
        
        val usageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )
        
        val appUsageList = mutableListOf<Map<String, Any>>()
        val packageManager = packageManager
        
        usageStats?.forEach { usage ->
            try {
                val appInfo = packageManager.getApplicationInfo(usage.packageName, 0)
                val appName = packageManager.getApplicationLabel(appInfo).toString()
                val category = getAppCategory(usage.packageName)
                
                appUsageList.add(mapOf(
                    "packageName" to usage.packageName,
                    "appName" to appName,
                    "usageTime" to usage.totalTimeInForeground,
                    "category" to category,
                    "lastTimeUsed" to usage.lastTimeUsed
                ))
            } catch (e: PackageManager.NameNotFoundException) {
                // App not found, skip
            }
        }
        
        return appUsageList.sortedByDescending { it["usageTime"] as Long }
    }
    
    private fun getCurrentAppUsage(): Map<String, Any> {
        if (!checkUsageStatsPermission()) {
            return mapOf(
                "packageName" to "unknown",
                "appName" to "Unknown",
                "usageTimeMinutes" to 0,
                "category" to "Unknown"
            )
        }
        
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 1000 * 60 * 5 // Last 5 minutes
        
        val usageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_BEST,
            startTime,
            endTime
        )
        
        val currentApp = usageStats?.maxByOrNull { it.lastTimeUsed }
        
        return if (currentApp != null) {
            try {
                val packageManager = packageManager
                val appInfo = packageManager.getApplicationInfo(currentApp.packageName, 0)
                val appName = packageManager.getApplicationLabel(appInfo).toString()
                val category = getAppCategory(currentApp.packageName)
                
                mapOf(
                    "packageName" to currentApp.packageName,
                    "appName" to appName,
                    "usageTimeMinutes" to (currentApp.totalTimeInForeground / (1000 * 60)).toInt(),
                    "category" to category
                )
            } catch (e: PackageManager.NameNotFoundException) {
                mapOf(
                    "packageName" to currentApp.packageName,
                    "appName" to currentApp.packageName,
                    "usageTimeMinutes" to (currentApp.totalTimeInForeground / (1000 * 60)).toInt(),
                    "category" to "Unknown"
                )
            }
        } else {
            mapOf(
                "packageName" to "unknown",
                "appName" to "Unknown",
                "usageTimeMinutes" to 0,
                "category" to "Unknown"
            )
        }
    }
    
    private fun getAppCategory(packageName: String): String {
        return when {
            packageName.contains("com.whatsapp") || 
            packageName.contains("com.facebook") ||
            packageName.contains("com.instagram") ||
            packageName.contains("com.twitter") ||
            packageName.contains("com.snapchat") -> "Social"
            
            packageName.contains("com.netflix") ||
            packageName.contains("com.youtube") ||
            packageName.contains("com.spotify") ||
            packageName.contains("com.amazon") ||
            packageName.contains("com.disney") -> "Entertainment"
            
            packageName.contains("com.google.android.apps.docs") ||
            packageName.contains("com.microsoft.office") ||
            packageName.contains("com.adobe") ||
            packageName.contains("com.slack") ||
            packageName.contains("com.microsoft.teams") -> "Productivity"
            
            packageName.contains("com.udemy") ||
            packageName.contains("com.coursera") ||
            packageName.contains("com.khan") ||
            packageName.contains("com.edx") -> "Education"
            
            else -> "Other"
        }
    }
}

