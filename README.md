# Shoply

A Flutter Android product catalogue with search, product details, and a persistent wishlist. Powered by the [DummyJSON API](https://dummyjson.com/docs/products); no API key is required.

This project targets Android only; unused platform folders have been removed.

## Run the project

1. Install Flutter **3.44.0** (Dart **3.12.0**) and Android Studio with the Android SDK. Add Flutter to PATH.
2. Accept Android licences and check your setup:

   ```sh
   flutter doctor --android-licenses
   flutter doctor
   ```

3. Start an Android emulator or connect an Android device with USB debugging enabled.
4. From the `shoply-flutter` directory, run:

   ```sh
   flutter pub get
   flutter devices
   flutter run -d <android-device-id>
   ```

To build a release APK, run `flutter build apk --release`. The output is `build/app/outputs/flutter-apk/app-release.apk`.

## State management

I chose **Provider with ChangeNotifier** because I used it in my previous project and found it stable and familiar. I previously tried GetX with Obx but encountered errors when reactive state was not configured correctly, so I preferred Provider for this project.

## AI assistance and my changes

AI generated the UI design, data models, and Shoply app icon used for the Android launcher and beside the catalogue title. I organised the file structure myself, following my previous project, and reused its API/core layer patterns. I adapted the generated code to these conventions and refined the product grid and search UI.

## Known weakness and improvements

The app does not yet have a cart or checkout flow. With more time, I would improve the UI and add cart features such as adding/removing items, updating quantities, and reviewing an order.
