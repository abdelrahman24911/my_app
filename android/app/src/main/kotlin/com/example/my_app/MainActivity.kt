package com.example.my_app

import android.app.Activity
import android.app.AppOpsManager
import android.app.admin.DeviceAdminReceiver
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.widget.Toast
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Process
import android.util.Log
import android.os.Handler
import android.os.Looper
import android.view.WindowManager
import android.graphics.Color
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.TextView
import android.app.usage.UsageStatsManager
import android.content.pm.PackageManager
import java.util.*

// MethodChannel name - MUST match the one in home_screen.dart
private const val CHANNEL = "com.appguard.native_calls"
private const val TAG = "AdminChecker"

// Warning Activity for Admin Disable Protection
class WarningActivity : Activity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)

        // Full screen settings
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )
        window.setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN,
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        )

        // Create warning UI
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#E53935"))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.MATCH_PARENT
            )
        }

        val textView = TextView(this).apply {
            text = "🛑 Security Alert!\nThis warning will close in 8 seconds."
            textSize = 24f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(50, 50, 50, 50)
        }

        layout.addView(textView)
        setContentView(layout)

        // Auto-close after 8 seconds
        Handler(Looper.getMainLooper()).postDelayed({
            finish()
        }, 8000)
    }
}

// Device Admin Receiver
class DeviceAdminReceiver : android.app.admin.DeviceAdminReceiver() {
    override fun onDisableRequested(context: Context, intent: Intent): CharSequence? {
        // Show warning activity
        try {
            val warningIntent = Intent(context, WarningActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            }
            context.startActivity(warningIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch WarningActivity: ${e.message}")
        }

        // Restart app
        try {
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            context.startActivity(launchIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch app after disable request: ${e.message}")
        }

        return "⛔CANNOT DISABLE THIS OPTION!"
    }

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Toast.makeText(context, "Device Admin Enabled!", Toast.LENGTH_SHORT).show()
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Toast.makeText(context, "Device Admin Disabled!", Toast.LENGTH_SHORT).show()
    }
}

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Check Device Admin status
                "isAdminActive" -> {
                    val isActive = checkDeviceAdminActive(this)
                    result.success(isActive)
                }
                // Request Device Admin permission
                "requestAdminPermission" -> {
                    requestDeviceAdminPermission(this)
                    result.success(true)
                }
                // Request Usage Access permission
                "requestUsagePermission" -> {
                    requestUsageAccessPermission(this)
                    result.success(true)
                }
                // Check Usage Access permission
                "hasUsagePermission" -> {
                    result.success(hasUsageAccessPermission(this))
                }
                // Validate usage data accuracy
                "validateUsageData" -> {
                    try {
                        val validationResult = validateUsageDataAccuracy(this)
                        result.success(validationResult)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error validating usage data: ${e.message}")
                        result.error("VALIDATION_ERROR", "Failed to validate usage data.", e.message)
                    }
                }
                // Get usage statistics
                "getUsageStats" -> {
                    try {
                        val usageStatsList = getUsageStats(this)
                        result.success(usageStatsList)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error fetching usage stats: ${e.message}")
                        result.error("USAGE_ERROR", "Failed to retrieve usage stats.", e.message)
                    }
                }
                // Get weekly usage statistics
                "getWeeklyUsageStats" -> {
                    try {
                        val usageStatsList = getWeeklyUsageStats(this)
                        result.success(usageStatsList)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error fetching weekly usage stats: ${e.message}")
                        result.error("USAGE_ERROR", "Failed to retrieve weekly usage stats.", e.message)
                    }
                }
                // Get monthly usage statistics
                "getMonthlyUsageStats" -> {
                    try {
                        val usageStatsList = getMonthlyUsageStats(this)
                        result.success(usageStatsList)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error fetching monthly usage stats: ${e.message}")
                        result.error("USAGE_ERROR", "Failed to retrieve monthly usage stats.", e.message)
                    }
                }
                // Get 3 months usage statistics
                "get3MonthsUsageStats" -> {
                    try {
                        val usageStatsList = get3MonthsUsageStats(this)
                        result.success(usageStatsList)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error fetching 3 months usage stats: ${e.message}")
                        result.error("USAGE_ERROR", "Failed to retrieve 3 months usage stats.", e.message)
                    }
                }
                // Get 6 months usage statistics
                "get6MonthsUsageStats" -> {
                    try {
                        val usageStatsList = get6MonthsUsageStats(this)
                        result.success(usageStatsList)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error fetching 6 months usage stats: ${e.message}")
                        result.error("USAGE_ERROR", "Failed to retrieve 6 months usage stats.", e.message)
                    }
                }
                // Get 1 year usage statistics
                "get1YearUsageStats" -> {
                    try {
                        val usageStatsList = get1YearUsageStats(this)
                        result.success(usageStatsList)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error fetching 1 year usage stats: ${e.message}")
                        result.error("USAGE_ERROR", "Failed to retrieve 1 year usage stats.", e.message)
                    }
                }
                // Block app (placeholder)
                "blockApp" -> {
                    val appName = call.argument<String>("appName")
                    Toast.makeText(this, "Block logic initiated for: $appName", Toast.LENGTH_LONG).show()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // Check Device Admin status
    private fun checkDeviceAdminActive(context: Context): Boolean {
        val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val componentName = ComponentName(context, DeviceAdminReceiver::class.java)
        return devicePolicyManager.isAdminActive(componentName)
    }

    // Request Device Admin permission
    private fun requestDeviceAdminPermission(context: Context) {
        try {
            val componentName = ComponentName(context, DeviceAdminReceiver::class.java)
            val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager

            if (!devicePolicyManager.isAdminActive(componentName)) {
                val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
                intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "This permission prevents unauthorized uninstallation and tampering.")
                context.startActivity(intent)
            } else {
                Toast.makeText(context, "Device Admin already enabled.", Toast.LENGTH_SHORT).show()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to request device admin: ${e.message}")
            Toast.makeText(context, "Failed to open Device Admin settings.", Toast.LENGTH_LONG).show()
        }
    }

    // Request Usage Access permission
    private fun requestUsageAccessPermission(context: Context) {
        if (!hasUsageAccessPermission(context)) {
            try {
                val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                context.startActivity(intent)
            } catch (e: Exception) {
                Toast.makeText(context, "Cannot open Usage Access settings.", Toast.LENGTH_LONG).show()
            }
        } else {
            Toast.makeText(context, "Usage Access already granted.", Toast.LENGTH_SHORT).show()
        }
    }

    // Check Usage Access permission
    private fun hasUsageAccessPermission(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
            return mode == AppOpsManager.MODE_ALLOWED
        }
        return false
    }

