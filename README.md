# Kasir Mini

Aplikasi kasir minimarket untuk Android, dibuat dengan Flutter (proyek praktikum PTI).
Semua teks antarmuka berbahasa Indonesia. Data disimpan di HP (tanpa internet).

## Cara menjalankan

Prasyarat: Flutter stable (diuji dengan 3.44.0 / Dart 3.12) dan Android SDK.

```bash
flutter pub get
flutter run                     # HP/emulator Android terhubung
flutter build apk --debug       # hasil: build/app/outputs/flutter-apk/app-debug.apk
flutter analyze && flutter test
```

- PIN bawaan: **1234** (konstanta `kAppPin` di `lib/constants.dart`).
- Saat pertama dijalankan, aplikasi berisi 10 produk contoh dan 3 transaksi dummy hari ini (TRX-0041 sampai 0043).
- `minSdk` 24 (mobile_scanner butuh minimal 23). Izin `CAMERA` sudah ada di manifest; `uses-feature camera` diberi `required="false"`.

## Struktur `lib/`

| Folder | Isi |
|---|---|
| `models/` | `Product`, `Sale`/`SaleItem`, `CartLine`, `AppData` |
| `store/` | `AppStore` (ChangeNotifier: keranjang, checkout, produk, backup) dan `AppScope` |
| `services/` | penyimpanan, backup, format rupiah, validator form, `BarcodeBuffer`, `ScanDebouncer`, teks struk |
| `screens/` | 13 layar sesuai desain |
| `widgets/` | komponen bersama (tombol, chip, baris produk, sheet kode belum terdaftar, dst.) |
| `theme/` | warna, radius, gaya teks |

Font IBM Plex Sans dan Mono dibundel di `assets/fonts` (lisensi SIL OFL).

## Cara uji scanner

### Kamera (mobile_scanner)
1. Di layar Kasir ketuk **Scan**. Izinkan akses kamera.
2. Arahkan ke barcode produk (mis. cetak/tampilkan kode `8998866200318` = Indomie Goreng). Semua kode contoh sudah memakai digit periksa yang benar. Barang masuk keranjang dan muncul di "Terakhir dipindai".
3. Barcode dibaca hanya di dalam kotak bidik. Kode diterima setelah terbaca sama pada 3 frame berturut-turut dan lolos digit periksa (EAN-13/EAN-8/UPC-A/UPC-E; kode dengan digit periksa salah ditolak dengan petunjuk "Barcode kurang jelas"). Bila ada beberapa barcode berbeda di kotak, tidak ada yang diambil. UPC-A 12 digit dan EAN-13 berawalan 0 dianggap kode yang sama. Kode yang sama dalam 1,5 detik diabaikan. Selama kamera tetap mengarah ke kode yang sama, tidak ada penambahan berulang. Jauhkan kamera sebentar untuk menambah lagi.
4. Kode yang belum ada di produk membuka sheet "Kode belum terdaftar".
5. Di Form produk, tombol **Scan** membaca satu kode lalu menutup kamera.

### Scanner fisik USB/Bluetooth (mode keyboard, belum diuji dengan alat asli)
Logika ada di `BarcodeBuffer` (Dart murni) dan `KeyboardScannerListener` (memakai `HardwareKeyboard.instance.addHandler`). Aktif hanya bila layar Kasir tampil paling atas dan tidak ada kolom teks yang fokus. Buffer direset bila jeda antar karakter > 100 ms; kode diproses saat Enter.

Cara menguji setelah punya scanner:
1. Sambungkan scanner ke HP (OTG untuk USB, atau pairing Bluetooth mode HID/keyboard).
2. Buka layar Kasir, jangan ketuk kolom teks apa pun.
3. Pindai barcode produk. Barang harus masuk keranjang dengan pesan "Terpindai: ...".
4. Pindai kode yang tidak ada: sheet "Kode belum terdaftar" muncul.
5. Jika tidak terbaca: pastikan scanner mengirim Enter (suffix) di pengaturannya. Jika scanner lambat (>100 ms antar karakter), ubah `maxGap` di `lib/services/barcode_buffer.dart`.

Sebelum punya alat, uji dengan keyboard Bluetooth biasa atau emulator: ketik cepat lalu Enter tidak bisa dilakukan manusia dalam <100 ms, jadi gunakan unit test (`test/barcode_buffer_test.dart`) dan widget test (`test/ui_flow_test.dart`, mensimulasikan ketikan cepat).

