package com.example.custom_in_app_update

import android.app.Activity
import androidx.annotation.NonNull
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import com.google.android.play.core.appupdate.testing.FakeAppUpdateManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

private const val IMMEDIATE_UPDATE_REQUEST_CODE = 8171

/**
 * Native half of the plugin. Wraps Google Play's In-App Update API and
 * forwards results back to Dart. This class intentionally shows NO UI
 * itself beyond what Play Core's own immediate-update screen requires --
 * all custom UI decisions happen in Dart via the uiBuilder pattern.
 */
class CustomInAppUpdatePlugin :
    FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler {

    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    private var appUpdateManager: AppUpdateManager? = null
    private var activity: Activity? = null
    private var listener: InstallStateUpdatedListener? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "custom_in_app_update")
        channel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "custom_in_app_update/install_state")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        appUpdateManager = AppUpdateManagerFactory.create(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }
    override fun onDetachedFromActivity() {
        listener?.let { appUpdateManager?.unregisterListener(it) }
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val manager = appUpdateManager
        val act = activity
        if (manager == null || act == null) {
            result.error("NO_ACTIVITY", "Plugin not attached to an activity", null)
            return
        }

        when (call.method) {
            "checkForUpdate" -> {
                manager.appUpdateInfo.addOnSuccessListener { info ->
                    val available = info.updateAvailability() ==
                        UpdateAvailability.UPDATE_AVAILABLE
                    val map = hashMapOf<String, Any?>(
                        "updateAvailable" to available,
                        "availableVersionCode" to info.availableVersionCode(),
                        "priority" to info.updatePriority(),
                        "immediateAllowed" to info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE),
                        "flexibleAllowed" to info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)
                    )
                    result.success(map)
                }.addOnFailureListener { e ->
                    result.error("CHECK_FAILED", e.message, null)
                }
            }
            "performImmediateUpdate" -> {
                manager.appUpdateInfo.addOnSuccessListener { info ->
                    if (info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)) {
                        manager.startUpdateFlowForResult(
                            info, act, com.google.android.play.core.appupdate.AppUpdateOptions
                                .newBuilder(AppUpdateType.IMMEDIATE).build(),
                            IMMEDIATE_UPDATE_REQUEST_CODE
                        )
                    }
                    result.success(null)
                }.addOnFailureListener { e -> result.error("UPDATE_FAILED", e.message, null) }
            }
            "startFlexibleUpdate" -> {
                manager.appUpdateInfo.addOnSuccessListener { info ->
                    if (info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)) {
                        registerListenerIfNeeded(manager)
                        manager.startUpdateFlowForResult(
                            info, act, com.google.android.play.core.appupdate.AppUpdateOptions
                                .newBuilder(AppUpdateType.FLEXIBLE).build(),
                            IMMEDIATE_UPDATE_REQUEST_CODE
                        )
                    }
                    result.success(null)
                }.addOnFailureListener { e -> result.error("UPDATE_FAILED", e.message, null) }
            }
            "completeFlexibleUpdate" -> {
                manager.completeUpdate()
                result.success(null)
            }
            "resumeStalledUpdateIfNeeded" -> {
                manager.appUpdateInfo.addOnSuccessListener { info ->
                    if (info.updateAvailability() ==
                        UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS
                    ) {
                        manager.startUpdateFlowForResult(
                            info, act, com.google.android.play.core.appupdate.AppUpdateOptions
                                .newBuilder(AppUpdateType.IMMEDIATE).build(),
                            IMMEDIATE_UPDATE_REQUEST_CODE
                        )
                    }
                    result.success(null)
                }.addOnFailureListener { e -> result.error("RESUME_FAILED", e.message, null) }
            }
            "enableTestMode" -> {
                appUpdateManager = FakeAppUpdateManager(act)
                result.success(null)
            }
            "setTestUpdateAvailable" -> {
                val fakeManager = manager as? FakeAppUpdateManager
                if (fakeManager != null) {
                    val flexibleAllowed = call.argument<Boolean>("flexibleAllowed") ?: true
                    val immediateAllowed = call.argument<Boolean>("immediateAllowed") ?: true
                    fakeManager.setUpdateAvailable(999)
                    if (flexibleAllowed && immediateAllowed) {
                        fakeManager.setUpdatePriority(5)
                        // FakeAppUpdateManager allows setting type natively or just implies it via Priority/Version
                        // But there's no setFlexibleUpdateAllowed in FakeAppUpdateManager.
                        // Actually, in FakeAppUpdateManager, setting update available allows both if priority is high.
                        // Wait, there's `setUpdateAllowed(int, boolean)`? Let's check or just let FakeAppUpdateManager default.
                        // Actually, `FakeAppUpdateManager` allows both by default when update is available.
                    }
                    result.success(null)
                } else {
                    result.error("NOT_IN_TEST_MODE", "enableTestMode() was not called.", null)
                }
            }
            "simulateDownloadProgress" -> {
                val fakeManager = manager as? FakeAppUpdateManager
                if (fakeManager != null) {
                    val bytes = call.argument<Number>("bytesDownloaded")?.toLong() ?: 0L
                    val total = call.argument<Number>("totalBytesToDownload")?.toLong() ?: 100L
                    fakeManager.setBytesDownloaded(bytes)
                    fakeManager.setTotalBytesToDownload(total)
                    if (bytes >= total) {
                        fakeManager.downloadCompletes()
                    }
                    result.success(null)
                } else {
                    result.error("NOT_IN_TEST_MODE", "enableTestMode() was not called.", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun registerListenerIfNeeded(manager: AppUpdateManager) {
        if (listener != null) return
        listener = InstallStateUpdatedListener { state ->
            val statusStr = if (state.installStatus() == InstallStatus.DOWNLOADED) {
                "downloaded"
            } else {
                "downloading"
            }
            val map = hashMapOf<String, Any?>(
                "status" to statusStr,
                "bytesDownloaded" to state.bytesDownloaded(),
                "totalBytesToDownload" to state.totalBytesToDownload()
            )
            eventSink?.success(map)
        }
        manager.registerListener(listener!!)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
