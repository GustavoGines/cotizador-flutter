# Cotizador Dólar — App Flutter

App móvil en **Flutter** para convertir **USD ⇄ ARS** y visualizar **promedios mensuales** (gráfico barras/líneas) consumiendo la API Laravel.
Incluye **Firebase Analytics** y publicación del **APK** en *GitHub Releases*.

---

## 🧭 Endpoints (backend)

- **Prod API base:** `https://cotizador-dolar-api.onrender.com/api`
- **Local API base:** `http://127.0.0.1:8000/api`

Configurable en `lib/config/app_config.dart` (ver más abajo).

---

## 🗂️ Estructura (resumen)

```text
lib/
├─ main.dart
├─ screens/
│  ├─ convertidor_screen.dart      # Conversión USD⇄ARS
│  └─ promedios_screen.dart        # Promedios mensuales (fl_chart)
├─ services/
│  ├─ convertidor_service.dart     # GET /cotizaciones/convertir
│  ├─ promedios_service.dart       # GET /cotizaciones/promedio-mensual
│  └─ update_service.dart          # Check de actualizaciones (opcional)
├─ widgets/
│  └─ app_shell.dart               # AppBar, tema, drawer, etc.
└─ config/
   └─ app_config.dart              # BASE_URL y flags
```

---

## ⚙️ Configuración

### 1) URL del backend
Crea `lib/config/app_config.dart`:

```dart
class AppConfig {
  static const String baseApi =
      String.fromEnvironment('BASE_API', defaultValue: 'https://cotizador-dolar-api.onrender.com/api');
  static const bool enableAnalytics =
      bool.fromEnvironment('ANALYTICS', defaultValue: true);
  static const String appRepo =
      'https://github.com/GustavoGines/cotizador-dolar-api';
}
```

Usa en servicios:
```dart
final base = AppConfig.baseApi;
```

Para **local**:
```bash
flutter run --dart-define=BASE_API=http://127.0.0.1:8000/api
```

### 2) Permisos Android
`android/app/src/main/AndroidManifest.xml` debe permitir Internet:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### 3) Firebase Analytics (opcional)
- Configurado con `firebase_analytics`. Asegurate de tener `google-services.json` en `android/app/`.
- Plugins (en `android/build.gradle` y `android/app/build.gradle`):
  ```gradle
  // android/build.gradle
  buildscript {
      dependencies {
          classpath 'com.google.gms:google-services:4.3.15'
      }
  }
  // android/app/build.gradle
  plugins {
      id "com.android.application"
      id "dev.flutter.flutter-gradle-plugin"
      id "com.google.gms.google-services"
  }
  dependencies {
      implementation platform("com.google.firebase:firebase-bom:34.3.0")
      implementation "com.google.firebase:firebase-analytics"
  }
  ```

**Verificar eventos**
- **Realtime:** Firebase Console → Analytics → *Realtime*.
- **DebugView (ADB):**
  ```bash
  adb shell setprop debug.firebase.analytics.app com.example.cotizador_dolar_api
  ```

---

## ▶️ Desarrollo

```bash
flutter pub get
flutter run --dart-define=BASE_API=https://cotizador-dolar-api.onrender.com/api
```

### Temas
El app soporta claro/oscuro desde el `AppShell`. La versión de la app se muestra en el footer del Drawer/AppBar.

---

## 📦 Build de release (APK)

### 1) Firma
Crea `android/key.properties`:
```properties
storePassword=********
keyPassword=********
keyAlias=upload
storeFile=../app/my-release-key.jks
```

Actualiza `android/app/build.gradle` (sección `android { ... }`):
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    defaultConfig {
        applicationId "com.example.cotizador_dolar_api"
        versionName "1.0.8"
        versionCode 1  // incrementalo en cada release
    }
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            // proguardFiles ...
        }
    }
}
```

> **¿Por qué `1.0.8+1`?**  
> `versionName` = **1.0.8**, `versionCode` = **1**. Android muestra `1.0.8 (1)`. Sube `versionCode` en cada publicación.

### 2) Compilar
```bash
flutter clean
flutter pub get
flutter build apk --release \
  --dart-define=BASE_API=https://cotizador-dolar-api.onrender.com/api \
  --dart-define=ANALYTICS=true
```
APK resultante: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🚀 Publicación (GitHub Releases)

1. Crea un tag y release en GitHub, subiendo `app-release.apk` como asset.
2. **Link de descarga directa (última versión):**
   ```
   https://github.com/GustavoGines/cotizador-dolar-api/releases/latest/download/app-release.apk
   ```
3. (Opcional) Workflow de CI para generar el APK automáticamente.

---

## 🧪 Tests manuales rápidos

- Conversión USD→ARS (blue y oficial).
- Conversión ARS→USD.
- Promedios: filtros por año/mes y cambio de gráfico (barras/líneas).
- Modo oscuro.
- Analytics: pantalla Convertidor y Promedios registran `screen_view`.

---

## 🛠️ Troubleshooting

- **Right overflowed by X pixels**: Usa `Expanded/Flexible`, reduce el `Text` con `softWrap:false, overflow: TextOverflow.ellipsis` o `FittedBox`, y preferí `Wrap` para chips/checkbox con poco ancho.
- **`GeneratedPluginRegistrant` no encuentra `FlutterFirebaseAnalyticsPlugin`**: verifica `firebase_analytics` en `pubspec.yaml`, corre `flutter pub get`, limpia (`flutter clean`) y recompila. Confirmá que `google-services.json` existe y que el plugin `com.google.gms.google-services` está aplicado.
- **Versión de Google Services**: alinear `classpath 'com.google.gms:google-services:4.3.15'` con la BOM usada.
- **Network en Android 9+ (Cleartext)**: si usás `http://` local, crea `network_security_config` y habilita cleartext o usa `https`/emulador con proxy.

---

## 📄 Licencia

Uso académico/demostrativo.
