package com.copecute.xstudio.cope_x_studio

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.util.Base64
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.util.Locale
import java.util.concurrent.TimeUnit

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
                    val useSu = call.argument<Boolean>("useSu") ?: false
                    val mountWritable = call.argument<Boolean>("mountWritable") ?: false
                    result.success(listDirectoryShell(path, showHidden, useSu, mountWritable))
                }
                "checkRootAccess" -> {
                    val mountWritable = call.argument<Boolean>("mountWritable") ?: false
                    result.success(checkRootAccess(mountWritable))
                }
                "installApk" -> {
                    val path = call.argument<String>("apkPath")
                    if (path.isNullOrBlank()) {
                        result.error("ARG", "apkPath required", null)
                        return
                    }
                    activity.runOnUiThread {
                        try {
                            installApk(path)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERR", e.message, null)
                        }
                    }
                    return
                }
                "getApkIconFromPath" -> {
                    val path = call.argument<String>("apkPath")
                    if (path.isNullOrBlank()) {
                        result.error("ARG", "apkPath required", null)
                        return
                    }
                    result.success(getApkIconFromPath(path))
                }
                "getPdfThumbnailFromPath" -> {
                    val path = call.argument<String>("pdfPath")
                    if (path.isNullOrBlank()) {
                        result.error("ARG", "pdfPath required", null)
                        return
                    }
                    val maxSize = call.argument<Int>("maxSize") ?: 120
                    result.success(getPdfThumbnailFromPath(path, maxSize))
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

    private fun listDirectoryShell(
        path: String,
        showHidden: Boolean,
        useSu: Boolean,
        mountWritable: Boolean,
    ): List<Map<String, Any?>> {
        if (useSu && mountWritable) {
            tryRemountWritable(path)
        }

        val flag = if (showHidden) "-1Ap" else "-1p"
        val escaped = shellEscape(path)
        val commands = mutableListOf<Array<String>>()

        if (useSu) {
            commands.add(arrayOf("su", "-c", "ls $flag $escaped"))
            commands.add(arrayOf("su", "0", "ls", flag, path))
        }

        commands.addAll(
            listOf(
                arrayOf("/system/bin/ls", flag, path),
                arrayOf("/system/bin/toybox", "ls", flag, path),
                arrayOf("ls", flag, path),
                arrayOf("/system/bin/sh", "-c", "ls $flag $escaped"),
                arrayOf("sh", "-c", "ls $flag $escaped"),
            )
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
        try {
            val viaFile = listDirectoryViaFile(path, showHidden)
            if (viaFile.isNotEmpty()) return viaFile
        } catch (_: Exception) {
        }

        if (!useSu && (path == "/" || path.isEmpty())) {
            val fallback = listRootFallback(showHidden)
            if (fallback.isNotEmpty()) return fallback
        }

        throw Exception(lastError)
    }

    private fun tryRemountWritable(path: String) {
        val mountPoint = resolveMountPoint(path)
        val commands = listOf(
            "mount -o remount,rw $mountPoint",
            "mount -o rw,remount $mountPoint",
        )
        for (cmd in commands) {
            runSuCommand(cmd)
        }
    }

    private fun resolveMountPoint(path: String): String {
        return when {
            path.startsWith("/system") -> "/system"
            path.startsWith("/vendor") -> "/vendor"
            path.startsWith("/product") -> "/product"
            else -> "/"
        }
    }

    private fun checkRootAccess(mountWritable: Boolean): Map<String, Any?> {
        val idOutput = runSuCommand("id")
        val hasSuperuser = idOutput?.contains("uid=0") == true
        if (!hasSuperuser) {
            return mapOf(
                "granted" to false,
                "message" to "Chưa được cấp quyền siêu người dùng. Thiết bị chưa root hoặc chưa cho phép ứng dụng truy cập root.",
            )
        }

        if (!mountWritable) {
            return mapOf("granted" to true, "message" to "")
        }

        val mountPoint = "/system"
        tryRemountWritable(mountPoint)
        val mountInfo = runSuCommand("mount | grep ' on $mountPoint '")
            ?: runSuCommand("mount | grep $mountPoint")
            ?: ""
        val isWritable = mountInfo.contains(" rw,") ||
            mountInfo.contains(",rw,") ||
            mountInfo.contains(",rw ") ||
            mountInfo.endsWith(" rw") ||
            mountInfo.contains(" rw(")

        if (isWritable) {
            return mapOf("granted" to true, "message" to "")
        }

        val probe = runSuCommand(
            "touch /system/.cope_x_mount_test 2>/dev/null && " +
                "rm -f /system/.cope_x_mount_test 2>/dev/null && echo ok"
        )
        if (probe?.contains("ok") == true) {
            return mapOf("granted" to true, "message" to "")
        }

        return mapOf(
            "granted" to false,
            "message" to "Đã có quyền siêu người dùng nhưng chưa được cấp quyền mount writable (remount rw).",
        )
    }

    private fun runSuCommand(command: String): String? {
        val escaped = shellEscape(command)
        val commands = listOf(
            arrayOf("su", "-c", command),
            arrayOf("su", "0", "sh", "-c", command),
            arrayOf("su", "-c", escaped),
        )
        for (cmd in commands) {
            try {
                val process = Runtime.getRuntime().exec(cmd)
                val completed = process.waitFor(SU_COMMAND_TIMEOUT_SEC, TimeUnit.SECONDS)
                if (!completed) {
                    process.destroy()
                    continue
                }
                val output = readStream(process.inputStream).trim()
                val error = readStream(process.errorStream).trim()
                val code = process.exitValue()
                if (code == 0) {
                    return output.ifBlank { "ok" }
                }
                if (error.contains("not found", ignoreCase = true) ||
                    error.contains("permission denied", ignoreCase = true)
                ) {
                    continue
                }
            } catch (_: Exception) {
            }
        }
        return null
    }

    private fun listDirectoryViaFile(path: String, showHidden: Boolean): List<Map<String, Any?>> {
        val normalized = if (path.isEmpty()) "/" else path
        val dir = File(normalized)
        if (!dir.exists() || !dir.isDirectory) {
            throw Exception("Thư mục không tồn tại")
        }
        val files = dir.listFiles() ?: throw Exception("Không thể đọc thư mục")

        val base = if (normalized.endsWith("/")) normalized.dropLast(1) else normalized
        val entries = mutableListOf<Map<String, Any?>>()
        for (file in files) {
            val name = file.name
            if (name.isEmpty() || name == "." || name == "..") continue
            if (!showHidden && name.startsWith('.')) continue
            val fullPath = if (base.isEmpty() || base == "/") "/$name" else "$base/$name"
            entries.add(
                mapOf(
                    "name" to name,
                    "path" to fullPath,
                    "isDirectory" to file.isDirectory,
                )
            )
        }

        entries.sortWith(
            compareBy<Map<String, Any?>> { !(it["isDirectory"] as Boolean) }
                .thenBy { (it["name"] as String).lowercase(Locale.getDefault()) }
        )
        return entries
    }

    private fun listRootFallback(showHidden: Boolean): List<Map<String, Any?>> {
        val names = listOf(
            "acct", "apex", "bin", "cache", "config", "d", "data", "dev", "etc",
            "linkerconfig", "mnt", "odm", "oem", "opt", "proc", "product", "sbin",
            "sdcard", "storage", "sys", "system", "vendor",
        )
        val entries = mutableListOf<Map<String, Any?>>()
        for (name in names) {
            if (!showHidden && name.startsWith('.')) continue
            val file = File("/$name")
            if (!file.exists()) continue
            entries.add(
                mapOf(
                    "name" to name,
                    "path" to "/$name",
                    "isDirectory" to file.isDirectory,
                )
            )
        }
        entries.sortWith(
            compareBy<Map<String, Any?>> { !(it["isDirectory"] as Boolean) }
                .thenBy { (it["name"] as String).lowercase(Locale.getDefault()) }
        )
        return entries
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

    private fun installApk(apkPath: String) {
        val file = File(apkPath)
        if (!file.exists()) {
            throw Exception("File APK không tồn tại")
        }
        val authority = "${activity.packageName}.fileprovider"
        val uri = FileProvider.getUriForFile(activity, authority, file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        activity.startActivity(Intent.createChooser(intent, "Cài đặt APK"))
    }

    private fun getApkIconFromPath(apkPath: String): String? {
        val file = File(apkPath)
        if (!file.exists()) return null
        val pm = activity.packageManager
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getPackageArchiveInfo(
                apkPath,
                PackageManager.PackageInfoFlags.of(PackageManager.GET_META_DATA.toLong()),
            )
        } else {
            @Suppress("DEPRECATION")
            pm.getPackageArchiveInfo(apkPath, PackageManager.GET_META_DATA)
        } ?: return null

        val appInfo = info.applicationInfo ?: return null
        appInfo.sourceDir = apkPath
        appInfo.publicSourceDir = apkPath
        return try {
            drawableToBase64(appInfo.loadIcon(pm))
        } catch (_: Exception) {
            null
        }
    }

    private fun getPdfThumbnailFromPath(pdfPath: String, maxSize: Int): String? {
        val file = File(pdfPath)
        if (!file.exists()) return null
        return try {
            ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY).use { pfd ->
                PdfRenderer(pfd).use { renderer ->
                    if (renderer.pageCount <= 0) return null
                    renderer.openPage(0).use { page ->
                        val scale = minOf(
                            maxSize.toFloat() / page.width.toFloat(),
                            maxSize.toFloat() / page.height.toFloat(),
                            1f,
                        )
                        val width = (page.width * scale).toInt().coerceAtLeast(1)
                        val height = (page.height * scale).toInt().coerceAtLeast(1)
                        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                        bitmap.eraseColor(Color.WHITE)
                        page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                        bitmapToBase64Png(bitmap)
                    }
                }
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun bitmapToBase64Png(bitmap: Bitmap): String {
        val stream = java.io.ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 90, stream)
        return Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
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
        private const val SU_COMMAND_TIMEOUT_SEC = 5L
    }
}
