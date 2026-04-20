# Shubhmilan Android release signing

Release builds use a Java keystore and `key.properties`. Debug builds keep using the debug keystore.

## What’s already configured

- `app/build.gradle.kts` loads `android/key.properties` when present and signs `release` with it; otherwise release falls back to the debug keystore (fine for local tests only — **not** for Play Store).
- Expected files (not committed to git):
  - `android/key.properties` — passwords and paths
  - `android/upload-keystore.jks` — the keystore file (or another name if you change `storeFile`)

## One-time: create a keystore

From the **`android/`** directory:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- **alias** must match `keyAlias` in `key.properties` (default: `upload`).
- Choose strong passwords; you can use the same value for keystore and key, or different — both go in `key.properties`.
- Back up `upload-keystore.jks` and passwords in a password manager. **Losing them means you cannot ship updates** under the same app signing key (unless you use Play App Signing and only lose the upload key — see Google Play docs).

## Configure `key.properties`

```bash
cp key.properties.example key.properties
# Edit key.properties with your real storePassword, keyPassword, and storeFile path.
```

## Verify release build

From the **project root** (`shubhmilan_frontend/`):

```bash
flutter build appbundle --release
```

The output is under `build/app/outputs/bundle/release/`. For an APK:

```bash
flutter build apk --release
```

## Google Play

- Prefer **Play App Signing**: Google holds the app signing key; you use an **upload key** (this keystore can be the upload certificate).
- In Play Console, register the upload certificate if required (PEM export from the keystore).

## CI/CD

- Store `key.properties` values and the keystore as **encrypted secrets** (e.g. GitHub Actions secrets + base64 decode to a file at build time).
- Never echo `key.properties` or keystore contents in CI logs.
