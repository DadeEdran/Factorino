package io.github.erysaw.factorino

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.io.OutputStream
import java.util.concurrent.Executors

/**
 * Saves a document where the user points, and opens one it has just saved.
 *
 * The only platform channel this application defines, and it is deliberately
 * two halves of one act rather than two features: nothing here can be asked to
 * open a file it did not itself write.
 *
 * ## Why the save is here rather than in a package (D-103)
 *
 * It was `flutter_file_dialog` until the first phone test of the export. That
 * package runs ACTION_CREATE_DOCUMENT correctly and writes the bytes correctly,
 * and then returns `destinationFileUri.path` -- the *path component* of the SAF
 * URI, with the scheme and the authority discarded. What Dart received was
 * `/document/primary:Download/factor-....pdf`: not a content URI, not a
 * filesystem path, and not something any authority can be reconstructed from.
 * So the hand-off below rejected the application's own file on every single
 * Android save, and «باز کردن» did nothing. See D-103.
 *
 * The URI is not recoverable after the fact, so the fix is to not throw it
 * away. The dialog is forty lines of the most ordinary Android there is; the
 * copy loop below is the same shape as the one it replaces, which did work.
 *
 * ## The read grant
 *
 * The viewer is a different process, so the ACTION_VIEW intent carries
 * FLAG_GRANT_READ_URI_PERMISSION. Re-granting is permitted because this
 * application holds the URI under a grant of its own, handed to it by SAF
 * moments earlier -- it is not claiming authority over a provider it does not
 * own. Only `content` URIs are accepted: a `file` URI would raise
 * FileUriExposedException on any current Android, and after the change above
 * there is no path by which one could arrive.
 */
class MainActivity : FlutterActivity() {
    /** The Dart caller waiting on the save dialog, if one is open. */
    private var pendingSave: MethodChannel.Result? = null

    /** The app-private file that dialog is about to copy out. */
    private var pendingSource: String? = null

    /**
     * The copy runs off the main thread.
     *
     * A PDF is small; a backup is the whole database, and blocking the UI
     * thread on it is a freeze the user would read as a crash. Results are
     * posted back with [runOnUiThread] because a [MethodChannel.Result] may
     * only be completed there.
     */
    private val io = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveDocument" -> saveDocument(call, result)
                    "openUri" -> openUri(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        io.shutdown()
        super.onDestroy()
    }

    /**
     * Opens SAF's create-document dialog and copies [sourcePath] into whatever
     * the user creates.
     *
     * Answers with the destination's `content://` URI as a string, or null if
     * the user backed out -- a cancellation is an ordinary outcome and must not
     * reach Dart as an error.
     */
    private fun saveDocument(call: MethodCall, result: MethodChannel.Result) {
        val sourcePath = call.argument<String>("sourcePath")
        val fileName = call.argument<String>("fileName")
        val mimeType = call.argument<String>("mimeType") ?: DEFAULT_MIME_TYPE

        if (sourcePath == null || fileName == null) {
            result.error("bad_arguments", "sourcePath and fileName are required", null)
            return
        }

        // One dialog at a time. Overwriting the pending result would strand the
        // earlier caller on a future that never completes.
        if (pendingSave != null) {
            result.error("dialog_already_open", "a save dialog is already open", null)
            return
        }

        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
            putExtra(Intent.EXTRA_TITLE, fileName)
        }

        pendingSave = result
        pendingSource = sourcePath
        try {
            startActivityForResult(intent, REQUEST_CREATE_DOCUMENT)
        } catch (error: ActivityNotFoundException) {
            pendingSave = null
            pendingSource = null
            result.error("no_document_ui", "this device has no document provider", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_CREATE_DOCUMENT) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }

        val result = pendingSave
        val sourcePath = pendingSource
        pendingSave = null
        pendingSource = null
        if (result == null) return

        val destination = if (resultCode == Activity.RESULT_OK) data?.data else null
        if (destination == null || sourcePath == null) {
            result.success(null)
            return
        }

        io.execute {
            try {
                copyInto(File(sourcePath), destination)
                // **`toString()`, and this is the whole point of the file.**
                // `destination.path` is what the package returned, and it is
                // not a URI. See D-103.
                runOnUiThread { result.success(destination.toString()) }
            } catch (error: Exception) {
                // No path and no URI in the message: §7 keeps the user's
                // directory structure out of logs as firmly as their customers.
                runOnUiThread { result.error("save_failed", "could not write the document", null) }
            }
        }
    }

    private fun copyInto(source: File, destination: Uri) {
        source.inputStream().use { input ->
            openTruncating(destination).use { output -> input.copyTo(output) }
        }
    }

    /**
     * Opens [destination] for writing, discarding anything already in it.
     *
     * ACTION_CREATE_DOCUMENT normally hands back a new, empty document, so this
     * matters only when the user picks an existing file to overwrite -- and
     * without it a shorter document would be written over a longer one and keep
     * the old tail, which for a PDF means a file no reader will open. Mode
     * `"wt"` is the documented way to ask for truncation; a provider that does
     * not implement it raises, and the plain mode is the honest fallback.
     */
    private fun openTruncating(destination: Uri): OutputStream {
        val truncating = try {
            contentResolver.openOutputStream(destination, "wt")
        } catch (error: IllegalArgumentException) {
            null
        }
        return truncating
            ?: contentResolver.openOutputStream(destination)
            ?: throw IOException("the document provider returned no output stream")
    }

    /** Hands a saved document to whatever the user already reads PDFs with. */
    private fun openUri(call: MethodCall, result: MethodChannel.Result) {
        val raw = call.argument<String>("uri")
        if (raw == null) {
            result.success(false)
            return
        }

        val uri = Uri.parse(raw)
        if (uri.scheme != "content") {
            result.success(false)
            return
        }

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, PDF_MIME_TYPE)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        // No FLAG_ACTIVITY_NEW_TASK: launched from an activity, the viewer
        // joins this task, so the back gesture returns to the invoice rather
        // than leaving the user in a separate task with no way back.
        //
        // `resolveActivity` needs the <queries> entry in the manifest to see
        // past API 30's package-visibility filtering; the catch stays anyway,
        // because a resolution that succeeds can still fail to launch.
        if (intent.resolveActivity(packageManager) == null) {
            result.success(false)
            return
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

    private companion object {
        // l10n-exempt: platform identifiers, not user-facing copy.
        const val CHANNEL = "io.github.erysaw.factorino/documents"
        const val PDF_MIME_TYPE = "application/pdf"
        const val DEFAULT_MIME_TYPE = "application/octet-stream"
        const val REQUEST_CREATE_DOCUMENT = 0x0FAC
    }
}
