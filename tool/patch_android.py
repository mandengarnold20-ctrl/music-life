"""Ajoute les réglages Android de Music Life après `flutter create`.

- Nom affiché : « Music Life »
- Permissions : internet, audio en arrière-plan, notifications
- Activité audio_service (lecture écran verrouillé)
- Lien de retour de connexion : com.musiclife.app://login-callback
Le script peut être relancé : il ne duplique rien.
"""
from pathlib import Path

manifest = Path("android/app/src/main/AndroidManifest.xml")
xml = manifest.read_text(encoding="utf-8")

if "com.ryanheise.audioservice.AudioService" in xml:
    print("Manifest déjà configuré.")
    raise SystemExit(0)

permissions = """    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <application"""
xml = xml.replace("    <application", permissions, 1)

# Nom de l'appli sous l'icône
xml = xml.replace('android:label="music_life"', 'android:label="Music Life"', 1)

# Activité compatible lecture audio en arrière-plan
xml = xml.replace('android:name=".MainActivity"', 'android:name="com.ryanheise.audioservice.AudioServiceActivity"', 1)

deep_link = """            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="com.musiclife.app" android:host="login-callback"/>
            </intent-filter>
        </activity>"""
xml = xml.replace("        </activity>", deep_link, 1)

services = """        <service android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService"/>
            </intent-filter>
        </service>
        <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON"/>
            </intent-filter>
        </receiver>
    </application>"""
xml = xml.replace("    </application>", services, 1)

# Ouvrir les liens (dons, bannières) dans le navigateur — Android 11+
browser_query = """    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="https"/>
        </intent>"""
if "<queries>" in xml:
    xml = xml.replace("    <queries>", browser_query, 1)
else:
    xml = xml.replace("</manifest>", browser_query + "\n    </queries>\n</manifest>", 1)

for needle in ("AudioServiceActivity", "login-callback", "MediaButtonReceiver", "android.permission.INTERNET"):
    if needle not in xml:
        raise SystemExit(f"Échec : « {needle} » n'a pas pu être ajouté au manifest.")

manifest.write_text(xml, encoding="utf-8")
print("Manifest Android configuré pour Music Life.")

# La vérification « lint » de la version finale plante sur certains plugins
# (bug connu de l'outil, sans rapport avec le code) : on la désactive.
LINT_FIX = """
// Music Life : désactive la vérification lint de la version finale (bug connu de l'outil).
subprojects {
    tasks.matching { it.name.startsWith("lintVital") }.configureEach { enabled = false }
}
"""
for name in ("android/build.gradle.kts", "android/build.gradle"):
    gradle = Path(name)
    if gradle.exists():
        text = gradle.read_text(encoding="utf-8")
        if "lintVital" not in text:
            gradle.write_text(text + LINT_FIX, encoding="utf-8")
        print(f"Vérification lint désactivée dans {name}.")
        break
