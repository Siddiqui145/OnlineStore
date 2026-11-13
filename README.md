# PartsHub: Flutter web app (spare parts + service orders)

Customer app and admin dashboard on Flutter Web + Firebase (Auth, Firestore, Storage, Hosting).

## 1. Prerequisites
- Flutter SDK (stable) with web enabled: `flutter config --enable-web`
- Node.js 20+, then: `npm i -g firebase-tools`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`
  (make sure `~/.pub-cache/bin` is on your PATH)

## 2. Generate the web platform files (once)
Run inside this folder:
```
flutter create . --platforms web --project-name partshub
flutter pub get
```
`flutter create .` only adds the missing `web/` folder; it keeps the `lib/` code and `pubspec.yaml`.

## 3. Create the Firebase project and connect it
1. Go to https://console.firebase.google.com, click **Add project**.
2. **Build → Authentication → Get started → Sign-in method → Email/Password → Enable.**
3. **Build → Firestore Database → Create database** (production mode, pick a region near your users, e.g. `asia-south1`).
4. **Build → Storage → Get started** (production mode).
5. In the terminal:
```
firebase login
flutterfire configure
```
   Select your project and tick the **web** platform. This overwrites `lib/firebase_options.dart` with real keys.

## 4. Deploy security rules
```
firebase use --add            # pick your project, alias "default"
firebase deploy --only firestore:rules,firestore:indexes,storage
```
The first Storage deploy may ask you to grant Storage access to Firestore (needed so Storage rules can check the admin role). Say **yes**.

## 5. Make yourself the admin
Everyone signs up as `customer`. To promote your account:
1. Run the app and sign up with your admin email.
2. Firebase console → Firestore → `users` → your document → change field `role` from `customer` to `admin`.
3. Sign out and back in. You now see the admin dashboard.

The rules block users from changing their own role, so this can only be done from the console.

## 6. Run locally
```
flutter run -d chrome
```

## 7. Host on Firebase Hosting
```
flutter build web --release
firebase deploy --only hosting
```
Your app is live at `https://<project-id>.web.app`.

(Optional) If product images do not show on the hosted site, apply CORS to the bucket:
`gcloud storage buckets update gs://<your-bucket> --cors-file=cors.json`

## 8. Admin notifications by email (works on mobile too)
New orders and service requests are visible instantly in the dashboard (badge + pop-up while an admin is logged in). To also get an **email**, which lands as a push notification in your phone's mail app:
1. Upgrade the project to the **Blaze** plan (required for Cloud Functions and extensions; the free monthly quota covers small shops).
2. Console → **Extensions** → install **Trigger Email from Firestore**. Use collection `mail` and connect an SMTP provider (Gmail app password, SendGrid, etc.).
3. Deploy the included function:
```
cd functions && npm install && cd ..
firebase deploy --only functions
```
`functions/index.js` emails every user with `role == admin` when a document is created in `orders`.

## Data model
- `users/{uid}`: name, phone, email, role (`customer` | `admin`)
- `products/{id}`: name, category, description, price, quantity, imageUrl, createdAt
- `orders/{id}`: type (`spare_part` | `service`), userId, customerName, phone, email, address, items[], total, serviceType, preferredDate, notes, status (`new`, `contacted`, `in_progress`, `completed`, `cancelled`), createdAt, updatedAt
- Storage: `products/*` (images only, max 5 MB, admin write)

## Notes
- Currency is shown as ₹; change the `money()` helper in `lib/widgets.dart` to change it.
- Stock is not auto-reduced when an order is placed; admins adjust quantity in Products after confirming with the customer.
