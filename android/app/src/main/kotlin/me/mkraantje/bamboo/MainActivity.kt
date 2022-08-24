package me.mkraantje.bamboo

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.AlarmClock
import android.view.View
import android.view.WindowInsetsController
import android.view.WindowManager
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), FlutterViewBinding.Handler {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.setFlags(
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.decorView.setOnApplyWindowInsetsListener { view, insets ->
                window.insetsController?.setSystemBarsAppearance(
                    0,
                    WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
                )
                insets
            }
        } else {
            window.decorView
                .systemUiVisibility =
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
        }

        if (flutterEngine != null)
            initEngine(flutterEngine!!)
    }

    override fun getTransparencyMode(): TransparencyMode {
        return TransparencyMode.transparent
    }

    override fun getDartEntrypointArgs(): MutableList<String> {
        return MutableList(1) { "bamboo" }
    }

    override fun initEngine(engine: FlutterEngine) {
        MethodChannel(
            engine.dartExecutor.binaryMessenger,
            "bamboo/android"
        ).setMethodCallHandler { call, result ->
            when {
                call.method.equals("exit") -> {
                    finish()
                }

                call.method.equals("setTimer") -> {
                    val length = call.argument<Int>("length")
                    if (length != null) {
                        startActivity(
                            Intent(AlarmClock.ACTION_SET_TIMER).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                .putExtra(AlarmClock.EXTRA_LENGTH, length)
                                .putExtra(AlarmClock.EXTRA_SKIP_UI, true)
                        )

                        result.success("Success!")
                    }
                }

                call.method.equals("toast") -> {
                    Toast.makeText(this, call.argument<String>("message"), Toast.LENGTH_SHORT)
                        .show()
                }
            }
        }
    }
}
