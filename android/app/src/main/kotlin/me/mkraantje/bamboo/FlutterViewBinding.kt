package me.mkraantje.bamboo

import android.content.Context
import android.content.Intent
import android.provider.AlarmClock
import android.view.ViewGroup
import android.widget.Toast
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterSurfaceView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class FlutterViewBinding(private val context: Context, private val handler: Handler) {

    lateinit var engine: FlutterEngine
    lateinit var view: FlutterView

    fun init() {
        engine = FlutterEngine(context).apply {
            dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(
                    FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                    "main"
                )
            )
        }

        view = FlutterView(context, FlutterSurfaceView(context, true)).apply {
            layoutParams = ViewGroup.MarginLayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )

            attachToFlutterEngine(engine)
        }
    }

    fun resume() {
        engine.lifecycleChannel.appIsResumed()
    }

    fun pause() {
        engine.lifecycleChannel.appIsPaused()
    }

    fun destroy() {
        engine.lifecycleChannel.appIsDetached()
    }

    interface Handler {
        fun initEngine(engine: FlutterEngine)
    }
}
