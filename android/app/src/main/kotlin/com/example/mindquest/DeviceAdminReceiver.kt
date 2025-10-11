package com.example.mindquest

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class DeviceAdminReceiver : DeviceAdminReceiver() {
    
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.d("ParentalControl", "Device admin enabled - Anti-removal protection active")
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.d("ParentalControl", "Device admin disabled - Anti-removal protection removed")
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        // This method is called when the user tries to disable device admin
        // You can show a warning message here
        return "Disabling device admin will remove parental control protection features. This may allow children to uninstall the app or access restricted content."
    }

    override fun onPasswordChanged(context: Context, intent: Intent, user: android.os.UserHandle) {
        super.onPasswordChanged(context, intent, user)
        Log.d("ParentalControl", "Password changed - Parental control may need reconfiguration")
    }

    override fun onPasswordFailed(context: Context, intent: Intent, user: android.os.UserHandle) {
        super.onPasswordFailed(context, intent, user)
        Log.d("ParentalControl", "Password failed - Potential unauthorized access attempt")
    }
}



