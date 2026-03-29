# Local API Simulator Run

Bu not lokal backend ile iOS simülatörde çalıştırma akışını sabitler.

## Backend

Backend'i lokal HTTP ile kaldır:

```bash
cd /Users/gokmenkucuk/Desktop/App/somine_api
ASPNETCORE_ENVIRONMENT=Development ASPNETCORE_URLS=http://127.0.0.1:5181 dotnet run --no-launch-profile --project src/SomineApi.WebApi/SomineApi.WebApi.csproj
```

Kontrol:

```bash
curl -s http://127.0.0.1:5181/health
```

## Flutter

Mobili backend URL ile çalıştır:

```bash
cd /Users/gokmenkucuk/Desktop/App/SoMine/somine_app
flutter run --dart-define=SOMINE_API_BASE_URL=http://127.0.0.1:5181
```

## iOS Notu

`ios/Runner/Info.plist` içine lokal HTTP erişimi için ATS istisnası eklendi:

- `localhost`
- `127.0.0.1`

Bu sayede iOS simülatörde lokal API'ye düz HTTP ile bağlanabilir.

## Beklenen Davranış

- login sonrası backend session oluşur
- kullanıcı verileri API'den gelir
- category/item/share/reminder/notification/storage/subscription akışları backend-aware çalışır

## Bilinen Şey

- Firebase Auth köprüsü hâlâ açık
- simülatörde Google/Apple login testleri için ilgili provider kurulumları yine gerekli
