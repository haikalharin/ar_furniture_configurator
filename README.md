# AR Furnitur Configurator (prototype)

Aplikasi Flutter untuk sesi fitting bersama client: pilih furnitur, atur ukuran,
material, warna, dan aksen, lihat estimasi harga langsung, lalu tempatkan
furnitur dengan ukuran asli di ruangan client lewat AR.

Dibuat dengan **Flutter 3.44.0** (Dart 3.12).

## Menjalankan

```bash
flutter pub get
flutter run        # sambungkan HP Android (ARCore) atau iPhone
flutter test
```

## Alur di aplikasi

1. **Pilih Furnitur**: 18 item dengan filter kategori ruangan.
   - Kamar tidur: lemari pakaian, tempat tidur (headboard berjok), nakas, meja rias (dengan cermin)
   - Ruang tamu: bufet TV, backdrop TV, meja kopi, rak buku, lemari pajangan (pintu kaca), rak sepatu
   - Dapur: kitchen set bawah (top table + kolom laci), kabinet gantung (terpasang 145 cm dari lantai)
   - Ruang makan: meja makan, kursi makan (dudukan berjok), bangku
   - Kerja & komersial: meja kerja, meja bar kafe, meja resepsionis
2. **Konfigurator**: slider ukuran (langkah 5 cm), material, warna, aksen handle/kaki.
   Pratinjau 3D dan harga berubah seketika. Ada gambar kerja (tampak depan dan samping)
   dan rincian biaya.
3. **Lihat di ruangan (AR)**: tombol di pratinjau 3D untuk melihat satu item cepat
   (Scene Viewer). Skala dikunci 1:1 dan model diletakkan di lantai.
4. **Tata Ruangan (AR)**: ikon AR di katalog/penawaran, atau "Tata di AR" setelah
   menambah item. Pilih item di baki bawah lalu ketuk lantai; ulangi untuk item
   berikutnya, item yang sudah ditaruh tetap ada. Geser satu jari untuk memindah,
   putar dua jari untuk memutar, ketuk item untuk memilih lalu "Hapus". Tombol
   "Tambah" membuka katalog dan kembali ke ruangan tanpa menghapus susunan.
   Banner atas menampilkan jumlah item dan total harga yang ada di ruangan.
5. **Penawaran**: kumpulkan beberapa item, isi nama client dan ruangan, lalu
   "Salin ringkasan" untuk ditempel ke WhatsApp.

## Cara kerjanya

- `lib/geometry/furniture_builder.dart` menyusun furnitur dari panel-panel (balok)
  sesuai ukuran pilihan, jadi model 3D selalu berukuran asli.
- `lib/geometry/glb_writer.dart` menulis model itu menjadi file GLB (glTF 2.0) di HP.
  Tidak perlu file 3D dari desainer untuk tiap ukuran/warna.
- `lib/widgets/model_preview.dart` menampilkan GLB lewat `model_viewer_plus`;
  setiap perubahan pilihan menulis ulang file dan memuat ulang pratinjau.
- `lib/pricing/price_calculator.dart` menghitung harga dari luas panel yang sama
  dengan model 3D: bahan (+15% sisa potong), aksen per pcs, engsel/rel laci,
  kaca/cermin dan jok kain per m², ongkos kerja dasar + 25% biaya bahan,
  dibulatkan ke Rp 10.000.

## Menyesuaikan data

Semua harga, material, warna, dan rentang ukuran ada di
`lib/models/catalog.dart` dan `lib/pricing/price_calculator.dart`. Angkanya
masih **mock** dan perlu diganti dengan daftar harga workshop.

## Batasan prototype

- **Tata Ruangan (AR)** memakai `ar_flutter_plugin_plus` (ARCore di Android, ARKit di
  iOS 15+). Menurut plugin, ARCore di sebagian HP Android melacak lebih stabil bila
  aplikasi dibangun non-debuggable (`flutter run --release`). Susunan belum tersimpan
  setelah layar AR ditutup.

- **Android**: AR memakai Google Scene Viewer (perlu HP yang mendukung ARCore dan
  aplikasi Google). Client masih bisa mencubit untuk mengubah skala di Scene Viewer;
  angka persentase di layar menunjukkan 100% saat ukuran asli.
- **iOS**: AR Quick Look umumnya tidak bisa dibuka dari dalam WebView, jadi tombol
  AR di iPhone kemungkinan belum berfungsi. Langkah berikutnya: ekspor USDZ dan buka
  dengan `QLPreviewController` lewat platform channel, atau pakai plugin ARKit.
- Material masih berupa warna polos (tanpa tekstur serat kayu). Warna kaca,
  cermin, dan kain jok masih tetap (belum bisa dipilih).
- Belum diuji di perangkat fisik; logika model, GLB, dan harga sudah diuji otomatis
  dan file GLB lolos Khronos glTF Validator.
