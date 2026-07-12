# توقيع إصدارات Android — عطريقك

## الوضع الحالي

- **معرّف التطبيق:** `me.onwayride.app` (Android و iOS معاً — كان `com.example.alatarekak`).
- **مفتاح التوقيع:** `android/keystore/upload-keystore.jks` — RSA-4096، الاسم المستعار `upload`، صالح 30 سنة.
- **بيانات الاعتماد:** في `android/key.properties` — **الملفان خارج git** (مغطيان بـ `.gitignore`).
- عند غياب `key.properties` يعود بناء الـ release تلقائياً لمفاتيح debug، فلا يتعطل بقية الفريق.

## ⚠️ نسخ احتياطي إلزامي — اقرأ هذا

فقدان الـ keystore أو كلمة مروره = **فقدان القدرة على تحديث التطبيق على Google Play نهائياً**
(إلا إذا فُعّل Play App Signing فيمكن طلب إعادة تعيين مفتاح الرفع، وهو إجراء بطيء).

انسخ الملفين التاليين **الآن** إلى مكانين آمنين على الأقل خارج هذا الجهاز
(مدير كلمات مرور + قرص خارجي/سحابة خاصة):

1. `android/keystore/upload-keystore.jks`
2. `android/key.properties` (أو احفظ كلمة المرور في مدير كلمات المرور)

## بناء نسخة متجر

```bash
flutter build appbundle --release   # الناتج: build/app/outputs/bundle/release/app-release.aab
flutter build apk --release        # للتوزيع اليدوي خارج المتجر
```

## قبل النشر الفعلي على Google Play

- فعّلوا **Play App Signing** عند إنشاء التطبيق في Play Console (المفتاح الحالي يصبح "upload key" ويحمي Google المفتاح النهائي).
- عند تفعيل Firebase (`flutterfire configure`) استخدموا المعرّف الجديد `me.onwayride.app`
  وأضيفوا بصمة SHA-1/SHA-256 للمفتاح:
  ```bash
  keytool -list -v -keystore android/keystore/upload-keystore.jks -alias upload
  ```
- ملاحظة: تغيير المعرّف يعني أن أي تثبيت قديم بمعرّف `com.example` لن يستقبل تحديثات — أزيلوه يدوياً من أجهزة الاختبار.
