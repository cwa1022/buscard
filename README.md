# buscard

This sample Flutter app demonstrates a simple business card scanner.
Users can capture a photo of a card and the app performs basic OCR to prefill
the name, company, phone, and email fields. Captured information and the image
path are stored locally using SQLite. The latest version recognizes both Latin
and Chinese text so Chinese business cards are supported out of the box.
When building for Android, make sure to include the Chinese text-recognition
model in `android/app/build.gradle`:

```gradle
dependencies {
    implementation 'com.google.mlkit:text-recognition-chinese:16.0.0'
}
```

## Features
- Capture an image using the device camera.
- Automatically recognize text on the card using ML Kit and pre-fill details.
- Improved heuristics detect phone numbers, emails, and likely name/company lines.
- Store name, company, phone, email, orientation, and photo path in SQLite.
- View saved cards in a list.

This code serves as a minimal starting point and is not production ready.
