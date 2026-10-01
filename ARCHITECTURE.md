# RepForge — Dokumen Arsitektur Aplikasi

Bangun aplikasi mobile full-stack sederhana bernama **RepForge — Aplikasi Pencatatan dan Pemantauan Progres Latihan**.

## Tujuan

RepForge adalah aplikasi mobile untuk mencatat latihan dan membantu pengguna memantau perkembangan latihan mereka secara konsisten.

Aplikasi memungkinkan pengguna untuk membuat akun, mengelola sesi latihan, memilih latihan, mencatat set, repetisi, dan beban, serta melihat riwayat latihan sebelumnya.

RepForge juga menyediakan fitur pertemanan sederhana sehingga pengguna dapat menambahkan pengguna lain sebagai teman dan melihat informasi profil serta aktivitas dasar yang dibagikan kepada teman.

Versi pertama harus tetap berfokus pada pencatatan latihan dan pemantauan progres. Jangan menambahkan fitur yang tidak diperlukan seperti chat, social media feed, pelacakan nutrisi, pembuatan program latihan berbasis AI, marketplace trainer, manajemen gym, atau sistem gamifikasi yang kompleks.

## Platform

Aplikasi dibuat sebagai **mobile application** menggunakan Flutter.

Pengguna utama berinteraksi dengan RepForge melalui aplikasi mobile Flutter.

## Teknologi yang Digunakan

Gunakan teknologi berikut:

* Frontend Mobile: Flutter + Dart
* Backend: Laravel + PHP
* Database: PostgreSQL
* ORM: Laravel Eloquent ORM
* Gaya API: REST API
* Authentication: Laravel Sanctum
* Local Development: Laravel Development Server
* Database Development: PostgreSQL menggunakan Docker Compose
* Konfigurasi Environment: `.env.example`

Arsitektur aplikasi:

```text
Flutter Mobile App
        |
        | HTTP / JSON
        v
Laravel REST API
        |
        | Eloquent ORM
        v
PostgreSQL
```

Backend bertanggung jawab atas autentikasi, business logic, validasi, pengelolaan data latihan, pengelolaan pertemanan, serta komunikasi dengan PostgreSQL.

Aplikasi Flutter harus berkomunikasi dengan backend melalui REST API.

Frontend tidak boleh terhubung langsung ke PostgreSQL.

## Aturan Kode

* Jangan menambahkan komentar kecuali benar-benar diperlukan.
* Gunakan struktur project yang bersih dan sederhana.
* Gunakan nama yang jelas dan deskriptif.
* Ikuti standar penamaan Dart untuk kode Flutter.
* Ikuti standar penamaan Laravel dan PHP.
* Controller hanya bertanggung jawab menangani HTTP request dan response.
* Business logic yang lebih kompleks dari CRUD dasar sebaiknya ditempatkan pada service class.
* Gunakan Laravel Form Request untuk validasi request jika diperlukan.
* Gunakan Eloquent relationship untuk entity yang saling berhubungan.
* Jangan menduplikasi business logic antara Flutter dan Laravel.
* Jangan menyimpan credential database atau secret di dalam source code.
* Gunakan `.env.example` untuk konfigurasi environment.
* Versi pertama harus tetap sederhana dan sesuai dengan skala project RPL mahasiswa.

# Entity Utama

## 1. User

Merepresentasikan akun pengguna RepForge.

Field:

* Id
* Name
* Email
* Password
* ProfilePhoto
* CreatedAt
* UpdatedAt

Satu user dapat memiliki banyak workout dan banyak teman.

## 2. Exercise

Merepresentasikan latihan yang tersedia di dalam exercise library RepForge.

Field:

* Id
* Name
* Description
* MuscleGroup
* Equipment
* CreatedAt
* UpdatedAt

Exercise merupakan data yang dapat digunakan oleh banyak user dan bukan milik satu user tertentu.

## 3. Workout

Merepresentasikan satu sesi latihan.

Field:

* Id
* UserId
* Name
* StartedAt
* CompletedAt
* CreatedAt
* UpdatedAt

Satu workout dimiliki oleh satu user dan dapat memiliki beberapa exercise.

## 4. WorkoutExercise

Merepresentasikan exercise yang dilakukan dalam suatu workout.

Field:

* Id
* WorkoutId
* ExerciseId
* Order
* CreatedAt

Satu workout dapat memiliki beberapa WorkoutExercise.

## 5. WorkoutSet

Merepresentasikan satu set latihan yang dilakukan untuk sebuah exercise.

