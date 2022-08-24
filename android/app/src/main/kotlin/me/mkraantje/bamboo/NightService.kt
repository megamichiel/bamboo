package me.mkraantje.bamboo

import android.app.*
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.Icon
import android.os.Build
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager


class NightService : Service() {

    private var windowManager: WindowManager? = null
    private var view: View? = null

    private lateinit var notification: Notification

    private var _darkness = 0

    override fun onBind(intent: Intent?): NightBinder {
        return NightBinder(object : NightBinder.Listener {
            override fun getDarkness() = _darkness

            override fun setDarkness(value: Int) {
                _darkness = value
                view?.setBackgroundColor(Color.argb(value, 0, 0, 0))
            }

            override fun stop() {
                stopSelf()
            }
        })
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.hasExtra("darkness") == true) {
            _darkness = intent.getIntExtra("darkness", 0) ?: 0
            view?.setBackgroundColor(Color.argb(_darkness, 0, 0, 0))
        }

        return super.onStartCommand(intent, flags, startId)
    }

    override fun onCreate() {
        super.onCreate()

        //Add the view to the window.
        val params: WindowManager.LayoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
            PixelFormat.TRANSLUCENT
        )

        if (Build.VERSION.SDK_INT >= 30) {
            params.fitInsetsSides = 0
            params.fitInsetsTypes = 0
        } else {
            params.systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
        }

        val windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        this.windowManager = windowManager

        windowManager.addView(View(this).apply {
            view = this
            layoutParams = ViewGroup.MarginLayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setBackgroundColor(Color.argb(_darkness, 0, 0, 0))
            addOnLayoutChangeListener { v, _, _, _, _, _, _, _, _ ->
                if (params.y == 0) {
                    val location = IntArray(2) { 0 }
                    v.getLocationOnScreen(location)

                    // For some reason the y shift needs / 2 if params.height is set to this, idk why though but it works
                    params.y = -location[1] / 2
                    params.height = v.height + location[1]

                    windowManager.updateViewLayout(v, params)
                }
            }
        }, params)

        notification = (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Create the NotificationChannel
            notificationManager.createNotificationChannel(
                NotificationChannel(
                    NOTIFICATION_CHANNEL,
                    "Night Light",
                    NotificationManager.IMPORTANCE_DEFAULT
                )
            )
            Notification.Builder(this, NOTIFICATION_CHANNEL)
        } else {
            Notification.Builder(this)
                .setPriority(Notification.PRIORITY_LOW)
        })
            .setContentTitle("Night light active")
            .setSmallIcon(R.drawable.bamboo)
            .setOngoing(true)
            .setContentIntent(
                PendingIntent.getActivity(
                    this,
                    0,
                    Intent(this, LightActivity::class.java).putExtra("state", "night"),
                    PendingIntent.FLAG_IMMUTABLE
                )
            ).apply {
                if (Build.VERSION.SDK_INT >= 24) {
                    setActions(
                        Notification.Action.Builder(
                            Icon.createWithResource(this@NightService, R.drawable.bamboo),
                            "Stop",
                            PendingIntent.getBroadcast(
                                this@NightService, 0,
                                Intent(this@NightService, NightReceiver::class.java),
                                PendingIntent.FLAG_IMMUTABLE
                            )
                        ).build()
                    )
                }
            }
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    override fun onDestroy() {
        super.onDestroy()

        windowManager?.removeView(view)
    }

    private val notificationManager
        get() = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

    companion object {
        const val NOTIFICATION_CHANNEL = "night_channel"
        const val NOTIFICATION_ID = 1
    }
}
