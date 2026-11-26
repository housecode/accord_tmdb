# MovieApp

Aplikasi iOS (UIKit, arsitektur VIPER) untuk menjelajah film dari [TMDB](https://www.themoviedb.org/): daftar genre, daftar film per genre, detail film, review, dan trailer.

## Kebutuhan

- macOS dengan Xcode 15+ (project diuji di Xcode dengan iOS Simulator 26.5)
- iOS deployment target 17.0
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (opsional, hanya jika ingin generate ulang `.xcodeproj`)
- [SwiftLint](https://github.com/realm/SwiftLint) (opsional)
- Akun TMDB untuk mendapat API Read Access Token

```bash
brew install xcodegen swiftlint
```

## Setup

### 1. Ambil TMDB token

1. Daftar / login di https://www.themoviedb.org/
2. Buka **Settings → API** dan salin **API Read Access Token** (string panjang berawalan `eyJ...`).

### 2. Buat file secrets

`Config/Secrets.xcconfig` di-ignore git, jadi buat dari template:

```bash
cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
```

Edit file itu, ganti nilainya:

```
TMDB_ACCESS_TOKEN = eyJ...token_kamu...
```

Token dibaca lewat `Info.plist` (`TMDBAccessToken`) oleh `Core/Config/AppConfig.swift`. Tanpa token valid, request API akan gagal dengan 401.

### 3. (Opsional) Generate project

`MovieApp.xcodeproj` sudah ada di repo. Jika menambah/menghapus file atau mengubah `project.yml`, generate ulang:

```bash
xcodegen generate
```

## Menjalankan

### Lewat Xcode

```bash
open MovieApp.xcodeproj
```

Pilih scheme **MovieApp**, pilih simulator (mis. iPhone 17), lalu tekan `Cmd+R`.

### Lewat terminal

```bash
# Build
xcodebuild -project MovieApp.xcodeproj -scheme MovieApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath build build

# Install dan jalankan di simulator
xcrun simctl boot "iPhone 17" 2>/dev/null || true
open -a Simulator
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/MovieApp.app
xcrun simctl launch booted com.example.MovieApp
```

## Test

```bash
xcodebuild -project MovieApp.xcodeproj -scheme MovieApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Atau `Cmd+U` di Xcode. Test ada di folder `Tests/` (Core, Genres, MovieList, MovieDetail, Reviews).

## Lint

```bash
swiftlint
```

Konfigurasi di `.swiftlint.yml`.

## Struktur project

```
App/        AppDelegate, SceneDelegate, Info.plist
Config/     xcconfig (Debug, Release, Secrets)
Core/       Network, Models, Paging, Images, UI helper, AppConfig
Modules/    Fitur VIPER: Genres, MovieList, MovieDetail, Reviews, Trailer
Tests/      Unit test per modul
project.yml Definisi XcodeGen
```

Tiap modul di `Modules/` berisi Builder, View(Controller), Presenter, Interactor, Entity, Router, dan Protocols.

## Troubleshooting

- **List kosong / error 401**: cek `TMDB_ACCESS_TOKEN` di `Config/Secrets.xcconfig`. Pastikan memakai *Read Access Token*, bukan API Key v3.
- **Perubahan token tidak terbaca**: Clean build folder (`Shift+Cmd+K`) lalu build ulang.
- **Signing error saat run di device**: set `DEVELOPMENT_TEAM` di `project.yml` (lalu `xcodegen generate`) atau pilih Team di Xcode. Simulator tidak butuh signing.
