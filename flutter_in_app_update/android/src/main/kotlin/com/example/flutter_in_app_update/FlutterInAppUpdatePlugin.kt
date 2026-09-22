package com.example.flutter_in_app_update

import android.app.Activity
import android.content.Intent
import android.net.Uri
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class FlutterInAppUpdatePlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener, EventChannel.StreamHandler {

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var activity: Activity? = null
    private var appUpdateManager: AppUpdateManager? = null
    private var pendingResult: Result? = null
    private var pluginBinding: ActivityPluginBinding? = null

    companion object {
        private const val REQUEST_CODE_START_UPDATE = 4242
    }

    private val installStateUpdatedListener = InstallStateUpdatedListener { state ->
        eventSink?.success(state.installStatus())
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_in_app_update")
        methodChannel?.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_in_app_update_events")
        eventChannel?.setStreamHandler(this)
        
        appUpdateManager = AppUpdateManagerFactory.create(flutterPluginBinding.applicationContext)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val currentActivity = activity
        val updateManager = appUpdateManager

        if (updateManager == null) {
            result.error("UNAVAILABLE", "AppUpdateManager is not available.", null)
            return
        }

        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "checkForUpdate" -> {
                updateManager.appUpdateInfo.addOnSuccessListener { appUpdateInfo ->
                    val map = mapOf(
                        "isUpdateAvailable" to (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE),
                        "availableVersion" to appUpdateInfo.availableVersionCode().toString(),
                        "currentBuildNumber" to 0, 
                        "availableBuildNumber" to appUpdateInfo.availableVersionCode(),
                        "immediateUpdateAllowed" to appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE),
                        "flexibleUpdateAllowed" to appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE),
                        "updatePriority" to appUpdateInfo.updatePriority(),
                        "clientVersionStalenessDays" to appUpdateInfo.clientVersionStalenessDays(),
                        "installStatus" to appUpdateInfo.installStatus(),
                        "availability" to appUpdateInfo.updateAvailability(),
                        "platform" to "android"
                    )
                    result.success(map)
                }.addOnFailureListener {
                    result.error("UPDATE_CHECK_FAILED", it.message, null)
                }
            }
            "startFlexibleUpdate" -> {
                startUpdate(AppUpdateType.FLEXIBLE, currentActivity, updateManager, result)
            }
            "startImmediateUpdate" -> {
                startUpdate(AppUpdateType.IMMEDIATE, currentActivity, updateManager, result)
            }
            "completeFlexibleUpdate" -> {
                updateManager.completeUpdate().addOnSuccessListener {
                    result.success(null)
                }.addOnFailureListener {
                    result.error("COMPLETE_UPDATE_FAILED", it.message, null)
                }
            }
            "openStore" -> {
                if (currentActivity != null) {
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=${currentActivity.packageName}"))
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        currentActivity.startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=${currentActivity.packageName}"))
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            currentActivity.startActivity(intent)
                            result.success(null)
                        } catch (e2: Exception) {
                            result.error("OPEN_STORE_FAILED", e2.message, null)
                        }
                    }
                } else {
                    result.error("NO_ACTIVITY", "Activity is null", null)
                }
            }
            else -> result.notImplemented()
        }
    }
    
    private fun startUpdate(updateType: Int, currentActivity: Activity?, updateManager: AppUpdateManager, result: Result) {
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity is null", null)
            return
        }
        
        if (pendingResult != null) {
            result.error("ALREADY_IN_PROGRESS", "An update flow is already in progress.", null)
            return
        }
        
        pendingResult = result

        updateManager.appUpdateInfo.addOnSuccessListener { appUpdateInfo ->
            if (appUpdateInfo.isUpdateTypeAllowed(updateType)) {
                try {
                    updateManager.startUpdateFlowForResult(
                        appUpdateInfo,
                        updateType,
                        currentActivity,
                        REQUEST_CODE_START_UPDATE
                    )
                } catch (e: Exception) {
                    pendingResult?.error("START_UPDATE_FAILED", e.message, null)
                    pendingResult = null
                }
            } else {
                pendingResult?.error("NOT_ALLOWED", "Update type not allowed.", null)
                pendingResult = null
            }
        }.addOnFailureListener {
            pendingResult?.error("CHECK_FAILED", it.message, null)
            pendingResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_START_UPDATE) {
            when (resultCode) {
                Activity.RESULT_OK -> {
                    pendingResult?.success(null)
                }
                Activity.RESULT_CANCELED -> {
                    pendingResult?.error("CANCELED", "User canceled the update.", null)
                }
                else -> {
                    pendingResult?.error("FAILED", "Update failed with code: $resultCode", null)
                }
            }
            pendingResult = null
            return true
        }
        return false
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        pluginBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activity = null
        pluginBinding?.removeActivityResultListener(this)
        pluginBinding = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        appUpdateManager?.unregisterListener(installStateUpdatedListener)
        appUpdateManager = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        appUpdateManager?.registerListener(installStateUpdatedListener)
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        appUpdateManager?.unregisterListener(installStateUpdatedListener)
    }
}
