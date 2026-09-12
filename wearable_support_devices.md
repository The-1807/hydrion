### IOS
Apple HealthKit
### Andriod:
1. **Samsung** — Galaxy Watch, Galaxy Watch Ultra, Galaxy Ring. Samsung remains one of the largest Android wearable ecosystems. ([Samsung it][1])
2. **Google** — Pixel Watch + Fitbit devices. ([Google Store][2])
3. **Xiaomi** — Xiaomi Watch, Xiaomi Smart Band, Redmi Watch/Band, and some POCO wearables. ([Xiaomi Australia][3])
4. **OnePlus** — OnePlus Watch series; current models use **Wear OS**. ([OnePlus][4])
5. **OPPO** — OPPO Watch, Watch X, Watch X2/X3, Watch S, etc. ([OPPO][5])
6. **vivo** — vivo Watch, Watch GT, Watch GT 2 and related devices. ([Vivo][6])
7. **HONOR** — HONOR Watch and HONOR Band families. ([Honor][7])
8. **Huawei** — Huawei Watch, Watch GT, Watch Fit, Watch D and Huawei Band. Huawei is a special case because its modern phones/watches increasingly use its own HarmonyOS ecosystem rather than the normal Google Android/Wear OS stack, but its wearables remain highly relevant to Android phones. ([Huawei Consumer][8])`
9. **Motorola / Lenovo** — Moto Watch and the newer Moto Watch Ultra. ([Motorola][9])
10. **ASUS** — ASUS VivoWatch series, including VivoWatch 5/6 and VivoWatch AERO health trackers. ([ASUS Global][10])
11. **Nothing / CMF** — CMF Watch Pro, Watch Pro 2 and Watch 3 Pro. Nothing also manufactures Android phones. ([Nothing][11])
12. **realme** — realme Watch family with heart-rate, SpO₂, sleep and activity tracking. ([Realme][12])
13. **ZTE** — ZTE Watch family; current examples include the ZTE Watch K1 Pro. ([ZTE Devices][13])
14. **nubia** — Android smartphone maker associated with the ZTE ecosystem and has produced smartwatches/wearable devices.
15. **TCL** — Android phones plus smartwatches and other wearable devices; TCL continues to develop wearable products. ([TCL][14])
16. **TECNO** — Android smartphones plus Watch Neo, Watch Pro, Watch Pro 2, Watch 3 and others. ([Tecno][15])
17. **Infinix** — Android smartphones plus a substantial XWATCH range including XWATCH N4/N4 Pro, H4/H5 Pro, N5 Pro and others. ([Infinix][16])
18. **itel** — Android smartphones plus Smart Watch Fit, Apex, Storm, Horizon and related products. ([itel Life][17])
19. **Lava** — Android smartphones plus its **Prowatch** smartwatch line. ([Lava International Limited][18])
20. **Meizu** — Android-based smartphones historically/currently in selected markets, with Meizu smartwatch/wearable products. ([Meizu][19])

For **Hydrion**, however, I would **not build 20 manufacturer-specific integrations**. The more sensible architecture is:

**Android wearable → manufacturer's health app → Health Connect → Hydrion**

That gives you a much more manageable target. The highest-priority ecosystems would be **Samsung, Google/Fitbit, Xiaomi, OnePlus, OPPO, Huawei, HONOR, Garmin, Amazfit/Zepp, Fitbit, Oura, Polar and Withings**—and notice that the last several aren't Android phone manufacturers at all. That's why for a hydration app, classifying devices by **health-data provider**, rather than phone manufacturer, is the more useful compatibility model.

[1]: https://www.samsung.com/ca/support/mobile-devices/track-workouts-with-your-galaxy-ring/?utm_source=chatgpt.com "Tracking workouts with your Galaxy Ring | Samsung CA"
[2]: https://store.google.com/category/watches_trackers?hl=en-US&utm_source=chatgpt.com "Google Fitbit, Pixel Watches & Trackers with Google Health"
[3]: https://www.mi.com/global/product-list/bands/?utm_source=chatgpt.com "Xiaomi Global Home"
[4]: https://www.oneplus.com/ca_en/oneplus-watch-3?utm_source=chatgpt.com "OnePlus Watch 3"
[5]: https://www.oppo.com/en/wearables/?utm_source=chatgpt.com "OPPO Wearables | OPPO Global"
[6]: https://www.vivo.com/en/products/watch3?utm_source=chatgpt.com "vivo Watch 3 | vivo Global"
[7]: https://www.honor.com/global/wearables/honor-watch/?utm_source=chatgpt.com "HONOR Smart Watches - HONOR Global"
[8]: https://consumer.huawei.com/ca/wearables/watch-fit3/?utm_source=chatgpt.com "HUAWEI Wearables - HUAWEI Canada"
[9]: https://www.motorola.com/ca/en/family/wearables?utm_source=chatgpt.com "Motorola Watch Wearables | motorola US - Motorola | motorola"
[10]: https://www.asus.com/us/mobile-handhelds/wearable-healthcare/asus-vivowatch/filter?Series=ASUS-VivoWatch&utm_source=chatgpt.com "VivoWatch - All Models｜Wearable｜ASUS USA"
[11]: https://intl.nothing.tech/collections/cmf?utm_source=chatgpt.com "CMF | Nothing | US"
[12]: https://www.realme.com/global/realme-watch?utm_source=chatgpt.com "realme Watch - realme (Global)"
[13]: https://www.ztedevices.com/en/products/accessories/wearable/zte-watch-k1-pro.html?utm_source=chatgpt.com "ZTE Watch K1 Pro"
[14]: https://www.tcl.com/global/en/news/tcl-to-display-the-future-with-advanced-visual-innovations-and-ai-powered-product-portfolio-at-ces-2026?utm_source=chatgpt.com "TCL to Display the Future with Advanced Visual Innovations and AI-Powered Product Portfolio at CES 2026"
[15]: https://www.tecno-mobile.com/accessories/product-detail/product/watch-neo/?utm_source=chatgpt.com "TECNO Watch Neo | TECNO AIoT"
[16]: https://www.infinixmobility.com/XWATCH-N4?utm_source=chatgpt.com "Infinix - XWATCH N4 - Global"
[17]: https://www.itel-life.com/products/phone?utm_source=chatgpt.com "Phone - itel"
[18]: https://shop.lavamobiles.com/collections/smartwatch?utm_source=chatgpt.com "Smartwatches – Lava International Limited"
[19]: https://www.meizu.com/en/accessory/mix.html?utm_source=chatgpt.com "Smart Watch MIX - Meizu"

Exactly. **FitPro is better thought of as a wearable ecosystem/companion app, not a phone manufacturer.** This category is especially important for Hydrion because many inexpensive watches are white-label devices sold under dozens or hundreds of names while using the same underlying companion app.

There is no practical way to enumerate *every* device brand because the white-label market constantly changes, but these are the major ecosystems you should account for.

### 1. Generic / white-label wearable ecosystems

These are the ones most similar to **FitPro**:

* **FitPro**
* **Da Fit**
* **WearFit Pro**
* **FitCloudPro**
* **HryFine**
* **VeryFit**
* **VeryFitPro**
* **GloryFit**
* **Lefun Health**
* **JYouPro**
* **Yoho Sports**
* **DayBand**
* **FlagFit 2.0**
* **RDFit**
* **MActivePro**
* **SMART-TIME PRO**
* **QWatch Pro**
* **Fere Fit / FereFit**
* **OnWear**
* **OnWear Pro**
* **V Band**
* **Keep Health**
* **Pubu Wear**
* **WearPro**
* **WearHealth**
* **H Band**
* **H Band 2.0**
* **Fundo Wear**
* **Fundo Pro**
* **Runmifit**
* **FitHere**
* **Fitdock**
* **Fitpolo**
* **Co-Fit**
* **Happy Sports**
* **HeroBand / HeroBand III**
* **Smart Wristband**
* **Smart Wristband 3**
* **SmartHealth**
* **SmartHealth Pro**
* **FitMore**
* **FitBeing**
* **FitGo**
* **WearHeart**
* **WearPro**
* **FitVII**
* **FitBridge**
* **FitGo**
* **FitTrack-style wearable ecosystems**

For example, Da Fit supports compatible smart wearables and can pass supported wellness information to Apple Health. ([App Store][1]) VeryFit similarly manages compatible watches/bands and tracks things such as steps, heart rate, sleep, stress and workouts. ([App Store][2])

FitCloudPro is another major white-label ecosystem; its current listing specifically names several KUMI watches while supporting steps, sleep, heart rate and SpO₂. ([Google Play][3]) WearFit Pro has more than 10 million Android installs and connects to multiple classes of wearable devices. ([Google Play][4])

RDFit, SMART-TIME PRO, JYouPro, OnWear, Fere Fit and Pubu Wear are the same general type of architecture: **BLE wearable → companion app → phone health ecosystem or proprietary database**. ([RDFit][5])

### 2. Independent major wearable brands

These aren't tied to manufacturing a particular Android phone and generally operate their own wearable ecosystem:

* **Garmin** — Garmin Connect
* **Amazfit** — Zepp
* **Polar** — Polar Flow
* **Suunto** — Suunto App
* **COROS** — COROS App
* **Oura** — Oura App / Oura Ring
* **WHOOP** — WHOOP
* **Withings** — Withings App
* **RingConn** — RingConn smart rings
* **Ultrahuman** — Ring AIR
* **Zepp Health** — Amazfit/Zepp ecosystem
* **Wahoo** — fitness sensors/computers
* **Beurer** — health wearables
* **Omron** — health wearables/medical devices
* **Dexcom** — continuous glucose wearables
* **Abbott FreeStyle Libre** — glucose wearables
* **Polar** chest straps and watches
* **Garmin** HR straps, watches and cycling devices

COROS, for example, explicitly supports third-party synchronization including **Apple HealthKit and Google Health Connect**. ([App Store][6]) Zepp is the official Amazfit ecosystem. ([App Store][7])

### 3. White-label hardware brands

Then there is another layer underneath FitPro/Da Fit/etc. These names may appear on Amazon, Temu, AliExpress, Walmart and similar marketplaces:

* KUMI
* Colmi
* Kieslect
* Haylou
* Zeblaze
* Mibro
* Blackview
* Kospet
* LIGE
* YAMAY
* Letsfit
* Letscom
* Fitpolo
* Popglory
* MorePro
* Kalinco
* Nerunsa
* TOZO
* Tensky
* Woneligo
* IOWODO
* AGPTEK
* GRV
* Parsonver
* MILOUZ
* RUIMEN
* Banlvs
* VPSTAY
* Ddidbi
* Jugeman
* EURANS
* SoundPEATS
* IDW-series watches
* ID-series fitness trackers
* T-series watches
* W-series watches
* P-series watches
* HK-series watches
* HW-series watches
* DT-series watches

The important thing is that these **brand names are unreliable as an integration boundary**. One KUMI device might use FitCloudPro while another inexpensive device may use Da Fit, FitPro, GloryFit or something else.

---

## For Hydrion, this changes the architecture

I would classify wearable support into **three layers**, not by watch brand:

**Tier 1 — OS health hubs**

`Health Connect ← Android wearable apps`

`HealthKit ← iOS wearable apps`

Hydrion integrates here first.

**Tier 2 — Major independent ecosystems**

Garmin Connect
Zepp/Amazfit
Oura
Polar Flow
Suunto
COROS
Withings
WHOOP
RingConn
Ultrahuman

Only build direct integrations where Health Connect/HealthKit does **not provide the data Hydrion actually requires**.

**Tier 3 — Generic/white-label ecosystem**

FitPro
Da Fit
WearFit Pro
FitCloudPro
GloryFit
VeryFit
HryFine
Lefun Health
RDFit
JYouPro
etc.

For these, **do not attempt to support every individual watch**.

The compatibility path should be:

**Watch → FitPro/Da Fit/etc. → Health Connect/HealthKit → Hydrion**

That gives Hydrion potential compatibility with **hundreds or thousands of wearable models without writing hundreds of BLE drivers**.

And there is an important engineering consequence here: **we should stop describing Hydrion's future compatibility simply as “Apple Watch, Samsung Watch, Fitbit, Garmin…”**. The correct model is a **provider capability matrix**:

**Device → Companion Provider → Health Hub → Metric → Hydrion**

That will scale much better and is what I'd recommend putting into `HWI.md`.

[1]: https://apps.apple.com/ca/app/da-fit/id1316004998?platform=watch&utm_source=chatgpt.com "‎Da Fit App - App Store"
[2]: https://apps.apple.com/ca/app/veryfit/id1516248105?platform=watch&utm_source=chatgpt.com "‎VeryFit App - App Store"
[3]: https://play.google.com/store/apps/details?hl=en-CA&id=com.topstep.fitcloudpro&utm_source=chatgpt.com "FitCloudPro - Apps on Google Play"
[4]: https://play.google.com/store/apps/details?hl=en_CA&id=com.wakeup.howear&utm_source=chatgpt.com "Wearfit Pro - Apps on Google Play"
[5]: https://rdfit.app/download/?utm_source=chatgpt.com "Download RDFit Smart Watch App - Free Smartwatch Companion | Google Play & App Store"
[6]: https://apps.apple.com/ca/app/coros/id1277625343?platform=watch&utm_source=chatgpt.com "‎COROS App - App Store"
[7]: https://apps.apple.com/ca/app/zepp/id1127269366?utm_source=chatgpt.com "‎Zepp App - App Store"
