package me.onwayride.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createDefaultNotificationChannel()
    }

    /**
     * قناة إشعارات FCM الافتراضية.
     *
     * البيان يشير إليها عبر
     * `com.google.firebase.messaging.default_notification_channel_id`، لكن
     * **الإشارة وحدها لا تُنشئها**. وأندرويد 8 فأحدث (minSdk عندنا 26) لا
     * يعرض إشعاراً بلا قناة قائمة، فكان FCM يتراجع إلى قناته الاحتياطية:
     * تظهر باسم «Miscellaneous» في إعدادات التطبيق، وبأهمية عادية لا
     * تُظهر الإشعار منبثقاً فوق الشاشة.
     *
     * IMPORTANCE_HIGH يعطي ما تعطيه بقية التطبيقات: صوت واهتزاز وظهور
     * منبثق فوق ما يفعله المستخدم.
     *
     * تُنشأ عند أول فتح للتطبيق ويحفظها النظام بعدها — والمستخدم يفتحه
     * ليسجّل دخوله على أي حال قبل أن يصله أي إشعار.
     */
    private fun createDefaultNotificationChannel() {
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val id = getString(R.string.default_notification_channel_id)

        // موجودة من تشغيل سابق — لا تُعاد فيُفقد ما غيّره المستخدم فيها
        if (manager.getNotificationChannel(id) != null) return

        val channel = NotificationChannel(
            id,
            getString(R.string.default_notification_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.default_notification_channel_description)
            enableVibration(true)
            enableLights(true)
        }
        manager.createNotificationChannel(channel)
    }
}
