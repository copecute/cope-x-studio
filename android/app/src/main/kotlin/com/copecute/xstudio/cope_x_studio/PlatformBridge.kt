package com.copecute.xstudio.cope_x_studio

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.util.Base64
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.util.Locale

class PlatformBridge(private val activity: MainActivity) : MethodChannel.MethodCallHandler {

    fun register(messenger: io.flutter.plugin.common.BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "listDirectoryShell" -> {
                    val path = call.argument<String>("path") ?: "/"
                    val showHidden = call.argument<Boolean>("showHidden") ?: false
                    result.success(listDirectoryShell(path, showHidden))
                }
                "listInstalledApps" -> {
                    val systemApps = call.argument<Boolean>("systemApps") ?: false
                    result.success(listInstalledApps(systemApps))
                }
                "openAppSettings" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrBlank()) {
                        result.error("ARG", "packageName required", null)
                        return
                    }
                    openAppSettings(packageName)
                    result.success(true)
                }
                "openPlayStore" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrBlank()) {
                        result.error("ARG", "packageName required", null)
                        return
                    }
                    openPlayStore(packageName)
                    result.success(true)
                }
                "openApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrBlank()) {
                        result.error("ARG", "packageName required", null)
                        return
                    }
                    openApp(packageName)
                    result.success(true)
                }
                "uninstallApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrBlank()) {
                        result.error("ARG", "packageName required", null)
                        return
                    }
                    uninstallApp(packageName)
                    result.success(true)
                }
                "backupApk" -> {
                    val packageName = call.argument<String>("packageName")
                    val destPath = call.argument<String>("destPath")
                    if (packageName.isNullOrBlank() || destPath.isNullOrBlank()) {
                        result.error("ARG", "packageName and destPath required", null)
                        return
                    }
                    result.success(backupApk(packageName, destPath))
                }
                "getApkPath" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrBlank()) {
                        result.error("ARG", "packageName required", null)
                        return
                    }
                    result.success(getApkPath(packageName))
                }
                "getAppIcon" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrBlank()) {
                        result.error("ARG", "packageName required", null)
                        return
                    }
                    result.success(getAppIconBase64(packageName))
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("ERR", e.message, null)
        }
    }

    private fun listDirectoryShell(path: String, showHidden: Boolean): List<Map<String, Any?>> {
        val flag = if (showHidden) "-1Ap" else "-1p"
        val escaped = shellEscape(path)
        val commands = listOf(
            arrayOf("/system/bin/ls", flag, path),
            arrayOf("/system/bin/toybox", "ls", flag, path),
            arrayOf("ls", flag, path),
            arrayOf("/system/bin/sh", "-c", "ls $flag $escaped"),
            arrayOf("sh", "-c", "ls $flag $escaped"),
        )

        var lastError = "Không thể đọc thư mục"
        for (cmd in commands) {
            try {
                val process = Runtime.getRuntime().exec(cmd)
                val output = readStream(process.inputStream)
                val error = readStream(process.errorStream)
                val code = process.waitFor()
                if (code == 0) {
                    return if (output.isBlank()) {
                        emptyList()
                    } else {
                        parseLsOutput(output, path, showHidden)
                    }
                }
                if (error.isNotBlank()) lastError = error.trim()
            } catch (e: Exception) {
                lastError = e.message ?: lastError
            }
        }
        throw Exception(lastError)
    }

    private fun parseLsOutput(output: String, dirPath: String, showHidden: Boolean): List<Map<String, Any?>> {
        val base = if (dirPath.endsWith("/")) dirPath.dropLast(1) else dirPath
        val entries = mutableListOf<Map<String, Any?>>()

        for (rawLine in output.split('\n')) {
            val line = rawLine.trim()
            if (line.isEmpty() || line == "." || line == "..") continue

            val isDir = line.endsWith('/')
            val name = if (isDir) line.dropLast(1) else line
            if (name.isEmpty()) continue
            if (!showHidden && name.startsWith('.')) continue

            val fullPath = if (base.isEmpty() || base == "/") "/$name" else "$base/$name"
            entries.add(
                mapOf(
                    "name" to name,
                    "path" to fullPath,
                    "isDirectory" to isDir,
                )
            )
        }

        entries.sortWith(compareBy<Map<String, Any?>> { !(it["isDirectory"] as Boolean) }
            .thenBy { (it["name"] as String).lowercase(Locale.getDefault()) })

        return entries
    }

    private fun listInstalledApps(systemApps: Boolean): List<Map<String, Any?>> {
        val pm = activity.packageManager
        val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        val result = mutableListOf<Map<String, Any?>>()

        for (app in apps) {
            val isSystem = (app.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            val isUpdatedSystem = (app.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
            val isSystemCategory = isSystem && !isUpdatedSystem
            val isUserCategory = !isSystem || isUpdatedSystem

            if (systemApps && !isSystemCategory) continue
            if (!systemApps && !isUserCategory) continue

            val packageName = app.packageName
            if (pm.getLaunchIntentForPackage(packageName) == null) continue

            val label = pm.getApplicationLabel(app).toString()
            val apkPath = app.sourceDir ?: app.publicSourceDir ?: continue
            val apkFile = File(apkPath)
            val apkSize = if (apkFile.exists()) apkFile.length() else 0L

            var versionName = ""
            var versionCode = 0L
            var installTime = 0L
            var updateTime = 0L
            try {
                val pkg = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
                } else {
                    @Suppress("DEPRECATION")
                    pm.getPackageInfo(packageName, 0)
                }
                versionName = pkg.versionName ?: ""
                versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    pkg.longVersionCode
                } else {
                    @Suppress("DEPRECATION")
                    pkg.versionCode.toLong()
                }
                installTime = pkg.firstInstallTime
                updateTime = pkg.lastUpdateTime
            } catch (_: Exception) {
            }

            result.add(
                mapOf(
                    "packageName" to packageName,
                    "appName" to label,
                    "versionName" to versionName,
                    "versionCode" to versionCode,
                    "installTime" to installTime,
                    "updateTime" to updateTime,
                    "apkSize" to apkSize,
                    "apkPath" to apkPath,
                    "isSystem" to isSystemCategory,
                )
            )
        }

        result.sortBy { (it["appName"] as String).lowercase(Locale.getDefault()) }
        return result
    }

    private fun openAppSettings(packageName: String) {
        val intent = Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        activity.startActivity(intent)
    }

    private fun openPlayStore(packageName: String) {
        val market = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$packageName")).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        val web = Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=$packageName")).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        try {
            activity.startActivity(market)
        } catch (_: Exception) {
            activity.startActivity(web)
        }
    }

    private fun openApp(packageName: String) {
        val pm = activity.packageManager
        val intent = pm.getLaunchIntentForPackage(packageName)
        if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            activity.startActivity(intent)
        } else {
            throw Exception("Không thể mở ứng dụng: Không tìm thấy Launch Intent")
        }
    }

    private fun uninstallApp(packageName: String) {
        val intent = Intent(Intent.ACTION_DELETE, Uri.parse("package:$packageName")).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        activity.startActivity(intent)
    }

    private fun backupApk(packageName: String, destPath: String): String {
        val source = getApkPath(packageName)
        val dest = File(destPath)
        dest.parentFile?.mkdirs()
        File(source).copyTo(dest, overwrite = true)
        return dest.absolutePath
    }

    private fun getApkPath(packageName: String): String {
        val app = activity.packageManager.getApplicationInfo(packageName, 0)
        return app.sourceDir ?: app.publicSourceDir
        ?: throw Exception("Không tìm thấy APK")
    }

    private fun getAppIconBase64(packageName: String): String? {
        return try {
            val pm = activity.packageManager
            val app = pm.getApplicationInfo(packageName, 0)
            drawableToBase64(app.loadIcon(pm))
        } catch (_: Exception) {
            null
        }
    }

    private fun drawableToBase64(drawable: Drawable): String {
        val size = (96 * activity.resources.displayMetrics.density).toInt().coerceAtLeast(48)
        val bitmap = when (drawable) {
            is BitmapDrawable -> {
                if (drawable.bitmap != null) {
                    Bitmap.createScaledBitmap(drawable.bitmap, size, size, true)
                } else {
                    bitmapFromDrawable(drawable, size)
                }
            }
            else -> bitmapFromDrawable(drawable, size)
        }
        val stream = java.io.ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 90, stream)
        return Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
    }

    private fun bitmapFromDrawable(drawable: Drawable, size: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(canvas)
        return bitmap
    }

    private fun readStream(stream: java.io.InputStream): String {
        return BufferedReader(InputStreamReader(stream)).use { it.readText() }
    }

    private fun shellEscape(path: String): String {
        return "'" + path.replace("'", "'\\''") + "'"
    }

    companion object {
        const val CHANNEL = "cope_x_studio/platform"
    }
}
