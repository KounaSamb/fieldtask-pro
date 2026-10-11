# FieldTask Pro - Flutter + SQLite + JSON-Server

## 1. Lancer le backend (JSON-Server)
Depuis le dossier `mock_api/` :
    npm install
    npm start
Verifier : http://localhost:3000/users et http://localhost:3000/interventions
Laissez ce terminal ouvert.

## 2. Lancer l'app
1. Remplacez `lib/`, `test/`, `pubspec.yaml` de votre projet par ceux de l'archive.
2. `flutter pub get`
3. `flutter run -d windows` ou emulateur Android. Pour Chrome, preparez d'abord SQLite web (une seule fois) :
       dart run sqflite_common_ffi_web:setup
   (cree web/sqflite_sw.js et web/sqlite3.wasm), puis `flutter run -d chrome`.
4. Connexion : karim@techfix.sn / 1234  (verifiee aupres de JSON-Server, il doit tourner)
5. Tests : `flutter test`

Adresse du serveur : `lib/core/config/api_config.dart`
- Windows : localhost (automatique) - Emulateur Android : 10.0.2.2 (automatique)
- Vrai telephone : mettre l'IP du PC dans `hostOverride` (meme Wi-Fi).

### Android : 2 reglages obligatoires (android/app/src/main/AndroidManifest.xml)
- avant `<application` : `<uses-permission android:name="android.permission.INTERNET"/>`
- aussi (GPS) : `<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>` et `ACCESS_COARSE_LOCATION`
- dans la balise `<application` : `android:usesCleartextTraffic="true"`

## 3. Tester le mode hors ligne (demo pour le jury)
1. App connectee, serveur lance. Changez le statut d'une mission : badge synchro OK, db.json modifie.
2. Coupez le serveur (Ctrl+C dans le terminal JSON-Server).
3. Changez le statut d'une autre mission : la modif reste dans SQLite (sync_queue).
4. Relancez `npm start` : en moins de 8 s l'app envoie la file, db.json est mis a jour.
(Sur telephone/emulateur, le mode avion declenche aussi la synchro via connectivity_plus.)

## Architecture
- core/ : config (URL API), couleurs, theme, connectivite, toast
- domain/entities/ : Intervention, InterventionStatus, User
- data/local/ : SQLite (database_helper, local_storage) - tables interventions, sync_queue, photos, signatures, session
- data/remote/ : remote_api (client REST JSON-Server)
- data/repositories/ : intervention_repository (local + file de synchro + pull serveur)
- presentation/ : blocs (Auth, Intervention, Sync), pages, widgets

## Strategie de synchro (pour le rapport)
- Ecriture : SQLite d'abord, puis ajout dans sync_queue, puis tentative d'envoi immediate.
- Envoi : la file est vidée dans l'ordre (PATCH /interventions/:id, POST /photos, POST /signatures) ; arret a la premiere erreur, reprise au prochain essai (retour reseau ou minuteur 8 s).
- Lecture : au demarrage / pull-to-refresh, GET /interventions ; une mission ayant une modif en attente n'est jamais ecrasee par le serveur.
- Signature : image PNG (base64) stockee dans SQLite (signatures.donnees) et envoyee a POST /signatures.
- Limite : JSON-Server n'accepte pas d'upload de fichier, les photos sont envoyees par chemin local.

## Carte
Carte reelle OpenStreetMap (flutter_map) + position GPS (geolocator). Les tuiles se chargent depuis Internet : hors ligne, les marqueurs restent visibles mais le fond de carte peut etre vide.

## Photos
Bouton « + » de la fiche : appareil photo ou galerie (image_picker). Les chemins sont stockes dans la table `photos` (SQLite) et envoyes via la file de synchro.
- Android : permission `android.permission.CAMERA` dans AndroidManifest.xml (conseille).
- iOS : `NSCameraUsageDescription` et `NSPhotoLibraryUsageDescription` dans Info.plist.
- Windows : pas d'appareil photo (galerie / explorateur de fichiers uniquement).
- Navigateur : selecteur de fichier ; les photos ne survivent pas a un rechargement de la page.

## Signature
Ecran de signature -> PNG (base64) enregistre dans la table `signatures`, apercu dans la fiche, envoi via la file de synchro.
Le bouton « Terminer l'intervention » reste grise tant que le client n'a pas signe.
Si vous aviez deja lance l'app : la base passe en version 2 automatiquement (colonne `donnees`).

## Notifications locales
- Un rappel est programme 30 min avant l'heure du RDV de chaque intervention non terminee ; il est annule si la mission est terminee.
- Cloche du tableau de bord : liste des rappels + boutons « Tester » (immediat) et « Rappel +1 min » (planification).
- Plateformes : Android, iOS, macOS. Pas de notification systeme sur Windows ni navigateur (la liste reste visible).
- Les RDV des donnees de test sont dans le passe : pour voir un rappel reel, mettez un `dateRdv` dans ~35 minutes dans `mock_api/db.json`.

### Reglages Android obligatoires (flutter_local_notifications)
1. `android/app/build.gradle(.kts)` :
   - dans `android { compileOptions { ... } }` ajouter `isCoreLibraryDesugaringEnabled = true` (Kotlin DSL) ou `coreLibraryDesugaringEnabled true` (Groovy)
   - dans `dependencies { }` ajouter `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` (Groovy : `coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'`)
2. `AndroidManifest.xml`, avant `<application` :
   `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`
   `<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>`
   `<uses-permission android:name="android.permission.VIBRATE"/>`
3. Dans `<application>` :
   `<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>`
   `<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"><intent-filter><action android:name="android.intent.action.BOOT_COMPLETED"/><action android:name="android.intent.action.MY_PACKAGE_REPLACED"/></intent-filter></receiver>`

## Profil
Page profil : bouton retour, « Modifier le profil » (nom, email, telephone ; role et matricule non modifiables).
La modification est ecrite dans SQLite (table session) puis envoyee a PATCH /users/:id via la file de synchro.
Si vous changez l'email, la connexion suivante se fait avec le nouvel email (mot de passe inchange).

## Validation d'une intervention
Le bouton « Terminer » exige : au moins une photo de l'intervention (preuve) ET la signature du client.
Une liste de controle s'affiche au-dessus du bouton et se coche au fur et a mesure.

## Suppression avant validation
Tant que l'intervention n'est pas terminee : une croix sur chaque photo permet de la supprimer (confirmation demandee),
et une corbeille permet de supprimer la signature. Le bouton « Terminer » se re-bloque alors tant que photo et signature manquent.
La suppression est aussi repercutee sur JSON-Server (file de synchro, action `delete`). Apres validation, preuves verrouillees.
