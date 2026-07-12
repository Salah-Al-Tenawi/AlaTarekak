# قواعد R8/ProGuard لبناء release.
#
# pusher-java-client (عبر pusher_channels_flutter) يستخدم slf4j الذي يبحث
# عن StaticLoggerBinder اختيارياً في وقت التشغيل — غيابه آمن (no-op logger)
# لكن R8 يعامله كصنف مفقود ويفشل البناء بدون هذه القاعدة.
-dontwarn org.slf4j.impl.StaticLoggerBinder
