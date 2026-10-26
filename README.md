# M Message

Material 3 messaging app (Flutter + Firebase): email login, 1-to-1 and group chats, photos, files, voice notes, reactions, replies, edit/delete, 24-hour status updates, Jitsi voice/video calls and an AI assistant (DeepSeek / OpenAI, your own key).

## Download the APK

Every push to `main` builds a new APK with GitHub Actions and publishes it under **Releases**:

https://github.com/mandumandal007-prog/m-message/releases/latest

- `m-message.apk` - most phones (64-bit, arm64-v8a)
- `m-message-armeabi-v7a.apk` - older 32-bit phones

The APK is signed with a debug key, so Android may ask to allow "Install unknown apps" and Play Protect may warn - tap "Install anyway".

## Firebase setup

`android/app/google-services.json` (project `m-message-8f022`, package `com.mmessage.app`) is in the repo. In the Firebase console of that project:

1. **Authentication > Sign-in method > Email/Password** - enable it (the app signs up / logs in with email + password).
2. **Firestore Database > Create database** (production mode), then paste `firestore.rules` from this repo into the **Rules** tab and Publish.
3. **Storage > Get started** (needed for photos, voice notes, files, status photos and profile pictures; new projects need the pay-as-you-go Blaze plan for Storage, the free quota still applies), then paste `storage.rules` into its **Rules** tab and Publish.

Text chats work with steps 1-2; media needs step 3. If google-services.json is removed, the app still opens and shows a "Firebase is not connected yet" screen.

## Build locally

```
flutter pub get
flutter build apk --release --split-per-abi
```
(Flutter 3.32.x, Java 17.)
