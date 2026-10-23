# Hibou & Bougie

Jeu incrémental de concentration pour Android.

- `game.html` : le jeu (même source que le prototype en ligne).
- `scripts/build-web.mjs` : prépare `www/` (polices incluses, pubs réelles si `ADMOB_REWARDED_ID` est fourni).
- `android/` : projet Android (Capacitor 8, cible Android 16 / API 36).
- `.github/workflows/android.yml` : fabrique le `.aab` signé dans le cloud.

## Fabriquer l'app
Onglet **Actions** → « Fabriquer l'app Android » → **Run workflow**. Le fichier `.aab` se télécharge en bas de la page du résultat.

## Mise à jour
1. Modifier le jeu.
2. Augmenter `versionCode` (et `versionName`) dans `android/app/build.gradle`.
3. Laisser GitHub fabriquer le nouveau `.aab`, puis l'envoyer dans la Play Console.

## Secrets GitHub nécessaires
`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`, `ADMOB_APP_ID`, `ADMOB_REWARDED_ID`.
