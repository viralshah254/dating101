# Backend — Firebase Service Account & Environment Setup

**Purpose:** Configure Firebase Admin SDK credentials for the backend. These are **backend-only** — never expose service account keys to the frontend.

---

## Frontend vs backend

| Component | Where | Credentials |
|-----------|-------|-------------|
| **Flutter app (frontend)** | This repo | `GoogleService-Info.plist` (iOS), `google-services.json` (Android), `firebase_options.dart` — client config for Firebase SDK. Already set up. |
| **Backend server** | Your API server | `FIREBASE_SERVICE_ACCOUNT_JSON` or `GOOGLE_APPLICATION_CREDENTIALS` — for Firebase Admin SDK to **send** push notifications, etc. |

The frontend uses Firebase client SDK (Auth, Messaging, Storage). The backend uses **Firebase Admin SDK** to send push notifications, verify tokens, etc. Admin SDK requires a **service account** with private key — this must stay on the server only.

---

## Backend environment variables

Add these to your backend `.env` (or deployment config):

### Option A: JSON string (recommended for PaaS / Docker)

```env
# Firebase Admin SDK — full JSON as a single-line string (escape quotes if needed)
FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account","project_id":"saathi-2644b","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"firebase-adminsdk-xxxxx@saathi-2644b.iam.gserviceaccount.com","client_id":"...","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"..."}'
```

### Option B: File path (traditional)

```env
# Path to the service account JSON file on disk
GOOGLE_APPLICATION_CREDENTIALS=/path/to/saathi-firebase-adminsdk.json
```

---

## How to get the service account JSON

1. Open [Firebase Console](https://console.firebase.google.com/) → select project **saathi-2644b** (or your project).
2. Go to **Project settings** (gear icon) → **Service accounts**.
3. Click **Generate new private key**.
4. Save the downloaded JSON file. **Never commit it to git.**
5. For **Option A**: Copy the entire JSON as a single line, escape internal quotes, and set `FIREBASE_SERVICE_ACCOUNT_JSON`.
6. For **Option B**: Place the file on the server and set `GOOGLE_APPLICATION_CREDENTIALS` to its path.

---

## Backend usage (Node.js example)

```javascript
// Option A: from env string
const admin = require('firebase-admin');
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

// Option B: from file (uses GOOGLE_APPLICATION_CREDENTIALS automatically)
admin.initializeApp();
```

---

## .env.example for backend

Create a `.env.example` in your backend repo and add:

```env
# API
API_PORT=3000
API_URL=https://api.yourdomain.com

# Database
DATABASE_URL=postgresql://...

# Firebase Admin SDK (for push notifications)
# Use ONE of these:
FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
# OR
GOOGLE_APPLICATION_CREDENTIALS=./saathi-firebase-adminsdk.json

# Other
JWT_SECRET=...
```

Copy to `.env` and fill in real values. Add `.env` to `.gitignore`.

---

## Security checklist

- [ ] Never commit `FIREBASE_SERVICE_ACCOUNT_JSON` or the JSON file to git
- [ ] Add `.env` and `*-firebase-adminsdk*.json` to `.gitignore`
- [ ] Use secrets manager (e.g. AWS Secrets Manager, GCP Secret Manager) in production
- [ ] Restrict service account permissions in Firebase Console (e.g. only Cloud Messaging if that's all you need)

---

## Related docs

- [BACKEND_PUSH_NOTIFICATIONS.md](./BACKEND_PUSH_NOTIFICATIONS.md) — when and how to send push via Firebase Admin SDK
