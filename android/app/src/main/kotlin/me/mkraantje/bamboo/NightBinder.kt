package me.mkraantje.bamboo

import android.os.Binder

class NightBinder(private val listener: Listener) : Binder() {

    var darkness: Int
        get() = listener.getDarkness()
        set(value) {
            listener.setDarkness(value)
        }

    fun stop() = listener.stop()

    interface Listener {
        fun getDarkness(): Int
        fun setDarkness(value: Int)
        fun stop()
    }
}
