# Configuracion Android (una sola vez)

1. Crea el proyecto base y copia encima `lib/` y `pubspec.yaml` de esta carpeta:

       flutter create --org mx.barbacoa --project-name barbacoa_movil .
       flutter pub get

2. `android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>` y ANTES de `<application>`:

       <uses-permission android:name="android.permission.INTERNET"/>
       <uses-permission android:name="android.permission.CAMERA"/>

   y en la etiqueta `<application ...>` agrega `android:usesCleartextTraffic="true"`
   (solo mientras uses http:// en desarrollo; con HTTPS se quita).

3. `android/app/build.gradle(.kts)`: `minSdk` debe ser 21 o mayor (el valor por defecto de Flutter sirve).

4. Ejecutar:

       flutter run --dart-define=API_URL=http://TU_IP_LOCAL:8080/api

   Emulador: puedes omitir --dart-define (usa 10.0.2.2). Telefono fisico: misma red Wi-Fi que la PC
   y permite el puerto 8080 en el firewall de Windows.

5. (iOS, opcional) `ios/Runner/Info.plist`: agrega `NSCameraUsageDescription`.