    // Get usage statistics for the last 24 hours
    private fun getUsageStats(context: Context): List<Map<String, Any>> {
        if (!hasUsageAccessPermission(context)) {
            Log.w(TAG, "Usage access permission not granted")
            return emptyList()
        }

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val packageManager = context.packageManager

        // Get stats for last 24 hours with more precise timing
        val calendar = Calendar.getInstance()
        val endTime = System.currentTimeMillis()
        calendar.add(Calendar.HOUR_OF_DAY, -24) // More precise: 24 hours ago
        val startTime = calendar.timeInMillis

        Log.d(TAG, "Querying usage stats from $startTime to $endTime")

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        val usageList = mutableListOf<Map<String, Any>>()
        val appUsageMap = mutableMapOf<String, Long>() // Aggregate usage by package

        // Aggregate usage data to avoid duplicates and get more accurate totals
        stats?.forEach { usageStats ->
            if (usageStats.totalTimeInForeground > 0) {
                val packageName = usageStats.packageName
                val currentTime = appUsageMap[packageName] ?: 0L
                appUsageMap[packageName] = currentTime + usageStats.totalTimeInForeground
            }
        }

        // Convert aggregated data to final format
        appUsageMap.forEach { (packageName, totalTime) ->
            try {
                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                val appName = packageManager.getApplicationLabel(appInfo).toString()
                val totalTimeInSeconds = (totalTime / 1000).toInt()

                // Filter out system apps and very short usage times
                if (totalTimeInSeconds >= 1 && !isSystemApp(packageName)) {
                    val usageMap = mapOf(
                        "appName" to appName,
                        "packageName" to packageName,
                        "totalTimeInSeconds" to totalTimeInSeconds
                    )
                    usageList.add(usageMap)
                    Log.d(TAG, "App: $appName, Time: ${totalTimeInSeconds}s")
                }
            } catch (e: PackageManager.NameNotFoundException) {
                Log.w(TAG, "Package not found: $packageName")
            }
        }

        Log.d(TAG, "Total apps with usage: ${usageList.size}")
        return usageList.sortedByDescending { it["totalTimeInSeconds"] as Int }
    }

    // Helper function to identify system apps
    private fun isSystemApp(packageName: String): Boolean {
        val systemApps = listOf(
            "android",
            "com.android.systemui",
            "com.android.settings",
            "com.android.launcher",
            "com.google.android.gms",
            "com.google.android.gsf"
        )
        return systemApps.any { packageName.startsWith(it) }
    }

