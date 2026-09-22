package com.example.my_in_app_update

import android.app.Activity
import android.content.Intent
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallState
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.ActivityResult
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** MyInAppUpdatePlugin */
class MyInAppUpdatePlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.ActivityResultListener {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var appUpdateManager: AppUpdateManager? = null
    private var cachedAppUpdateInfo: AppUpdateInfo? = null
    private var pendingResult: Result? = null

    private val REQUEST_CODE_IMMEDIATE = 7301
    private val REQUEST_CODE_FLEXIBLE = 7302

    private val installStateUpdatedListener = InstallStateUpdatedListener { state: InstallState ->
        val args = HashMap<String, Any>()
        args["installStatus"] = state.installStatus()
        args["bytesDownloaded"] = state.bytesDownloaded()
        args["totalBytesToDownload"] = state.totalBytesToDownload()
        args["installErrorCode"] = state.installErrorCode()
        channel.invokeMethod("onInstallStateChanged", args)
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "my_in_app_update")
        channel.setMethodCallHandler(this)
        appUpdateManager = AppUpdateManagerFactory.create(flutterPluginBinding.applicationContext)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val manager = appUpdateManager
        if (manager == null) {
            result.error("NOT_INITIALIZED", "AppUpdateManager is not initialized", null)
            return
        }

        when (call.method) {
            "checkForUpdate" -> {
                manager.appUpdateInfo
                    .addOnSuccessListener { info ->
                        cachedAppUpdateInfo = info
                        val resultMap = HashMap<String, Any?>()
                        resultMap["updateAvailability"] = info.updateAvailability()
                        resultMap["availableVersionCode"] = info.availableVersionCode()
                        resultMap["immediateAllowed"] = info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)
                        resultMap["flexibleAllowed"] = info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)
                        resultMap["clientVersionStalenessDays"] = info.clientVersionStalenessDays()
                        resultMap["updatePriority"] = info.updatePriority()
                        resultMap["installStatus"] = info.installStatus()
                        result.success(resultMap)
                    }
                    .addOnFailureListener { exception ->
                        result.error("CHECK_UPDATE_FAILED", exception.message, null)
                    }
            }

            "startImmediateUpdate" -> {
                val currentActivity = activity
                if (currentActivity == null) {
                    result.error("NO_ACTIVITY", "Cannot start update without an active foreground Activity", null)
                    return
                }

                fun startFlow(info: AppUpdateInfo) {
                    if (!info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)) {
                        result.error("UPDATE_TYPE_NOT_ALLOWED", "Immediate update is not allowed for this update", null)
                        return
                    }
                    pendingResult = result
                    manager.startUpdateFlowForResult(
                        info,
                        currentActivity,
                        AppUpdateOptions.defaultInstance(AppUpdateType.IMMEDIATE),
                        REQUEST_CODE_IMMEDIATE
                    )
                }

                val cached = cachedAppUpdateInfo
                if (cached != null) {
                    startFlow(cached)
                } else {
                    manager.appUpdateInfo
                        .addOnSuccessListener { info ->
                            cachedAppUpdateInfo = info
                            startFlow(info)
                        }
                        .addOnFailureListener { exception ->
                            result.error("START_UPDATE_FAILED", exception.message, null)
                        }
                }
            }

            "startFlexibleUpdate" -> {
                val currentActivity = activity
                if (currentActivity == null) {
                    result.error("NO_ACTIVITY", "Cannot start update without an active foreground Activity", null)
                    return
                }

                manager.registerListener(installStateUpdatedListener)

                fun startFlow(info: AppUpdateInfo) {
                    if (!info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)) {
                        result.error("UPDATE_TYPE_NOT_ALLOWED", "Flexible update is not allowed for this update", null)
                        return
                    }
                    pendingResult = result
                    manager.startUpdateFlowForResult(
                        info,
                        currentActivity,
                        AppUpdateOptions.defaultInstance(AppUpdateType.FLEXIBLE),
                        REQUEST_CODE_FLEXIBLE
                    )
                }

                val cached = cachedAppUpdateInfo
                if (cached != null) {
                    startFlow(cached)
                } else {
                    manager.appUpdateInfo
                        .addOnSuccessListener { info ->
                            cachedAppUpdateInfo = info
                            startFlow(info)
                        }
                        .addOnFailureListener { exception ->
                            result.error("START_UPDATE_FAILED", exception.message, null)
                        }
                }
            }

            "completeFlexibleUpdate" -> {
                manager.completeUpdate()
                    .addOnSuccessListener {
                        result.success(true)
                    }
                    .addOnFailureListener { exception ->
                        result.error("COMPLETE_UPDATE_FAILED", exception.message, null)
                    }
            }

            else -> result.notImplemented()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_IMMEDIATE || requestCode == REQUEST_CODE_FLEXIBLE) {
            val res = pendingResult
            pendingResult = null
            when (resultCode) {
                Activity.RESULT_OK -> res?.success("OK")
                Activity.RESULT_CANCELED -> res?.error("USER_CANCELED", "User canceled update", null)
                ActivityResult.RESULT_IN_APP_UPDATE_FAILED -> res?.error("UPDATE_FAILED", "In-app update failed", null)
                else -> res?.success("RESULT_CODE_$resultCode")
            }
            return true
        }
        return false
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        appUpdateManager?.unregisterListener(installStateUpdatedListener)
        appUpdateManager = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeActivityResultListener(this)
        activity = null
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activity = null
        activityBinding = null
    }
}
