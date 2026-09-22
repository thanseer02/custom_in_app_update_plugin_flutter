package dev.customappupdate

import android.app.Activity
import android.content.Intent
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallException
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
import io.flutter.plugin.common.PluginRegistry

/** Google Play flexible updates, owned by the Flutter engine, not a UI route. */
class CustomAppUpdatePlugin : FlutterPlugin, ActivityAware,
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler,
    PluginRegistry.ActivityResultListener {

    private companion object {
        const val REQUEST_UPDATE = 51825
    }

    private var manager: AppUpdateManager? = null
    private var methods: MethodChannel? = null
    private var events: EventChannel? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var sink: EventChannel.EventSink? = null
    private var downloadResult: MethodChannel.Result? = null
    private var installResult: MethodChannel.Result? = null
    private val checkResults = mutableSetOf<MethodChannel.Result>()
    private var statusRevision = 0L

    private val listener = InstallStateUpdatedListener { state ->
        statusRevision++
        deliverState(mapOf(
            "installStatus" to state.installStatus(),
            "bytesDownloaded" to state.bytesDownloaded(),
            "totalBytesToDownload" to state.totalBytesToDownload(),
            "errorCode" to state.installErrorCode()
        ))
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        manager = AppUpdateManagerFactory.create(binding.applicationContext).also {
            it.registerListener(listener)
        }
        methods = MethodChannel(binding.binaryMessenger, "dev.customappupdate/methods")
            .also { it.setMethodCallHandler(this) }
        events = EventChannel(binding.binaryMessenger, "dev.customappupdate/events")
            .also { it.setStreamHandler(this) }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val currentManager = manager
        if (currentManager == null) {
            result.error("DETACHED", "The Flutter engine is detached.", null)
            return
        }
        when (call.method) {
            "check" -> {
                checkResults.add(result)
                currentManager.appUpdateInfo
                    .addOnSuccessListener { info ->
                        if (checkResults.remove(result)) result.success(infoMap(info))
                    }
                    .addOnFailureListener { error ->
                        if (checkResults.remove(result)) fail(result, "CHECK_FAILED", error)
                    }
            }
            "download" -> startDownload(currentManager, result)
            "install" -> install(currentManager, result)
            else -> result.notImplemented()
        }
    }

    private fun startDownload(currentManager: AppUpdateManager, result: MethodChannel.Result) {
        if (downloadResult != null || installResult != null) {
            result.error("UPDATE_BUSY", "An update action is already in progress.", null)
            return
        }
        if (activityBinding == null) {
            result.error("NO_ACTIVITY", "Open the app before starting an update.", null)
            return
        }
        downloadResult = result
        // A fresh AppUpdateInfo is required for every consent attempt.
        currentManager.appUpdateInfo.addOnSuccessListener { info ->
            if (downloadResult !== result) return@addOnSuccessListener
            val activity = activityBinding?.activity
            if (activity == null) {
                finishDownloadError("NO_ACTIVITY", "The foreground activity is unavailable.")
                return@addOnSuccessListener
            }
            when (info.installStatus()) {
                InstallStatus.DOWNLOADED -> {
                    deliverState(infoMap(info))
                    return@addOnSuccessListener
                }
                InstallStatus.DOWNLOADING, InstallStatus.PENDING -> {
                    deliverState(infoMap(info))
                    return@addOnSuccessListener
                }
            }
            if (info.updateAvailability() != UpdateAvailability.UPDATE_AVAILABLE ||
                !info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)) {
                finishDownloadError("UPDATE_UNAVAILABLE", "Google Play does not allow a flexible update.")
                return@addOnSuccessListener
            }
            try {
                val started = currentManager.startUpdateFlowForResult(
                    info, activity,
                    AppUpdateOptions.newBuilder(AppUpdateType.FLEXIBLE).build(),
                    REQUEST_UPDATE
                )
                if (!started) finishDownloadError("START_FAILED", "Google Play did not start the update.")
            } catch (error: Exception) {
                finishDownloadError("START_FAILED", error.message, errorDetails(error))
            }
        }.addOnFailureListener { error ->
            if (downloadResult === result) {
                finishDownloadError("CHECK_FAILED", error.message, errorDetails(error))
            }
        }
    }

    private fun install(currentManager: AppUpdateManager, result: MethodChannel.Result) {
        if (installResult != null) {
            result.error("UPDATE_BUSY", "Installation has already been requested.", null)
            return
        }
        if (activityBinding == null) {
            result.error("NO_ACTIVITY", "Return to the app before installing the update.", null)
            return
        }
        installResult = result
        currentManager.appUpdateInfo.addOnSuccessListener { info ->
            if (installResult !== result) return@addOnSuccessListener
            if (info.installStatus() != InstallStatus.DOWNLOADED) {
                installResult = null
                result.error("NOT_DOWNLOADED", "The update has not finished downloading.", null)
                return@addOnSuccessListener
            }
            currentManager.completeUpdate()
                .addOnSuccessListener {
                    if (installResult === result) {
                        installResult = null
                        result.success(null)
                    }
                }
                .addOnFailureListener { error ->
                    if (installResult === result) {
                        installResult = null
                        fail(result, "INSTALL_FAILED", error)
                    }
                }
        }.addOnFailureListener { error ->
            if (installResult === result) {
                installResult = null
                fail(result, "CHECK_FAILED", error)
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_UPDATE) return false
        when (resultCode) {
            Activity.RESULT_CANCELED -> {
                downloadResult?.success("canceled")
                downloadResult = null
                sink?.success(mapOf("installStatus" to InstallStatus.CANCELED))
            }
            Activity.RESULT_OK -> refreshState()
            else -> finishDownloadError("CONSENT_FAILED", "Google Play could not accept the update.", resultCode)
        }
        return true
    }

    private fun deliverState(state: Map<String, Any?>) {
        sink?.success(state)
        when (state["installStatus"]) {
            InstallStatus.DOWNLOADED -> {
                downloadResult?.success("downloaded")
                downloadResult = null
            }
            InstallStatus.CANCELED -> {
                downloadResult?.success("canceled")
                downloadResult = null
            }
            InstallStatus.FAILED -> finishDownloadError(
                "DOWNLOAD_FAILED", "Google Play could not download the update.", state["errorCode"]
            )
        }
    }

    private fun refreshState() {
        val revision = statusRevision
        val currentManager = manager ?: return
        currentManager.appUpdateInfo.addOnSuccessListener { info ->
            if (manager === currentManager && statusRevision == revision) {
                deliverState(infoMap(info))
            }
        }.addOnFailureListener { error ->
            if (manager === currentManager) {
                sink?.error("CHECK_FAILED", error.message, errorDetails(error))
            }
        }
    }

    private fun infoMap(info: AppUpdateInfo): Map<String, Any?> = mapOf(
        "updateAvailability" to info.updateAvailability(),
        "flexibleUpdateAllowed" to info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE),
        "immediateUpdateAllowed" to info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE),
        "flexibleAllowedPreconditions" to info.getFailedUpdatePreconditions(
            AppUpdateOptions.newBuilder(AppUpdateType.FLEXIBLE).build()).toList(),
        "immediateAllowedPreconditions" to info.getFailedUpdatePreconditions(
            AppUpdateOptions.newBuilder(AppUpdateType.IMMEDIATE).build()).toList(),
        "availableVersionCode" to info.availableVersionCode(),
        "installStatus" to info.installStatus(),
        "packageName" to info.packageName(),
        "clientVersionStalenessDays" to info.clientVersionStalenessDays(),
        "updatePriority" to info.updatePriority(),
        "bytesDownloaded" to info.bytesDownloaded(),
        "totalBytesToDownload" to info.totalBytesToDownload(),
        "errorCode" to 0
    )

    private fun errorDetails(error: Exception): Int? = (error as? InstallException)?.errorCode

    private fun fail(result: MethodChannel.Result, code: String, error: Exception) {
        result.error(code, error.message, errorDetails(error))
    }

    private fun finishDownloadError(code: String, message: String?, details: Any? = null) {
        downloadResult?.error(code, message, details)
        downloadResult = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        refreshState()
    }

    override fun onCancel(arguments: Any?) {
        sink = null // The engine listener stays registered while Play downloads.
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addActivityResultListener(this)
        refreshState()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        // Preserve pending work across rotation; the engine remains alive.
    }

    override fun onDetachedFromActivity() {
        onDetachedFromActivityForConfigChanges()
        finishDownloadError("NO_ACTIVITY", "The app activity was detached. Check again after returning.")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        manager?.unregisterListener(listener)
        manager = null
        finishDownloadError("DETACHED", "The Flutter engine was detached.")
        installResult?.error("DETACHED", "The Flutter engine was detached.", null)
        installResult = null
        checkResults.forEach { it.error("DETACHED", "The Flutter engine was detached.", null) }
        checkResults.clear()
        methods?.setMethodCallHandler(null)
        events?.setStreamHandler(null)
        methods = null
        events = null
        sink = null
    }
}
