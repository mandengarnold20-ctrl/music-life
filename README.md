# Music Life — Étape 1

Plateforme chrétienne : louange, adoration, cultes en direct (OBS / vMix) et vie communautaire.
Flutter (Android + iOS) · Supabase · Bunny.net Stream ou Cloudflare Stream.

Cette étape contient :

1. `supabase/schema.sql` — le schéma complet (tables, clés étrangères, index de recherche, RLS, temps réel, recherche globale, stockage).
2. L'arborescence du projet Flutter (ci-dessous).
3. Le code des écrans **Lancement**, **Bienvenue**, **Accueil** et **TV Live** (bascule automatique direct / hors-ligne).

---

## 1. Mettre en place Supabase

1. Créez un projet sur supabase.com.
2. **SQL Editor › New query** : collez tout `supabase/schema.sql` puis **Run**. Le script peut être relancé sans erreur.
3. **Authentication › URL Configuration** : ajoutez `com.musiclife.app://login-callback` dans *Redirect URLs* (connexion par lien e-mail).
4. Connectez-vous une fois dans l'appli, puis donnez-vous le rôle admin :
   ```sql
   update public.app_users set role = 'admin'
   where id = (select id from auth.users where email = 'VOTRE_EMAIL');
   ```

### Passer à l'antenne depuis la régie
1. Dans Bunny.net / Cloudflare Stream, créez un *Live Input* : il vous donne une URL RTMP + clé (à mettre dans OBS ou vMix) et une URL de lecture **.m3u8**.
2. Collez le `.m3u8` dans `live_stream.hls_url` (une seule fois).
3. Au début du culte : `update live_stream set is_live = true;` → toutes les applis passent en direct **instantanément** (Realtime). En fin de culte : `is_live = false`.
4. Pour un vrai mode « économie de données », renseignez `audio_hls_url` avec un rendu audio seul si votre fournisseur le propose ; sinon l'appli lit le son du flux principal.

### Qui peut faire quoi (RLS)
| | Visiteur | Connecté | Modérateur | Admin |
|---|---|---|---|---|
| Lire vidéos, agenda, églises, bios | ✓ | ✓ | ✓ | ✓ |
| Écrire dans le chat (pendant un direct) | | ✓ | ✓ | ✓ |
| Retirer un message du chat | | | ✓ | ✓ |
| Publier / modifier le contenu, passer en direct | | | | ✓ |

