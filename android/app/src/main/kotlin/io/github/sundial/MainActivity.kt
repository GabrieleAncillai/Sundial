package io.github.sundial

import android.content.ComponentName
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.SoundPool
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var soundPool: SoundPool? = null
    private val soundIds = HashMap<Int, Int>()
    private val loadedIds = HashSet<Int>()
    private val pendingIds = HashSet<Int>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val pool = SoundPool.Builder()
            .setMaxStreams(MAX_STREAMS)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            .build()
        pool.setOnLoadCompleteListener { _, sampleId, status ->
            if (status == 0) {
                loadedIds.add(sampleId)
                // The first request may arrive before the sample is ready.
                if (pendingIds.remove(sampleId)) {
                    pool.play(sampleId, 1f, 1f, 1, 0, 1f)
                }
            } else {
                pendingIds.remove(sampleId)
            }
        }
        soundPool = pool

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> {
                        val played = play(
                            alarm = call.argument<String>("alarm"),
                            pack = call.argument<String>("pack"),
                            file = call.argument<String>("file"),
                        )
                        result.success(played)
                    }

                    "preload" -> {
                        val loaded = preload(
                            pack = call.argument<String>("pack"),
                            files = call.argument<List<String>>("files"),
                        )
                        result.success(loaded)
                    }

                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_ICON_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setAppIcon" -> {
                        val style = call.argument<String>("style")
                        if (style != "classic" && style != "aero") {
                            result.error("invalid_style", "Unknown app icon style", null)
                            return@setMethodCallHandler
                        }
                        try {
                            setAppIcon(style)
                            result.success(true)
                        } catch (error: Exception) {
                            result.error("icon_switch_failed", error.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun setAppIcon(style: String) {
        val classic = ComponentName(packageName, "$packageName.ClassicIcon")
        val aero = ComponentName(packageName, "$packageName.AeroIcon")
        val selected = if (style == "aero") aero else classic
        val other = if (style == "aero") classic else aero
        val manager = packageManager

        if (manager.getComponentEnabledSetting(selected) != PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
            manager.setComponentEnabledSetting(
                selected,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
        if (manager.getComponentEnabledSetting(other) != PackageManager.COMPONENT_ENABLED_STATE_DISABLED) {
            manager.setComponentEnabledSetting(
                other,
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
    }

    private fun preload(pack: String?, files: List<String>?): Int {
        val pool = soundPool ?: return 0
        if (pack == null || files == null) return 0
        var loaded = 0
        for (file in files) {
            val resourceId = resourceId("sundial_${pack}_$file")
            if (resourceId == 0) continue
            val sampleId = soundIds.getOrPut(resourceId) {
                try {
                    pool.load(this, resourceId, 1)
                } catch (_: Exception) {
                    0
                }
            }
            if (sampleId != 0) loaded++
        }
        return loaded
    }

    private fun play(alarm: String?, pack: String?, file: String?): Boolean {
        val name = when {
            alarm != null -> "sundial_alarm_$alarm"
            pack != null && file != null -> "sundial_${pack}_$file"
            else -> return false
        }

        val pool = soundPool ?: return false
        val resourceId = resourceId(name)
        if (resourceId == 0) return false

        val sampleId = soundIds.getOrPut(resourceId) {
            try {
                pool.load(this, resourceId, 1)
            } catch (_: Exception) {
                0
            }
        }
        if (sampleId == 0) return false
        if (sampleId !in loadedIds) {
            pendingIds.add(sampleId)
            return true
        }

        val streamId = try {
            pool.play(sampleId, 1f, 1f, 1, 0, 1f)
        } catch (_: Exception) {
            0
        }
        return streamId != 0
    }

    private fun resourceId(name: String): Int {
        if (!isValidResourceName(name)) return 0
        return try {
            resources.getIdentifier(name, "raw", packageName)
        } catch (_: Exception) {
            0
        }
    }

    private fun isValidResourceName(name: String): Boolean {
        if (name.isEmpty()) return false
        return name.all { it in 'a'..'z' || it in '0'..'9' || it == '_' }
    }

    override fun onDestroy() {
        soundPool?.release()
        soundPool = null
        soundIds.clear()
        loadedIds.clear()
        pendingIds.clear()
        super.onDestroy()
    }

    private companion object {
        const val CHANNEL = "sundial/sound"
        const val APP_ICON_CHANNEL = "sundial/app_icon"
        const val MAX_STREAMS = 4
    }
}
