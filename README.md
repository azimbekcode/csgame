# Atrium Strike

CS 1.6 uslubidan ilhomlangan, **Windows va Linux uchun botlar bilan o‘ynaladigan mustaqil FPS**. Xarita foydalanuvchi yuborgan `IMG_0038.MOV`–`IMG_0052.MOV` videolariga asoslangan. Bu dastlabki o‘ynaladigan versiya; original Counter-Strike kodi, modellari va tovushlari ishlatilmagan.

## Tayyor Windows o‘yini

**[AtriumStrike-Windows-x64.zip ni yuklab olish](https://github.com/azimbekcode/csgame/raw/refs/heads/main/downloads/AtriumStrike-Windows-x64.zip)**

ZIP’ni to‘liq oching, `AtriumStrike/AtriumStrike.exe` ni ishga tushiring. Godot o‘rnatish, internet yoki administrator huquqi kerak emas. Windows 10/11 x64 va OpenGL 3.3’ni qo‘llaydigan video drayver talab qilinadi. Bu portable EXE; APK Android uchun va bu versiyaga kiritilmagan. Faylning SHA-256 qiymati [SHA256SUMS.txt](downloads/SHA256SUMS.txt) da.

Windows SmartScreen noma’lum ilova haqida ogohlantirishi mumkin: EXE raqamli sertifikat bilan imzolanmagan. Faylni yuqoridagi repozitoriydan yuklagan bo‘lsangiz, **Подробнее → Выполнить в любом случае** orqali ochishingiz mumkin.

## Tayyor Linux o‘yini

**[AtriumStrike-Linux-x64.zip ni yuklab olish](https://github.com/azimbekcode/csgame/raw/refs/heads/main/downloads/AtriumStrike-Linux-x64.zip)**

ZIP’ni to‘liq oching, `AtriumStrike` papkasida terminal ochib bajaring:

```bash
chmod +x AtriumStrike.x86_64
./AtriumStrike.x86_64
```

Godot yoki Wine kerak emas. Yangilangan Kali Linux x64, Debian yoki Ubuntu, grafik ish stoli va OpenGL 3.3 video drayver talab qilinadi. ARM uchun mos emas. Batafsil: [Linux yo‘riqnomasi](docs/LINUX.txt).

Menyuda **CT bilan boshlash**, **T bilan boshlash** yoki **Xaritani erkin ko‘rish**ni tanlang. Bot qiyinligi, ovoz, sichqoncha sezgirligi va to‘liq ekran sozlamalari saqlanadi.

![O‘yin menyusi](docs/screenshots/menu.png)

## O‘yin

- Siz va 7 bot: 4×4 jamoalar, 5 raund g‘alabasigacha.
- CT/T, 5 soniya tayyorgarlik, 115 soniya raund, A/B bomba nuqtalari.
- T bomba o‘rnatadi; CT zararsizlantiradi. Bomba 35 soniyadan keyin portlaydi.
- Pistol, AK-47, M4, MP5, sniper, shotgun va pichoq. O‘q zaxirasi, qayta o‘qlash, tarqalish, recoil, headshot va sniper zoom mavjud.
- HE, flash va smoke granatalari. Devorga urilish va ko‘rish chizig‘i hisobga olinadi; smoke botlarning ko‘rishini to‘sadi.
- HP, zirh, defuse kit, xarid, kill puli, raund iqtisodi, hisob, minimap va kill feed.
- Botlar navigatsiya, ko‘rish chizig‘i, otish, qayta o‘qlash, bomba o‘rnatish va zararsizlantirishdan foydalanadi.
- O‘lgan o‘yinchi keyingi raundda qaytadi. Friendly fire o‘chirilgan. Internet multiplayer bu versiyada yo‘q.

![Bot va qurol bilan o‘yin](docs/screenshots/combat.png)

## Boshqaruv

| Tugma | Amal |
| --- | --- |
| WASD / sichqoncha | Yurish / qarash |
| Space / Ctrl / Shift | Sakrash / egilish / sekin yurish |
| Chap sichqoncha tugmasi | Otish yoki granata uloqtirish |
| O‘ng sichqoncha tugmasi | Sniper zoom |
| 1 / 2 / 3 / 4 | Asosiy qurol / pistol / pichoq / granata turini almashtirish |
| R / B | Qayta o‘qlash / xarid |
| E | Bomba o‘rnatish, zararsizlantirish yoki liftni boshqarish |
| Q, lift ichida | Oldingi qavatga tushish |
| Tab / Esc / F11 | Hisob / pauza / to‘liq ekran |
| F1–F4, erkin ko‘rishda | Atrium / orqa kirish / auditoriya / yuqori balkon |

Birinchi raund $800 va pistol bilan boshlanadi. **B** bilan dastlabki 20 soniyada, boshlanish joyidan 12 metr ichida xarid qilish mumkin. T: A yoki B nuqtada qimirlamasdan **E**’ni 3 soniya tuting. CT: bomba yonida **E**’ni 10 soniya tuting; kit bilan 5 soniya.

## Video va rasm asosidagi yangi xarita

Bino **0, 1, 2, 3-qavatlardan iborat**. Oldingi ikki to‘rtburchak yon hajm olib tashlandi: auditoriya, xonalar va ichki zinapoya endi dumaloq bino ichida.

- Rasmdagi och rangli dumaloq fasad, kulrang pastki qism, baland ravoqli oynalar, ustunlar va karnizlar. Ko‘k gumbaz old hovlida yer sathidan qaraganda ham ko‘rinishi uchun ko‘tarildi.
- Old markaziy tashqi zina 1-qavatga olib chiqadi; uning tagidagi 0-qavat eshigiga hovlidan panjarasiz ikki yon zinasi orqali pastga tushiladi. Eshikdan atriumgacha pol tekis: ichkarida qayta ko‘tariladigan zina va yo‘lni to‘sadigan plita yo‘q.
- Atriumda old kirishning ikki yonidagi belgilangan joylarda kichik yog‘och yo‘laklar ochildi; ulardan kiriladigan alohida buriluvchi zinapoyalar 0–3-qavatlarni bog‘laydi. Eski o‘ng yon zina olib tashlandi, xona devorlaridagi ortiqcha ochilishlar yopildi.
- Orqadagi ikkala zina rasmdagidek oraliq maydonchada burilib, bitta 1-qavat kirishiga birlashadi; uning tagidagi eshikdan 0-qavatga kiriladi.
- Orqadan kirganda chapdagi lift barcha to‘rt qavatni bog‘laydi. Kabinada **E — keyingi qavat**, **Q — oldingi qavat**; kabina shu qavatda bo‘lsa yaqinlashganda ikki tabaqali eshik ochiladi; boshqa qavatda bo‘lsa **E — chaqirish tugmasi**.
- Jigarrang yog‘och eshiklar, markaziy yo‘lakli pog‘onali partalar va qora o‘rindiqlar; zinada qadamga mos kamera va askar oyoq harakati. Har qavatda beshta kiriladigan xona, pog‘onali auditoriya, ochiq atrium, qora shishali panjaralar, yog‘och panellar va sariq taktil yo‘lak.
- Old fasadga qaraganda chap tomondagi daraxtlar olib tashlandi. Qolgan daraxtlar shox va alohida barglardan qurilgan; kamuflyaj, dubulg‘a, himoya jihozlari va yurish animatsiyasi bor askarlar.
- Monitorlar kirishning chapidagi pastki qismda; ichki zina yonida yopiq xona devorlari va panjaralar, tashqarini ko‘rsatadigan derazalar hamda lift oynasida o‘yinchi aksi.

![Yangi old fasad](docs/screenshots/front.png)
![Old hovlidan ko‘rinadigan ko‘k gumbaz](docs/screenshots/front_ground.png)
![Daraxtlari olib tashlangan chap tomon](docs/screenshots/front_left_clear.png)
![Burilish maydonchali orqa zina](docs/screenshots/rear_stairs.png)
![Ikki tomonlama orqa zina](docs/screenshots/rear.png)
![Atrium va balkonlar](docs/screenshots/atrium.png)
![Rom va sharnirli xona eshiklari](docs/screenshots/room_doors.png)
![Chap tomondagi lift](docs/screenshots/lift.png)
![Liftning yopiq suriladigan eshiklari](docs/screenshots/lift_closed.png)
![Old kirish yonidagi ichki zina](docs/screenshots/inner_stairs.png)
![Belgilangan joylardagi ikkala zina yo‘lagi](docs/screenshots/front_stair_pair.png)
![Pastga tushib kiriladigan 0-qavat eshigi](docs/screenshots/front_entry_zero.png)

![0-qavat eshigidan atriumgacha tekis yo‘lak](docs/screenshots/front_entry_flat.png)

Ichki zina pog‘onalari qiya taglik ustida aniq ko‘rinadi; panjaralar oraliq maydonchalargacha tutashgan. Zinada tezlik, oyoq qo‘yish balandligi, kamera va qadam tovushi pog‘ona o‘lchamiga moslanadi. Orqa kirishdagi sariq yo‘lak belgisi 0-qavat polida turadi. Lift kabinasining o‘z suriladigan eshiklari va qavatlar orasini yopadigan shaxta devorlari bor.

![Ichki zinaning yuqoridan ko‘rinishi](docs/screenshots/stairs_top.png)
![Derazadan tashqi ko‘rinish](docs/screenshots/window_view.png)
![Lift oynasidagi o‘yinchi aksi](docs/screenshots/lift_mirror.png)
![Pog‘onali auditoriya](docs/screenshots/classroom.png)
![Kirishning chapidagi monitor](docs/screenshots/classroom_front.png)
![Askar modeli](docs/screenshots/soldier.png)

O‘lchamlar hamda videoda to‘liq ko‘rinmagan xonalarning joylashuvi taxminiy. Modellar protsedurali o‘yin grafikasidir; fotogrammetrik yoki fotoreal nusxa deb taqdim etilmaydi. Manbalar va tekshiruvlar: [xarita izohlari](docs/MAP.md).

## Ishlab chiqish va tekshirish

Godot **4.6.3** bilan qurilgan. Shu versiya va unga mos export templates tavsiya qilinadi. `project.godot`ni import qilib, **F5** bilan loyihani ishga tushiring. Qo‘shimcha paketlar yoki backend kerak emas.

```bash
bash tools/check.sh
bash tools/build_windows.sh
bash tools/build_linux.sh
```

`tools/check.sh` xaritada yurish, xonalar, to‘rt qavatli lift, jang mexanikalari va ikki raundli bot sinovini bajaradi. Windows va Linux export preset’lari barcha o‘yin resurslarini executable ichiga joylaydi. `tools/package_windows.py` va `tools/package_linux.py` ZIP hamda ikkala platforma uchun SHA-256 ro‘yxatini yaratadi. Xaritadagi collision geometriyasi o‘zgarsa, navigatsiya meshini qayta bake qilish kerak; [tools/bake_navigation.gd](tools/bake_navigation.gd) bilan bajarish mumkin.

Yangi yig‘ilma 163 ta funksional tekshiruv va ikki raundli bot sinovidan o‘tdi. Linux standalone ishga tushishi va ichiga joylangan resurslarda to‘rt qavat, 20 xona kirishi, lift va harakatlanuvchi askarlar tekshirildi. Ikkala ZIP arxivning butunligi hamda SHA-256 qiymatlari tasdiqlandi. Windows x64 EXE Linuxdan eksport qilindi; Windows tizimida bevosita ishga tushirish tekshirilmagan.

Godot va uchinchi tomon kutubxonalarining litsenziyalari: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md), [GODOT-COPYRIGHT.txt](GODOT-COPYRIGHT.txt). Asl reference videolar va ulardagi odamlar tasvirlari repozitoriy yoki tayyor ZIP’ga qo‘shilmagan.
