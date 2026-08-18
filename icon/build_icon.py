"""يبني أيقونتَي التطبيق من assets/images/logo.jpg.

مخرجان:
  app_icon.png            المربّع الكامل — للأيقونة التقليدية وiOS.
  app_icon_foreground.png الرسم وحده على شفافية، محصوراً في المنطقة
                          الآمنة — لأيقونة أندرويد التكيّفية.

سبب الفصل: أندرويد 8 فأحدث (وminSdk عندنا 26) يقصّ الأيقونة بقناع
دائري أو مربّع الزوايا، ولا يضمن ظهور إلا الثلثين الأوسطين. فوضع
الصورة كاملةً في المقدّمة يقصّ كلمة «طريقك» وأطراف الرسم.
"""

from PIL import Image

SRC = 'assets/images/logo.jpg'
OUT_DIR = 'icon'
BG = (37, 60, 91)          # كحليّ الهوية — مقيس من الصورة
FRAME = 3                  # إطار فاتح رفيع في ملف المصدر يُقصّ
SIZE = 1024

# نسبة الرسم من ضلع ملف المقدّمة. flutter_launcher_icons يضيف فوقها
# حشوة 16% في ic_launcher.xml، فالنتيجة النهائية 0.88 × 0.68 ≈ 0.60 من
# ضلع الأيقونة — أي ملء المنطقة الآمنة (66%) بلا لمس حوافّها.
CONTENT_RATIO = 0.88


def content_box(im):
    px = im.load()
    w, h = im.size

    def strong(x, y):
        r, g, b = px[x, y]
        return abs(r - BG[0]) + abs(g - BG[1]) + abs(b - BG[2]) > 120

    rows = [y for y in range(h) if sum(1 for x in range(0, w, 3) if strong(x, y)) >= 4]
    cols = [x for x in range(w) if sum(1 for y in range(0, h, 3) if strong(x, y)) >= 4]
    return (cols[0], rows[0], cols[-1] + 1, rows[-1] + 1)


def main():
    src = Image.open(SRC).convert('RGB')
    src = src.crop((FRAME, FRAME, src.width - FRAME, src.height - FRAME))

    # ── 1) المربّع الكامل ──
    full = src.resize((SIZE, SIZE), Image.LANCZOS)
    full.save(OUT_DIR + '/app_icon.png')
    print('app_icon.png', full.size)

    # ── 2) المقدّمة: الرسم على شفافية ──
    box = content_box(src)
    art = src.crop(box)

    # الكحليّ يصير شفافاً فيظهر لون الخلفية المعلَن تحته
    art = art.convert('RGBA')
    px = art.load()
    for y in range(art.height):
        for x in range(art.width):
            r, g, b, _ = px[x, y]
            d = abs(r - BG[0]) + abs(g - BG[1]) + abs(b - BG[2])
            if d < 60:
                px[x, y] = (r, g, b, 0)
            elif d < 120:
                # حافة متدرّجة: شفافية جزئية فلا تظهر هالة مسنّنة
                px[x, y] = (r, g, b, int(255 * (d - 60) / 60))

    target = int(SIZE * CONTENT_RATIO)
    ratio = min(target / art.width, target / art.height)
    art = art.resize(
        (max(1, round(art.width * ratio)), max(1, round(art.height * ratio))),
        Image.LANCZOS,
    )

    fg = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    fg.paste(art, ((SIZE - art.width) // 2, (SIZE - art.height) // 2), art)
    fg.save(OUT_DIR + '/app_icon_foreground.png')
    print('app_icon_foreground.png', fg.size, '| الرسم', art.size)


main()