    // Get usage statistics for the last 7 days
    private fun getWeeklyUsageStats(context: Context): List<Map<String, Any>> {
        if (!hasUsageAccessPermission(context)) {
            Log.w(TAG, "Usage access permission not granted")
            return emptyList()
        }

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val packageManager = context.packageManager

        // Get stats for last 7 days with more precise timing
        val calendar = Calendar.getInstance()
        val endTime = System.currentTimeMillis()
        calendar.add(Calendar.DAY_OF_YEAR, -7)
        val startTime = calendar.timeInMillis

        Log.d(TAG, "Querying weekly usage stats from $startTime to $endTime")

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_WEEKLY,
            startTime,
            endTime
        )

        val usageList = mutableListOf<Map<String, Any>>()
        val appUsageMap = mutableMapOf<String, Long>()

        // Aggregate usage data
        stats?.forEach { usageStats ->
            if (usageStats.totalTimeInForeground > 0) {
                val packageName = usageStats.packageName
                val currentTime = appUsageMap[packageName] ?: 0L
                appUsageMap[packageName] = currentTime + usageStats.totalTimeInForeground
            }
        }

        // Convert aggregated data to final format
        appUsageMap.forEach { (packageName, totalTime) ->
            try {
                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                val appName = packageManager.getApplicationLabel(appInfo).toString()
                val totalTimeInSeconds = (totalTime / 1000).toInt()

                if (totalTimeInSeconds >= 5 && !isSystemApp(packageName)) {
                    val usageMap = mapOf(
                        "appName" to appName,
                        "packageName" to packageName,
                        "totalTimeInSeconds" to totalTimeInSeconds
                    )
                    usageList.add(usageMap)
                }
            } catch (e: PackageManager.NameNotFoundException) {
                Log.w(TAG, "Package not found: $packageName")
            }
        }

