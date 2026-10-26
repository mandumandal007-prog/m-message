# M Message

Material 3 messaging app (Flutter + Firebase): email login, 1-to-1 and group chats, photos, files, voice notes, reactions, replies, edit/delete, 24-hour status updates, Jitsi voice/video calls and an AI assistant (DeepSeek / OpenAI, your own key).

## Download the APK

Every push to `main` builds a new APK with GitHub Actions and publishes it under **Releases**:

https://github.com/mandumandal007-prog/m-message/releases/latest

- `m-message.apk` - most phones (64-bit, arm64-v8a)
- `m-message-armeabi-v7a.apk` - older 32-bit phones

The APK is signed with a debug key, so Android may ask to allow "Install unknown apps" and Play Protect may warn - tap "Install anyway".

## Connect Firebase (required for login and chat)

The app needs your own Firebase project. Without it the app opens and shows a "Firebase is not connected yet" screen.

1. Open https://console.firebase.google.com and create (or open) a project.
2. Project settings > Your apps > **Add app > Android**, package name **`com.mmessage.app`**.
3. Download **`google-services.json`** and add it to this repo at **`android/app/google-services.json`** (GitHub: Add file > Upload files, inside `android/app`).
4. In the console enable **Authentication > Email/Password**, **Firestore Database** and **Storage**.
5. Paste `firestore.rules` and `storage.rules` from this repo into the Firestore and Storage rules tabs.

Pushing the file triggers a new build automatically; the next release APK will have working login and chat.

## Build locally

```
flutter pub get
flutter build apk --release --split-per-abi
```
(Flutter 3.32.x, Java 17.)
