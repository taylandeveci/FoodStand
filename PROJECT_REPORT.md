# Food Stand — Detaylı Proje Raporu

Bu rapor, proje içeriğini ve çalışma zamanındaki gereksinimleri "GPT'nin anlayacağı" ayrıntıda açıklar. Amacı: bir başka GPT veya geliştiricinin projeyi hızlı ve doğru anlaması için tüm önemli noktaları kayıt altına almak.

---

## 1) Genel Bilgi
- Proje adı: Food Stand
- Motor: Godot (project.godot belirtmesi: `config/features` içinde "4.6" — yani Godot 4.6 hedefi/uyumluluğu). `config_version=5` (Godot 4 serisi yapılandırma).
- Oynanış türü: 2D side-view (gündüz/gece döngüsü, servis/defans mecaniği)
- Kök: çalışma dizini içeriği incelendi.

## 2) Konfigürasyon (`project.godot` özet)
- Ana sahne: `run/main_scene="uid://dkuwuqiv4s2oq"` (UID ile tanımlı; proje editöründe bir `PackedScene` referansı — muhtemelen `main.tscn`).
- Pencere: 1280x720, stretch mode: `canvas_items`.
- Input aksiyonları (tanımlı): `move_left`, `move_right`, `jump`, `attack`, `pause`, `interact`, `recipe_a`, `recipe_b`.
- Physics: 3D motoru olarak "Jolt Physics" tanımlı (bu 2D proje için engine defaultu; 2D fizik ayarları ayrıca alınmalı).
- Rendering: `renderer/rendering_method = "mobile"` (mobil uyumluluk ayarı).

## 3) Dosya ve Klasör Yapısı (kök seviyesinden önemli alt içerikler)
- Kök: `project.godot`, `README.md`, `assets/`, `scenes/`, `scripts/`
- Önemli sahneler (bulundu): `scenes/main.tscn`, `main_menu.tscn`, `food_cart.tscn`, `customer.tscn`, `enemy.tscn`, `tank_enemy.tscn`, `trash.tscn`.
- Önemli scriptler: `scripts/main.gd`, `player.gd`, `food_cart.gd`, `enemy.gd`, `customer.gd`, `hud.gd`, `trash.gd`, `main_menu.gd`, `music_h_slider.gd`.
- Varlıklar: `assets/` içinde `character/` sprite'ları, `tileset/` görselleri, font `ThaleahFat.ttf`, arka plan resimleri, ve bir müzik dosyası.

