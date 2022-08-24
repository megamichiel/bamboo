package me.mkraantje.bamboo

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.provider.Settings
import android.view.View
import android.view.WindowInsetsController
import android.view.WindowManager
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class LightActivity : FlutterActivity(), FlutterViewBinding.Handler {

    private var _setDarkness = 0

    private lateinit var nightIntent: Intent
    private var nightService: NightBinder? = null
    private val nightConnection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName?, service: IBinder?) {
            nightService = service as NightBinder
            val darkness = nightService!!.darkness
            if (darkness > 0) {
                _setDarkness = darkness
            } else {
                nightService!!.darkness = darkness
            }
        }

        override fun onServiceDisconnected(className: ComponentName?) {
            nightService = null
        }
    }

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

    override fun onStart() {
        super.onStart()

        nightIntent = Intent(this, NightService::class.java)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, CODE_DRAW_OVER_OTHER_APP_PERMISSION)
        } else if ("night" == intent.getStringExtra("state")) {
            _setDarkness = 1
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(nightIntent)
            } else {
                startService(nightIntent)
            }
            bindService(nightIntent, nightConnection, Context.BIND_AUTO_CREATE)
        }
    }

    override fun onStop() {
        super.onStop()

        unbindService(nightConnection)

        if (nightService?.darkness == 0) {
            stopService(nightIntent)
        }
    }

    override fun getTransparencyMode(): TransparencyMode {
        return TransparencyMode.transparent
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == CODE_DRAW_OVER_OTHER_APP_PERMISSION) {
            if (resultCode != RESULT_OK) {
                Toast.makeText(
                    this,
                    "Draw over other app permission not available. Closing the application",
                    Toast.LENGTH_SHORT
                ).show()
                finish()
            }
        } else {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun getDartEntrypointArgs(): MutableList<String> {
        if (intent.hasExtra("state")) {
            return mutableListOf("firefly", intent.getStringExtra("state")!!)
        }
        return mutableListOf("firefly")
    }

    override fun initEngine(engine: FlutterEngine) {
        MethodChannel(
            engine.dartExecutor.binaryMessenger,
            "bamboo/android"
        ).setMethodCallHandler { call, result ->
            when {
                call.method.equals("exit") -> finish()

                call.method.equals("toast") -> Toast.makeText(
                    this,
                    call.argument<String>("message"),
                    Toast.LENGTH_SHORT
                ).show()

                call.method.equals("setNight") -> {
                    val darkness = _setDarkness
                    _setDarkness = call.argument<Int>("value") ?: 0

                    if (_setDarkness != 0) {
                        if (darkness == 0) {
                            nightIntent.putExtra("darkness", _setDarkness)
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                startForegroundService(nightIntent)
                            } else {
                                startService(nightIntent)
                            }
                            bindService(nightIntent, nightConnection, Context.BIND_AUTO_CREATE)
                        } else {
                            nightService?.darkness = _setDarkness
                        }
                    } else if (darkness != 0) {
                        stopService(nightIntent)
                    }
                }

                call.method.equals("getNight") -> result.success(
                    nightService?.darkness ?: _setDarkness
                )
            }
        }
    }

    companion object {
        const val CODE_DRAW_OVER_OTHER_APP_PERMISSION = 2084
    }
}
