package io.github.erysaw.factorino

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Opens a document the user has just saved, and nothing else.
 *
 * The single platform method this application defines. It exists because the
 * save dialog is SAF's ACTION_CREATE_DOCUMENT, which returns a content:// URI
 * rather than a path -- so every off-the-shelf "open this file" package, all of
 * which want a FileProvider and a filesystem path, would be solving a problem
 * we do not have while adding a dependency and a manifest provider.
 *
 * It refuses anything that is not a content or file URI, so the channel cannot
 * be used to launch an arbitrary intent. The read grant is passed with the
 * intent because the viewer is a different process; the URI is one this
 * application was itself handed by SAF moments earlier.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "io.github.erysaw.factorino/open_file"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "openUri") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val raw = call.argument<String>("uri")
                if (raw == null) {
                    result.success(false)
                    return@setMethodCallHandler
                }

                val uri = Uri.parse(raw)
                if (uri.scheme != "content" && uri.scheme != "file") {
                    result.success(false)
                    return@setMethodCallHandler
                }

                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, "application/pdf")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }

                try {
                    startActivity(intent)
                    result.success(true)
                } catch (error: ActivityNotFoundException) {
                    // A phone with nothing that reads PDFs is a real phone.
                    // The Dart side reports it in Persian; it is not a fault.
                    result.success(false)
                }
            }
    }
}