Field:

* Id
* WorkoutExerciseId
* SetNumber
* Repetitions
* Weight
* CreatedAt
* UpdatedAt

Satu WorkoutExercise dapat memiliki beberapa WorkoutSet.

## 6. FriendRequest

Merepresentasikan permintaan pertemanan dari satu user ke user lainnya.

Field:

* Id
* SenderId
* ReceiverId
* Status
* CreatedAt
* UpdatedAt

Status friend request:

* `PENDING`
* `ACCEPTED`
* `REJECTED`

## 7. Friendship

Merepresentasikan hubungan pertemanan yang sudah diterima.

Field:

* Id
* UserId
* FriendId
* CreatedAt

Friendship dibuat ketika sebuah friend request diterima.

# Relasi Database

Relasi utama:

```text
User
 ├── hasMany Workouts
 ├── hasMany SentFriendRequests
 └── hasMany ReceivedFriendRequests

Workout
 ├── belongsTo User
 └── hasMany WorkoutExercises

Exercise
 └── hasMany WorkoutExercises

WorkoutExercise
 ├── belongsTo Workout
 ├── belongsTo Exercise
 └── hasMany WorkoutSets

WorkoutSet
 └── belongsTo WorkoutExercise

FriendRequest
 ├── belongsTo Sender
 └── belongsTo Receiver

Friendship
 ├── belongsTo User
 └── belongsTo Friend
```

# Aturan Database

* Email User harus bersifat unique.
* Exercise tidak boleh memiliki duplikasi data yang tidak diperlukan.
* Setiap Workout harus memiliki User yang valid.
* Setiap WorkoutExercise harus memiliki Workout dan Exercise yang valid.
* Setiap WorkoutSet harus memiliki WorkoutExercise yang valid.
* SetNumber harus unique dalam WorkoutExercise yang sama.
* Repetitions harus berupa bilangan bulat positif.
* Weight tidak boleh bernilai negatif.
* User tidak boleh mengirim friend request kepada dirinya sendiri.
* User tidak boleh membuat friend request pending yang sama secara berulang.
* User tidak boleh memiliki hubungan pertemanan yang sama lebih dari satu kali.
* Menghapus Workout harus menghapus WorkoutExercise dan WorkoutSet yang terkait sesuai dengan aturan relationship database.
* Riwayat workout tidak boleh terhapus secara tidak sengaja ketika mengubah data set.
* Gunakan Laravel migrations untuk mengelola struktur database.
* Gunakan database seeder untuk membuat contoh exercise dan data development.

# Authentication

RepForge membutuhkan akun pengguna.

Gunakan **Laravel Sanctum** untuk authentication API.

Fitur authentication:

1. Registrasi akun.
2. Login.
3. Logout.
4. Mendapatkan informasi user yang sedang login.
5. Melindungi endpoint workout dan friendship sehingga pengguna hanya dapat mengakses data yang memang memiliki izin.

Password harus di-hash secara aman menggunakan mekanisme Laravel.

Aplikasi Flutter menyimpan authentication token secara aman pada perangkat dan mengirimkannya pada request API yang membutuhkan authentication.

# Fitur Backend

## 1. Authentication

Endpoint yang disediakan:

* Register
* Login
* Logout
* Mendapatkan user yang sedang login

Validasi seluruh request registrasi dan login.

Berikan error yang sesuai untuk credential yang salah, email yang sudah digunakan, dan input yang tidak valid.

## 2. Exercise Library

Menyediakan library exercise sederhana.

Fitur:

* Melihat daftar exercise.
* Melihat detail exercise.
* Mencari exercise.
* Filter exercise berdasarkan muscle group.
* Menyediakan contoh exercise melalui database seeder.

Versi pertama tidak membutuhkan interface manajemen exercise yang kompleks untuk pengguna.

## 3. Workout Management

Pengguna dapat:

* Membuat workout.
* Memulai sesi workout.
* Menambahkan exercise ke workout.
* Mencatat set.
* Mengubah data set.
* Menghapus exercise dari workout.
* Menyelesaikan workout.
* Melihat riwayat workout.
* Melihat detail workout.
* Menghapus workout miliknya sendiri.

Alur utama workout:

```text
Mulai Workout
      |
      v
Pilih Exercise
      |
      v
Tambah Set
      |
      v
Masukkan Beban + Repetisi
      |
      v
Selesaikan Workout
      |
      v
Simpan ke Riwayat Workout
```

## 4. Workout Progress

