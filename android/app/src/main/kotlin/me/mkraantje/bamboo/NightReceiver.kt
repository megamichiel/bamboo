package me.mkraantje.bamboo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class NightReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        context?.stopService(Intent(context, NightService::class.java))
    }
}
