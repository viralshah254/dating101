# Android release signing (Play Store)

To upload an **App Bundle** to Google Play, you must sign it in **release** mode (not debug).

## 1. Create a keystore (one-time)

From your machine, run (replace passwords and alias if you prefer):

```bash
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- Use a **strong store password** and **key password**; you’ll need them for every release.
- **Back up** the `.jks` file and passwords securely. If you lose them, you cannot update the app on Play Store with the same key.

The keystore is already in `.gitignore` — do **not** commit it.

## 2. Create `android/key.properties`

Copy the example and fill in your values:

```bash
cp android/key.properties.example android/key.properties
```

Edit `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

If the keystore is in another location, set `storeFile` to a path **relative to the `android/` folder**, e.g. `../keys/upload-keystore.jks`.

`key.properties` is gitignored — do **not** commit it.

## 3. Build the release App Bundle

From the project root:

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Upload **this file** to Play Console (App bundle explorer or a new release). It will be signed with your release key.

## 4. If you don’t set up signing

If `key.properties` (and optionally the keystore) is missing, the release build falls back to **debug** signing so `flutter build appbundle --release` still runs. That bundle is **not** accepted by Play Store — you’ll see “signed in debug mode”. Complete steps 1–2 to fix it.