Menyediakan informasi progres sederhana berdasarkan data workout yang tersimpan.

Aplikasi dapat menampilkan:

* Total workout.
* Total set.
* Total repetisi.
* Workout terakhir.
* Performa terakhir untuk suatu exercise.
* Performa sebelumnya untuk suatu exercise.
* Personal record untuk suatu exercise jika tersedia.

Versi pertama hanya menggunakan perhitungan sederhana dari data database.

Jangan menerapkan analisis progres berbasis AI yang kompleks.

## 5. Friendship

Pengguna dapat mencari pengguna lain dan mengirim friend request.

Fitur pertemanan:

* Mencari user.
* Mengirim friend request.
* Melihat friend request yang diterima.
* Menerima friend request.
* Menolak friend request.
* Menghapus teman.
* Melihat daftar teman.

Versi pertama tidak mencakup:

* Chat.
* Social feed.
* Like.
* Comment.
* Public post.
* Leaderboard.

## 6. Friend Profile

Pengguna dapat melihat informasi dasar mengenai teman mereka.

Profile dapat menampilkan:

* Name.
* Profile photo.
* Total workout.
* Aktivitas workout terbaru.
* Informasi progres dasar.

Hanya informasi yang memang ditujukan untuk dapat dilihat oleh teman yang boleh dikembalikan oleh API.

Pengguna tidak boleh mengakses data workout pribadi user lain tanpa authorization.

# API Routes

## Authentication

```text
POST /api/auth/register
POST /api/auth/login
POST /api/auth/logout
GET /api/auth/me
```

## Exercise

```text
GET /api/exercises
GET /api/exercises/:Id
```

## Workout

```text
GET /api/workouts
POST /api/workouts
GET /api/workouts/:Id
PUT /api/workouts/:Id
DELETE /api/workouts/:Id
POST /api/workouts/:Id/complete
```

## Workout Exercise

```text
POST /api/workouts/:WorkoutId/exercises
PUT /api/workout-exercises/:Id
DELETE /api/workout-exercises/:Id
```

## Workout Set

```text
GET /api/workout-exercises/:WorkoutExerciseId/sets
POST /api/workout-exercises/:WorkoutExerciseId/sets
PUT /api/workout-sets/:Id
DELETE /api/workout-sets/:Id
```

## Progress

```text
GET /api/progress
GET /api/progress/exercises/:ExerciseId
```

## Friends

```text
GET /api/friends
POST /api/friends/requests
GET /api/friends/requests
POST /api/friends/requests/:Id/accept
POST /api/friends/requests/:Id/reject
DELETE /api/friends/:Id
```

## User Search dan Profile

```text
GET /api/users/search
GET /api/users/:Id
```

# Aturan API Response

Gunakan JSON untuk response API.

Response yang berhasil harus mengembalikan resource atau hasil operasi yang diminta.

Validation error harus menggunakan HTTP status code yang sesuai dan memberikan pesan error yang jelas.

API tidak boleh mengembalikan:

* Password hash.
* Authentication secret.
* Credential database.
* Informasi private milik user lain.

Gunakan Laravel API Resources jika diperlukan untuk mengontrol struktur response API.

# Halaman / Screen Frontend

## 1. Login

Fitur:

* Input email.
* Input password.
* Tombol login.
* Pesan validasi.
* Link menuju halaman registrasi.

## 2. Register

Fitur:

* Input nama.
* Input email.
* Input password.
* Konfirmasi password.
* Tombol registrasi.
* Pesan validasi.

## 3. Home / Dashboard

Menampilkan ringkasan aktivitas latihan pengguna:

* Total workout.
* Workout terbaru.
* Exercise terbaru.
* Informasi progres dasar.
* Tombol cepat untuk memulai workout.

Jangan menambahkan chart yang kompleks pada versi pertama.

## 4. Start Workout

Fitur:

* Nama workout.
* Pencarian exercise.
* Pemilihan exercise.
* Menambahkan exercise.
* Mencatat set.
* Input beban.
* Input repetisi.
* Menghapus exercise.
* Menyelesaikan workout.

Halaman workout harus mengutamakan proses input data yang cepat karena digunakan ketika pengguna sedang berlatih.

## 5. Workout History

Menampilkan:

* Workout sebelumnya.
* Nama workout.
* Tanggal.
* Durasi jika tersedia.
* Jumlah exercise.
* Jumlah set.

Pengguna dapat membuka workout untuk melihat detailnya.

## 6. Workout Detail