## Format backup

Backup berupa teks JSON yang disalin ke clipboard (bisa ditempel ke WhatsApp/Catatan, lalu dipulihkan di HP lain):

```json
{"app":"kasir-mini","version":1,"exportedAt":"2026-09-21T16:05:00.000",
 "products":[{"id":1,"name":"Indomie Goreng","code":"8998866200318","price":3500,"stock":84}],
 "transactions":[{"no":"TRX-0041","time":"2026-09-21T09:12:00.000",
   "items":[{"productId":3,"name":"Aqua 600 ml","qty":2,"price":3500}],
   "total":23500,"method":"tunai","tendered":25000,"change":1500}],
 "nextNo":44}
```

- `method`: `tunai`, `qris`, atau `debit`. `tendered` dan `change` hanya untuk tunai.
- PIN tidak ikut di-backup.
- Restore mengganti seluruh data. JSON rusak, bukan milik Kasir Mini, versi selain 1, atau isi tidak valid (harga negatif, ID/kode ganda, dsb.) ditolak dengan pesan error dan data yang ada tidak diubah.
- Penyimpanan internal: satu JSON di shared_preferences (kunci `kasir_mini_data`) dengan isi yang sama plus `lastBackupAt`.

## Batasan

- **QRIS dan Debit hanya simulasi.** Tidak ada integrasi QRIS/EDC asli; layar diberi label "SIMULASI" dan gambar QR hanya ilustrasi.
- **Cetak struk hanya simulasi** (snackbar). **Kirim WhatsApp** menyalin teks struk ke clipboard.
- Tidak ada cetak sungguhan, sinkronisasi cloud, atau multi-pengguna.
- Nama kasir dan toko ("Rina", "Toko Sinar Jaya") adalah konstanta di `lib/constants.dart`.
- Keranjang tidak disimpan bila aplikasi ditutup.

## Yang belum bisa diverifikasi di lingkungan pengembangan

- Kamera sungguhan (emulator tidak punya barcode nyata) dan izin kamera di HP asli.
- Scanner fisik USB/Bluetooth.
- Perilaku di berbagai ukuran layar/HP selain emulator Pixel dan tes pada ukuran 390x844.

## Asumsi dan perbedaan dari desain

1. Transaksi contoh: 3 transaksi dummy hari ini (sesuai permintaan pemilik), nomor berikutnya 44.
2. "Penjualan hari ini" dan jumlah transaksi dihitung dari tanggal transaksi = hari ini; daftar di bawahnya menampilkan semua transaksi, terbaru di atas.
3. Bilah status (jam, baterai) pada SVG tidak ditiru; memakai bilah status sistem.
4. Navigasi bawah 4 tab (Kasir, Riwayat, Stok, Kelola) sesuai SVG; prototype hanya 3.
5. Produk cepat: 6 produk pertama, digulir horizontal (SVG menampilkan 3 yang muat).
6. Baris keranjang: tombol +/- dan hapus diberi area sentuh ≥ 44-48 dp, sehingga nama panjang membungkus ke dua baris.
7. "Tempel & pulihkan data" membaca clipboard. Kolom tempel manual (tidak ada di SVG) baru muncul bila clipboard kosong atau isinya tidak valid.
8. Bila Kasir dibuka dengan produk yang stoknya diubah ke bawah jumlah keranjang, jumlah di keranjang dipotong ke stok baru.
9. Produk tanpa kode ditulis "tanpa barcode" di daftar.
10. Format tanggal: `21 Sep 2026, 16.05` (titik sebagai pemisah jam), dibuat sendiri tanpa `intl`.
11. Jeda deduplikasi kamera 1,5 detik dihitung sejak kode terakhir terlihat (bukan sejak diterima), agar kamera yang diam di satu barcode tidak menambah berulang.
12. Data tersimpan yang rusak dianggap tidak ada dan diganti data contoh.
13. Paket: hanya `shared_preferences` dan `mobile_scanner`.

## Tes

`flutter test` mencakup: format rupiah, total dan kembalian, checkout (stok berkurang, snapshot struk), batas stok, filter stok menipis, validasi form (kode unik), roundtrip dan penolakan backup, `BarcodeBuffer`, `ScanDebouncer`, serta alur UI utama (login, bayar, struk, backup, scanner keyboard).