## 4) `scripts/main.gd` — yüksek seviyeli özet (ana oyun döngüsü ve durum makinesi)
- Node türü: `extends Node2D` — merkezi oyun yöneticisi.
- Tanımlı enum `GameState`: CLEANING, OPEN_CART, CUSTOMER_WALKING, CUSTOMER_WAITING, SERVING, CUSTOMER_LEAVING, NIGHT, NIGHT_WON, NIGHT_FAILED.
- Exported PackedScene değişkenleri (editor'da bağlanması gerekiyor): `trash_scene`, `customer_scene`, `enemy_scene`, `tank_scene`.
- Günlük akışı:
  - `start_morning_phase()` → çöp spawn, müşteri kuyruğu oluşturma hazırlığı.
  - `open_cart()` → `spawn_customer_queue()` çağrılır.
  - Müşteri geldiğinde `start_recipe_input_phase()` → ardından `start_service_phase()` → servis başarılıysa `finish_service_phase()` ile para ve appeal kazanımı.
  - Geceleri `start_night_phase()` → `NightTimer` ve `EnemySpawnTimer` ile düşman spawnları.
- Recipe sistemi: `recipes` sözlüğü (örnek: "BURGER" -> ["A","A"]) ve `recipe_display_map` (A->J, B->K). Girdi `recipe_a` / `recipe_b` aksiyonları ile toplanıyor.
- UI referansları: HUD alt düğümlerine (`HUD/HUDRoot/`) birçok `Label` ve `ProgressBar` yoluyla erişiliyor. Eğer `HUD` veya iç yollar hatalıysa `get_node_or_null` null dönebilir.
- Sinyal kullanımı: `player` ve `food_cart` üzerindeki bir dizi sinyale bağlanıyor (ör: `health_changed`, `down_started`, `interacted`, `hp_changed`, `destroyed`). Script, sinyallerin varlığını kontrol ediyor.
- Hata kontrolü: `push_error` ile atamalar yapılmamış PackedScene'leri bildirebilecek kontrol akışları var.

## 5) `scripts/player.gd` — özet
- `extends CharacterBody2D` — oyuncu hareketi, zıplama, saldırı, can sistemi.
- Sinyaller: `health_changed`, `down_started`, `recovered`.
- Saldırı mantığı: `start_attack()` -> `hit_nearest_enemy()`; en yakın düşmanı `enemy` grubundan seçiyor; mesafe ve facing kontrolü var.
- Kamera kontrolleri: `Camera2D` ile sınırlandırılmış hareket ve top-down benzeri smoothing kapalı.
- Durumlar: hurt, down, attacking yönetimleri; `down` süresinden sonra recover.

## 6) Diğer önemli script-sahne ilişkileri
- `food_cart.gd` muhtemelen servis etkileşimlerini, hp management'ı ve `interacted`, `hp_changed`, `destroyed` sinyallerini sağlıyor — `main.gd` bu sinyallere dayanıyor.
- `customer.gd` içinde `arrived`, `exited`, `patience_ran_out` sinyalleri bekleniyor.
- `enemy.gd` ve `tank_enemy.tscn` düşman davranışı ve `take_damage` metodunu sağlamalı (çünkü `player.gd` ve `main.gd` düşmana `take_damage` çağrıyor).

## 7) Asset durumu
- Karakter sprite'ları: `assets/character/` içinde çok sayıda PNG (hem oyuncu hem NPC animasyonları).
- Tileset: `assets/tileset/` içinde şehir arka planları ve tileset görselleri.
- Font: `ThaleahFat.ttf` mevcut ve import dosyası da var.
- Ses: `White Sands Day Night.mp3` ve import dosyası.

## 8) Gözlemler — çalışma zamanı hatası olasılıkları ve gerekli atamalar
- `main.gd`'de tanımlı `@export var trash_scene/customer_scene/enemy_scene/tank_scene` değişkenlerinin editörde atanması gerekiyor. Atanmazsa `push_error` ile hata verecek ve spawn işlemleri başarısız olur.
- `get_node_or_null("HUD/HUDRoot/...")` ile alınan label ve bar öğelerinin sahnede beklenen yollarla var olduğundan emin olun. Eğer HUD yapısı değiştiyse `null` dönebilir ve UI güncelleme eksik olur.
- `run/main_scene` UID'si `main.tscn` ile eşleşmiyorsa, proje açıldığında beklendiği sahne çalışmayabilir. Editörde `Project -> Project Settings -> Application -> Run -> Main Scene` kontrol edilmeli.
- `enemy.gd` ve `tank_enemy.tscn`'in `take_damage` gibi metodları ve `current_hp` değişkeni sağlaması gerekiyor; aksi takdirde `player.gd` veya `main.gd` çağrıları hata üretir.
- Input aksiyonlarının (`recipe_a`, `recipe_b`, `interact`, `attack`, vs.) doğru key/button ile eşlendiği `project.godot`'da zaten tanımlı görünüyor, fakat kullanıcı tarafından farklı atama yapılmışsa beklenti değişir.

## 9) Önerilen Kısa Testler (öncelik sırasına göre)
1. Godot 4.6 ile projeyi aç ve `Project -> Project Settings` içinde `Main Scene` atamasını doğrula. Ardından `Run` ile oyunu başlat.
2. `main.tscn` sahnesini aç; `Main` node (veya proje root'u) üzerindeki `Export` alanlarında `trash_scene`, `customer_scene`, `enemy_scene`, `tank_scene` atamalarını kontrol et.
3. `main.tscn` içinde `HUD/HUDRoot` yollarının scriptte aranan yollarla eşleştiğini doğrula.
4. Gündüz akışı: Temizleme -> Açma -> Müşteri akışı -> Tarif girişi -> Servis akışını çalıştır.
5. Gece akışı: Stand HP'si düşürülerek `start_night_phase()` testi; düşman spawn ve `tank_scene` için %20 olasılık gözle.

## 10) Potansiyel İyileştirme ve Refactor Önerileri
- Sahne ve Node referanslarını `onready var hud: HUD` tarzı tipli referanslarla (ve null check) daha sıkı tip kontrolüyle güvence altına almak.
- `recipes` verisini dış bir JSON / `Resource` haline getirip kolayca eklenti yapılabilir hale getirmek.
- Düşman seçimi ve saldırı menzili ayarlarını (`nearest_distance`) `export` yaparak tuning yapılmasını sağlamak.
- UI yollarını tek bir `HUD` scripti altında toplamak ve `main.gd`'nin UI'yı sadece `HUD` aracılığıyla güncellemesini sağlamak (loose coupling).

## 11) Oluşturulan Dosya
- Bu rapor kaydedildi: [PROJECT_REPORT.md](PROJECT_REPORT.md)

## 12) Sonraki Adımlar — nasıl ilerleyelim?
- İstersen proje için otomatik bir `checklist` oluşturayım (ör: eksik atamalar, eksik metodlar) ve `main.gd` ile `player.gd` üzerindeki potansiyel null/hata noktalarını satır bazında listeleyeyim.
- Ya da doğrudan `main.tscn` ve ilgili sahnelerde eksik atamaları otomatik arayıp raporlayabilirim (editör API gerekebilir). Hangisini tercih edersin?

---

Hazır. Bir sonraki adımı belirt (varsayılan olarak: `1) Eksik PackedScene atamalarını tespit edip listeleyeyim`, `2) Kodda potansiyel null referansları satır satır tespit edeyim`, `3) Başka bir GPT'ye aktarılacak daha yapılandırılmış JSON raporu oluşturayım`).