Le nom affiché dans le chat est imposé par le serveur (impossible d'usurper un nom) et un utilisateur ne peut pas modifier son propre rôle.

---

## 2. Lancer l'appli Flutter

Prérequis : **Flutter 3.27 ou plus récent**.

```bash
# 1. Générer les dossiers natifs android/ et ios/ dans ce projet
flutter create . --org com.musiclife --project-name music_life --platforms android,ios

# 2. Dépendances
flutter pub get

# 3. Lancer (remplacez par vos clés : Supabase › Project Settings › API)
flutter run \
  --dart-define=SUPABASE_URL=https://VOTRE-PROJET.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=VOTRE_CLE_ANON
```

### Réglages natifs à ajouter après `flutter create`

**Android — `android/app/src/main/AndroidManifest.xml`**

Dans `<manifest>` :
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```
Sur la balise `<activity android:name=".MainActivity" …>` : remplacez `android:name=".MainActivity"` par
`android:name="com.ryanheise.audioservice.AudioServiceActivity"` (lecture écran verrouillé), puis ajoutez dans cette activité :
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="com.musiclife.app" android:host="login-callback"/>
</intent-filter>
```
Dans `<application>` :
```xml
<service android:name="com.ryanheise.audioservice.AudioService"
    android:foregroundServiceType="mediaPlayback" android:exported="true">
  <intent-filter><action android:name="android.media.browse.MediaBrowserService"/></intent-filter>
</service>
<receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver" android:exported="true">
  <intent-filter><action android:name="android.intent.action.MEDIA_BUTTON"/></intent-filter>
</receiver>
```

**iOS — `ios/Runner/Info.plist`**
```xml
<key>UIBackgroundModes</key>
<array><string>audio</string></array>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>com.musiclife.app</string></array>
  </dict>
</array>
```

---

## 3. Arborescence du projet (Feature-first)

Chaque fonctionnalité a ses couches **domain** (modèles), **data** (accès Supabase) et **presentation** (écrans, widgets, providers Riverpod).
✅ = livré dans cette étape · ⏳ = étapes suivantes.

```
music_life/
├── pubspec.yaml
├── analysis_options.yaml
├── supabase/
│   └── schema.sql                         ✅ schéma complet
└── lib/
    ├── main.dart                          ✅ init Supabase, audio arrière-plan, dates FR
    ├── app.dart                           ✅ thème + routes
    ├── core/
    │   ├── config/env.dart                ✅ clés via --dart-define
    │   ├── router/
    │   │   ├── app_routes.dart            ✅
    │   │   ├── app_shell.dart             ✅ barre 5 onglets
    │   │   └── tab_provider.dart          ✅ onglet courant
    │   ├── supabase/supabase_provider.dart ✅ client, session, rôle
    │   ├── theme/
    │   │   ├── app_colors.dart            ✅ palette violette + dégradés
    │   │   └── app_theme.dart             ✅ Poppins / Barlow Condensed
    │   ├── media/
    │   │   ├── hls_video_player.dart      ✅ video_player + chewie (HLS/MP4)
    │   │   └── audio_player_service.dart  ✅ just_audio + audio_service (écran verrouillé)
    │   └── widgets/
    │       ├── music_life_logo.dart       ✅ logo pinceau vectoriel
    │       ├── glow_background.dart       ✅ fond dégradé + lumières animées
    │       ├── live_badge.dart            ✅ badge EN DIRECT clignotant
    │       ├── chamfered_button.dart      ✅ bouton coin coupé
    │       └── section_header.dart        ✅
    └── features/
        ├── onboarding/                    ✅ lancement + bienvenue
        │   ├── data/onboarding_prefs.dart
        │   └── presentation/{splash_screen, welcome_screen}.dart
        ├── auth/                          ✅ connexion par lien e-mail
        │   └── presentation/sign_in_sheet.dart
        ├── home/                          ✅ Onglet 1 — Accueil
        │   ├── domain/{home_banner, daily_verse}.dart
        │   ├── data/home_repository.dart
        │   └── presentation/
        │       ├── home_screen.dart
        │       ├── home_providers.dart
        │       └── widgets/{hero_banner_carousel, media_carousel, verse_card}.dart
        ├── live_tv/                       ✅ Onglet 2 — TV Live
        │   ├── domain/{live_stream, chat_message}.dart
        │   ├── data/{live_stream_repository, chat_repository}.dart
        │   └── presentation/
        │       ├── live_tv_screen.dart
        │       ├── live_tv_providers.dart
        │       └── widgets/{offline_waiting_view, countdown, live_chat, audio_only_panel}.dart
        ├── library/                       Onglet 3 — Médiathèque
        │   ├── domain/vod_item.dart       ✅
        │   ├── presentation/vod_player_screen.dart ✅ lecture VOD
        │   ├── data/download_service.dart ⏳ téléchargement privé (vidéo ou MP3)
        │   └── presentation/{library_screen, downloads_screen}.dart ⏳
        ├── explore/                       Onglet 4 — Explorer
        │   ├── domain/event_item.dart     ✅
        │   ├── domain/{bio_profile, church}.dart ⏳
        │   ├── data/explore_repository.dart ⏳
        │   └── presentation/{bios, agenda, churches}_screen.dart ⏳
        └── search/                        ⏳ Onglet 5 — Recherche (RPC search_all prête)
```

---

## 4. Ce que fait l'écran TV Live

- **Direct actif** (`is_live = true`) : lecteur HLS en 16:9 avec plein écran paysage, badge EN DIRECT, interrupteur **Audio uniquement** (la vidéo est coupée, le son continue écran éteint avec les contrôles sur l'écran verrouillé), chat temps réel sous la vidéo.
- **Hors direct** : bannière d'attente (`offline_banner_url`), compte à rebours jusqu'à `next_program_at`, texte `next_program_info` et grille des prochains programmes (événements `is_live_tv = true`).
- La bascule est **automatique** dans les deux sens, sans recharger. Quand le direct s'arrête, l'audio en arrière-plan s'arrête aussi.
- La vidéo n'est chargée que lorsque l'onglet TV est affiché (économie de batterie et de données).