Menampilkan:

* Informasi workout.
* Exercise yang dilakukan.
* Set.
* Beban.
* Repetisi.
* Tanggal workout.

## 7. Progress

Menampilkan informasi progres dasar.

Fitur:

* Memilih exercise.
* Performa sebelumnya.
* Performa terbaru.
* Personal record jika tersedia.
* Jumlah workout yang menggunakan exercise tersebut.

Jangan menambahkan analytics atau chart yang kompleks pada versi pertama.

## 8. Friends

Menampilkan:

* Daftar teman.
* Pencarian user.
* Friend request yang menunggu.
* Aksi tambah teman.
* Menerima request.
* Menolak request.
* Menghapus teman.

## 9. Friend Profile

Menampilkan:

* Nama.
* Profile photo.
* Statistik workout dasar.
* Aktivitas terbaru yang diizinkan untuk dibagikan.

## 10. Profile / Settings

Menampilkan:

* Nama user.
* Email.
* Profile photo.
* Tombol logout.

# Persyaratan UI

* Gunakan Bahasa Indonesia untuk seluruh label, tombol, pesan, dan validasi yang ditampilkan kepada pengguna.
* Buat interface mobile yang bersih dan modern.
* Prioritaskan kemudahan penggunaan ketika pengguna sedang melakukan workout.
* Gunakan card, list, form, button, badge, dan confirmation dialog sederhana.
* Tampilkan loading state ketika melakukan API request.
* Tampilkan pesan berhasil dan error yang mudah dipahami.
* Tampilkan empty state ketika pengguna belum memiliki workout, exercise, atau teman.
* Gunakan confirmation dialog untuk tindakan yang bersifat menghapus.
* Hindari animasi yang berlebihan.
* Jangan menambahkan chart yang tidak diperlukan pada versi pertama.
* Interface harus tetap sederhana sehingga realistis untuk project RPL mahasiswa.

# Alur Data

## Login

```text
Flutter
   |
   | POST /api/auth/login
   v
Laravel
   |
   | Validasi credential
   v
PostgreSQL
   |
   | Data User
   v
Laravel
   |
   | Authentication Token
   v
Flutter
```

## Mencatat Workout

```text
Flutter
   |
   | Create Workout
   v
Laravel
   |
   | Eloquent
   v
PostgreSQL
```

Exercise dan set kemudian disimpan melalui endpoint REST API masing-masing.

## Melihat Progress

```text
Flutter
   |
   | GET /api/progress
   v
Laravel
   |
   | Query data workout menggunakan Eloquent
   v
PostgreSQL
   |
   | Data workout
   v
Laravel
   |
   | Menghitung progress
   v
Flutter
```

## Menambahkan Teman

```text
User A
  |
  | Mengirim friend request
  v
Laravel
  |
  v
PostgreSQL
  |
  | Pending request
  v
User B
  |
  | Menerima request
  v
Laravel
  |
  v
PostgreSQL
  |
  | Friendship dibuat
```

# Struktur Project

Gunakan struktur project Flutter dan Laravel yang bersih.

## Flutter

```text
repforge/
  mobile/
    lib/
      core/
        constants/
        network/
        storage/
        theme/
      models/
      services/
      repositories/
      providers/
      screens/
        auth/
        home/
        workout/
        history/
        progress/
        friends/
        profile/
      widgets/
      main.dart
```

Library state management dapat dipilih berdasarkan kebutuhan project, tetapi jangan menggunakan architecture atau library yang menambah kompleksitas tanpa alasan.

## Laravel

```text
api/
  app/
    Http/
      Controllers/
      Requests/
      Resources/
    Models/
    Services/
  database/
    migrations/
    seeders/
  routes/
    api.php
  config/
  .env.example
```

Gunakan struktur Laravel standar dan jangan membuat struktur backend terlalu kompleks.

# Database Development

Gunakan Docker Compose untuk PostgreSQL selama development.

Struktur project:

```text
repforge/
  mobile/
  api/
  docker-compose.yml
  README.md
```

Docker Compose harus menyediakan PostgreSQL database untuk local development.

Gunakan `.env.example` untuk konfigurasi seperti:

```text
DB_CONNECTION=pgsql
DB_HOST=...
DB_PORT=5432
DB_DATABASE=...
DB_USERNAME=...
DB_PASSWORD=...
```

Jangan menyimpan credential database asli di repository.

# Database Migration dan Seed

Gunakan Laravel migrations untuk membuat struktur database.

Sediakan seed data untuk:

* Contoh user.
* Exercise umum seperti Bench Press, Squat, Deadlift, Pull Up, Push Up, dan Shoulder Press.
* Contoh workout jika diperlukan untuk development.

Seed data harus dipisahkan dengan jelas dari data pengguna sebenarnya.

# Pertimbangan Offline

Versi pertama memprioritaskan arsitektur online yang sederhana:

```text
Flutter
   |
   v
Laravel REST API
   |
   v
PostgreSQL
```

Fitur pencatatan workout secara offline dapat dipertimbangkan sebagai pengembangan berikutnya.

Jika fitur offline diterapkan pada versi berikutnya, SQLite dapat digunakan sebagai local database atau cache di dalam aplikasi Flutter.

Penambahan SQLite tidak menggantikan PostgreSQL sebagai primary database selama RepForge sudah mendukung account dan fitur multi-user.

Arsitektur offline di masa depan dapat berupa:

```text
             Flutter
                |
        ┌───────┴───────┐
        v               v
     SQLite         Laravel API
        |               |
        | Sync          v
        └──────────> PostgreSQL
```

Jangan menerapkan mekanisme sinkronisasi yang kompleks pada versi pertama kecuali memang diwajibkan.

# Persyaratan Keamanan

* Gunakan Laravel Sanctum untuk authentication.
* Hash password menggunakan mekanisme hashing standar Laravel.
* Validasi seluruh input API.
* Gunakan authorization agar pengguna hanya dapat mengubah workout miliknya sendiri.
* Pengguna tidak dapat mengubah data workout milik pengguna lain.
* Pengguna tidak dapat mengakses informasi private milik pengguna lain.
* Validasi seluruh operasi friendship pada backend.
* Gunakan environment variable untuk credential database dan application secret.
* Jangan menyimpan password dalam bentuk plain text.
* Jangan menampilkan error database internal secara langsung kepada pengguna.

# Batasan Scope

Versi pertama TIDAK mencakup:

* Manajemen gym.
* Manajemen membership.
* Manajemen trainer.
* Payment processing.
* Subscription billing.
* Chat.
* Social media feed.
* Like dan comment.
* AI workout generation.
* AI coaching.
* Nutrition tracking.
* Calorie tracking.
* Gamifikasi kompleks.
* Integrasi wearable yang kompleks.
* Sistem rekomendasi yang kompleks.
* Multi-gym management.
* Marketplace.

Fitur-fitur tersebut dapat dipertimbangkan pada versi berikutnya, tetapi berada di luar scope MVP.

# Kriteria Keberhasilan MVP

Versi pertama dianggap berhasil apabila pengguna dapat:

1. Membuat akun.
2. Login.
3. Memulai workout.
4. Memilih exercise.
5. Mencatat set, beban, dan repetisi.
6. Menyelesaikan dan menyimpan workout.
7. Melihat riwayat workout.
8. Melihat progres dasar.
9. Mencari pengguna lain.
10. Mengirim friend request.
11. Menerima atau menolak friend request.
12. Melihat daftar teman.
13. Melihat informasi dasar profile teman.
14. Logout.

Aplikasi harus dapat dibuild dengan baik, Laravel API dapat berjalan dengan baik, database migration dapat dijalankan, seed data tersedia, serta alur utama API dan aplikasi mobile dapat berjalan dengan benar.

# Deliverables

Sediakan:

* Source code Flutter mobile.
* Source code Laravel backend.
* Konfigurasi database PostgreSQL.
* Laravel migrations.
* Laravel seeders.
* Laravel Eloquent models dan relationships.
* Laravel API controllers.
* Laravel Form Requests jika diperlukan.
* Laravel API Resources jika diperlukan.
* Laravel Sanctum authentication.
* REST API routes.
* Flutter API services.
* Flutter models.
* Flutter screens dan reusable widgets.
* Docker Compose untuk PostgreSQL.
* `.env.example`.
* README yang berisi:

  * Penjelasan project.
  * Technology stack.
  * Arsitektur sistem.
  * Cara instalasi.
  * Setup PostgreSQL dengan Docker.
  * Setup Laravel.
  * Database migration.
  * Database seeding.
  * Setup Flutter.
  * Menjalankan backend.
  * Menjalankan aplikasi mobile.
  * Konfigurasi environment.
  * Konfigurasi authentication.
  * Gambaran penggunaan API.

Pastikan aplikasi tetap sederhana, mudah dipelihara, dan realistis untuk project RPL mahasiswa.