        Log.d(TAG, "Weekly total apps with usage: ${usageList.size}")
        return usageList.sortedByDescending { it["totalTimeInSeconds"] as Int }
    }

    // Get usage statistics for the last 30 days
    private fun getMonthlyUsageStats(context: Context): List<Map<String, Any>> {
        if (!hasUsageAccessPermission(context)) {
            return emptyList()
        }

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val packageManager = context.packageManager

        // Get stats for last 30 days
        val calendar = Calendar.getInstance()
        val endTime = System.currentTimeMillis()
        calendar.add(Calendar.DAY_OF_YEAR, -30)
        val startTime = calendar.timeInMillis

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_MONTHLY,
            startTime,
            endTime
        )

        val usageList = mutableListOf<Map<String, Any>>()

        stats?.filter { it.totalTimeInForeground > 0 }?.forEach { usageStats ->
            try {
                val packageName = usageStats.packageName
                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                val appName = packageManager.getApplicationLabel(appInfo).toString()
                val totalTimeInSeconds = (usageStats.totalTimeInForeground / 1000).toInt()

                val usageMap = mapOf(
                    "appName" to appName,
                    "packageName" to packageName,
                    "totalTimeInSeconds" to totalTimeInSeconds
                )
                usageList.add(usageMap)
            } catch (e: PackageManager.NameNotFoundException) {
                Log.w(TAG, "Package not found: ${usageStats.packageName}")
            }
        }

        return usageList.sortedByDescending { it["totalTimeInSeconds"] as Int }
    }

    // Get usage statistics for the last 3 months
    private fun get3MonthsUsageStats(context: Context): List<Map<String, Any>> {
        if (!hasUsageAccessPermission(context)) {
            return emptyList()
        }

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val packageManager = context.packageManager

        // Get stats for last 3 months
        val calendar = Calendar.getInstance()
        val endTime = System.currentTimeMillis()
        calendar.add(Calendar.MONTH, -3)
        val startTime = calendar.timeInMillis

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_MONTHLY,
            startTime,
            endTime
        )

        val usageList = mutableListOf<Map<String, Any>>()

        stats?.filter { it.totalTimeInForeground > 0 }?.forEach { usageStats ->
            try {
                val packageName = usageStats.packageName
                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                val appName = packageManager.getApplicationLabel(appInfo).toString()
                val totalTimeInSeconds = (usageStats.totalTimeInForeground / 1000).toInt()

                val usageMap = mapOf(
                    "appName" to appName,
                    "packageName" to packageName,
                    "totalTimeInSeconds" to totalTimeInSeconds
                )
                usageList.add(usageMap)
            } catch (e: PackageManager.NameNotFoundException) {
                Log.w(TAG, "Package not found: ${usageStats.packageName}")
            }
        }

        return usageList.sortedByDescending { it["totalTimeInSeconds"] as Int }
    }

    // Get usage statistics for the last 6 months
    private fun get6MonthsUsageStats(context: Context): List<Map<String, Any>> {
        if (!hasUsageAccessPermission(context)) {
            return emptyList()
        }

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val packageManager = context.packageManager

        // Get stats for last 6 months
        val calendar = Calendar.getInstance()
        val endTime = System.currentTimeMillis()
        calendar.add(Calendar.MONTH, -6)
        val startTime = calendar.timeInMillis

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_MONTHLY,
            startTime,
            endTime
        )

        val usageList = mutableListOf<Map<String, Any>>()

        stats?.filter { it.totalTimeInForeground > 0 }?.forEach { usageStats ->
            try {
                val packageName = usageStats.packageName
                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                val appName = packageManager.getApplicationLabel(appInfo).toString()
                val totalTimeInSeconds = (usageStats.totalTimeInForeground / 1000).toInt()

                val usageMap = mapOf(
                    "appName" to appName,
                    "packageName" to packageName,
                    "totalTimeInSeconds" to totalTimeInSeconds
                )
                usageList.add(usageMap)
            } catch (e: PackageManager.NameNotFoundException) {
                Log.w(TAG, "Package not found: ${usageStats.packageName}")
            }
        }

        return usageList.sortedByDescending { it["totalTimeInSeconds"] as Int }
    }

    // Get usage statistics for the last 1 year
    private fun get1YearUsageStats(context: Context): List<Map<String, Any>> {
        if (!hasUsageAccessPermission(context)) {
            return emptyList()
        }

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val packageManager = context.packageManager

        // Get stats for last 1 year
        val calendar = Calendar.getInstance()
        val endTime = System.currentTimeMillis()
        calendar.add(Calendar.YEAR, -1)
        val startTime = calendar.timeInMillis

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_YEARLY,
            startTime,
            endTime
        )

        val usageList = mutableListOf<Map<String, Any>>()

        stats?.filter { it.totalTimeInForeground > 0 }?.forEach { usageStats ->
            try {
                val packageName = usageStats.packageName
                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                val appName = packageManager.getApplicationLabel(appInfo).toString()
                val totalTimeInSeconds = (usageStats.totalTimeInForeground / 1000).toInt()

                val usageMap = mapOf(
                    "appName" to appName,
                    "packageName" to packageName,
                    "totalTimeInSeconds" to totalTimeInSeconds
                )
                usageList.add(usageMap)
            } catch (e: PackageManager.NameNotFoundException) {
                Log.w(TAG, "Package not found: ${usageStats.packageName}")
            }
        }

        return usageList.sortedByDescending { it["totalTimeInSeconds"] as Int }
    }

    // Validate usage data accuracy
    private fun validateUsageDataAccuracy(context: Context): Map<String, Any> {
        val hasPermission = hasUsageAccessPermission(context)
        val currentTime = System.currentTimeMillis()
        val oneDayAgo = currentTime - (24 * 60 * 60 * 1000)
        
        val validationResult = mutableMapOf<String, Any>()
        validationResult["hasPermission"] = hasPermission
        validationResult["currentTime"] = currentTime
        validationResult["oneDayAgo"] = oneDayAgo
        
        if (hasPermission) {
            try {
                val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                val stats = usageStatsManager.queryUsageStats(
                    UsageStatsManager.INTERVAL_DAILY,
                    oneDayAgo,
                    currentTime
                )
                
                val totalApps = stats?.size ?: 0
                val appsWithUsage = stats?.count { it.totalTimeInForeground > 0 } ?: 0
                val totalUsageTime = stats?.sumOf { it.totalTimeInForeground } ?: 0L
                
                validationResult["totalApps"] = totalApps
                validationResult["appsWithUsage"] = appsWithUsage
                validationResult["totalUsageTime"] = totalUsageTime
                validationResult["isDataAccurate"] = totalApps > 0 && appsWithUsage > 0
                
                Log.d(TAG, "Validation: $totalApps total apps, $appsWithUsage with usage, ${totalUsageTime/1000}s total time")
            } catch (e: Exception) {
                Log.e(TAG, "Error during validation: ${e.message}")
                validationResult["error"] = e.message ?: "Unknown error"
            }
        }
        
        return validationResult
    }
}
