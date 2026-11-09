extends Node
## Tiny two-language helper (English source strings -> Persian).
## Kept as a plain static class so any script can call L10n.t("PLAY").

static var fa := false

const FA := {
	# ---- home / navigation
	"PLAY": "بازی",
	"LEVELS": "مراحل",
	"SHOP": "فروشگاه",
	"SKINS": "پوسته‌ها",
	"HOME": "خانه",
	"RETRY": "تلاش دوباره",
	"CLOSE": "بستن",
	"SETTINGS": "تنظیمات",
	"UPGRADES": "ارتقاها",
	"DAILY MISSION": "مأموریت روزانه",
	"DAILY BEST": "رکورد روز",
	"DAILY RUN": "ران روزانه",
	"STARS": "ستاره",
	"LEVEL": "مرحله",
	"LOCKED": "قفل",
	"BOSS": "باس",
	"CLAIM": "دریافت",
	"DONE": "تمام شد",
	"BUY": "خرید",
	"MAX": "حداکثر",
	"USE": "انتخاب",
	"EQUIPPED": "انتخاب‌شده",
	"HOW TO PLAY": "راهنمای بازی",
	"TAP LEFT / RIGHT TO PICK A GATE": "چپ یا راست بزن تا گیت را انتخاب کنی",
	"COLOUR MEANS NOTHING - READ THE NUMBER": "رنگ مهم نیست — عدد را بخوان",
	"FIRE BURNS 30% OF YOUR MASS": "آتش ۳۰٪ جرمت را می‌سوزاند",
	"ENDLESS  ·  EVERY LEVEL IS GENERATED": "بی‌پایان  ·  هر مرحله خودکار ساخته می‌شود",
	"G R O W   ·   R O L L   ·   R E P E A T": "بزرگ شو  ·  بغلت  ·  تکرار کن",

	# ---- settings rows
	"Music": "موسیقی",
	"Sound FX": "افکت صدا",
	"Haptics": "لرزش",
	"LANGUAGE": "زبان",

	# ---- missions
	"Finish {n} levels": "{n} مرحله را تمام کن",
	"Earn {n} coins": "{n} سکه جمع کن",
	"Pass {n} bonus gates": "از {n} گیت جایزه رد شو",
	"Collect {n} stars": "{n} ستاره بگیر",
	"Absorb {n} blobs": "{n} بلاب را ببلع",

	# ---- upgrades
	"Start Mass": "جرم شروع",
	"Begin every run bigger": "هر ران را بزرگ‌تر شروع کن",
	"Magnet": "آهنربا",
	"Pull in orbs from far away": "جایزه‌ها را از دور جذب کن",
	"Lane Speed": "سرعت لاین",
	"Switch lanes faster": "سریع‌تر لاین عوض کن",
	"Shield": "شیلد",
	"Survive one hit per run": "هر ران یک برخورد را تحمل کن",

	# ---- skins
	"Slime": "اسلایم",
	"Bubblegum": "آدامس",
	"Glacier": "یخی",
	"Toxic": "سمی",
	"Galaxy": "کهکشانی",
	"Gold": "طلایی",

	# ---- run panels
	"RUN OVER": "بازی تمام شد",
	"TOO SMALL": "خیلی کوچک بودی",
	"PAUSED": "توقف",
	"RESUME": "ادامه",
	"RESTART": "شروع دوباره",
	"NEXT LEVEL": "مرحلهٔ بعد",
	"NICE!": "عالی!",
	"MASS": "جرم",
	"GOAL": "هدف",
	"COINS": "سکه",
	"STAR": "ستاره",
	"Your blob shrank to nothing": "قطره‌ات کاملاً آب شد",
	"A bigger blob absorbed you": "یک بلاب بزرگ‌تر تو را بلعید",
	"The spikes drained you": "آتش جانت را گرفت",
	"You needed %d mass to fill the pool": "برای پر کردن استخر %d جرم لازم بود",
}


const FA_DIGITS := ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"]


## Converts every ASCII digit in the string to its Persian counterpart when
## the UI language is Persian. Numbers are the same value, just localised.
static func d(source: String) -> String:
	if not fa:
		return source
	var out := ""
	for i in range(source.length()):
		var c := source[i]
		if c >= "0" and c <= "9":
			out += FA_DIGITS[c.to_int()]
		else:
			out += c
	return out


static func num(value: int) -> String:
	return d(str(value))


static func t(s: String) -> String:
	if not fa:
		return s
	return String(FA.get(s, s))
