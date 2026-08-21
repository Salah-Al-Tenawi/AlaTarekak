# بناء نسخة الإصدار — مع التنظيف الذي لا يُستغنى عنه.
#
# ━━ لماذا التنظيف قبل كل بناء إصدار ━━
#
# `integration_test` تبعيّةُ تطوير (dev_dependency) لأجل
# `integration_test/app_test.dart`. وهي لا تُضمَّن في بناء الإصدار —
# وهذا صواب. لكن الملف المولَّد:
#
#   android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java
#
# يُكتب أحياناً وفيه سطرٌ يسجّل إضافتها، فيفشل التصريف:
#
#   error: package dev.flutter.plugins.integration_test does not exist
#
# يقع ذلك حين تسبق البناءَ عمليةٌ تُهيّئ الإضافات بوضع التطوير — تشغيل
# التطبيق للتصحيح، أو اختبار تكاملي. فتبقى بياناتها في `.dart_tool`
# و`.flutter-plugins-dependencies`، ويُبنى عليها المسجِّل.
#
# و`flutter clean` يمحو تلك البيانات، فيُعاد توليد المسجِّل من جديد
# صحيحاً للإصدار. وقع العطل في نسختَي 1.3.0+7 و1.3.0+14، وفي الأولى
# ظُنّ عابراً — ولم يكن.
#
# ━━ الاستعمال ━━
#
#   .\tool\build_release_apk.ps1
#
# ولا يُستعمل لبناء التصحيح: `flutter run` لا يحتاج شيئاً من هذا،
# والتنظيف قبله إبطاءٌ بلا سبب.

$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host '━━ 1/3  تنظيف مخلّفات البناء السابق ━━' -ForegroundColor Cyan
flutter clean
if ($LASTEXITCODE -ne 0) { throw 'فشل flutter clean' }

Write-Host ''
Write-Host '━━ 2/3  جلب الحزم ━━' -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'فشل flutter pub get' }

Write-Host ''
Write-Host '━━ 3/3  بناء نسخة الإصدار ━━' -ForegroundColor Cyan
flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw 'فشل بناء الـAPK' }

$apk = 'build/app/outputs/flutter-apk/app-release.apk'
$meta = 'build/app/outputs/apk/release/output-metadata.json'

if (Test-Path $apk) {
    $size = [math]::Round((Get-Item $apk).Length / 1MB, 1)
    $sha = (Get-FileHash $apk -Algorithm SHA1).Hash.ToLower()

    Write-Host ''
    Write-Host "✔ تمّ: $apk" -ForegroundColor Green
    Write-Host "  الحجم : $size ميغابايت"
    Write-Host "  SHA-1 : $sha"

    if (Test-Path $meta) {
        $json = Get-Content $meta -Raw | ConvertFrom-Json
        $el = $json.elements[0]
        Write-Host "  النسخة: $($el.versionName) — versionCode $($el.versionCode)"
    }
}
