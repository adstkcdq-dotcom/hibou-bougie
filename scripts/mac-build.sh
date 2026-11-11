#!/bin/bash
# Fabrique l'app iPhone/iPad sur un Mac et l'envoie sur TestFlight.
# Prérequis : Xcode installé, clé API AuthKey_<ID>.p8 dans ~/Downloads.
# Usage : curl -fsSL https://raw.githubusercontent.com/adstkcdq-dotcom/hibou-bougie/main/scripts/mac-build.sh | bash
set -euo pipefail

KEY_ID="C488T228G7"
ISSUER_ID="e524c9f7-2c5f-4e06-a1d0-bb6b2026a575"
KEY="$HOME/Downloads/AuthKey_${KEY_ID}.p8"
BUILD_NUMBER="${BUILD_NUMBER:-100}"
W="$HOME/hibou-bougie-build"

say() { printf '\n\033[1;33m==> %s\033[0m\n' "$1"; }

say "1/6 Vérifications"
if [ ! -f "$KEY" ]; then
  echo "Clé introuvable : $KEY"
  echo "Le fichier AuthKey_${KEY_ID}.p8 doit être dans le dossier Téléchargements du Mac."
  exit 1
fi
if ! ls -d /Applications/Xcode*.app >/dev/null 2>&1; then
  echo "Xcode n'est pas installé. Installe-le depuis l'App Store du Mac, ouvre-le une fois, puis relance cette commande."
  exit 1
fi
XCODE="$(ls -d /Applications/Xcode*.app | sort -V | tail -1)"
export DEVELOPER_DIR="$XCODE/Contents/Developer"
if ! xcodebuild -version >/dev/null 2>&1; then
  echo "Il faut accepter la licence Xcode : tape le mot de passe du Mac si demandé (rien ne s'affiche, c'est normal)."
  sudo xcodebuild -license accept
fi
xcodebuild -runFirstLaunch >/dev/null 2>&1 || true
xcodebuild -version

say "2/6 Node.js (outil de préparation, installé dans $W)"
mkdir -p "$W"
if ! command -v node >/dev/null 2>&1; then
  V="v22.12.0"; ARCH="$(uname -m)"; [ "$ARCH" = "arm64" ] || ARCH="x64"
  ND="$W/node-$V-darwin-$ARCH"
  [ -d "$ND" ] || curl -fsSL "https://nodejs.org/dist/$V/node-$V-darwin-$ARCH.tar.gz" | tar -xz -C "$W"
  export PATH="$ND/bin:$PATH"
fi
node -v

say "3/6 Téléchargement du projet"
rm -rf "$W/src" && mkdir -p "$W/src"
curl -fsSL https://codeload.github.com/adstkcdq-dotcom/hibou-bougie/tar.gz/main | tar -xz -C "$W/src" --strip-components=1
cd "$W/src"

say "4/6 Préparation du jeu"
npm ci --no-audit --no-fund
export ADMOB_IOS_APP_ID="$(node -p "require('./admob.config.json').iosAppId||''")"
export ADMOB_IOS_REWARDED_ID="$(node -p "require('./admob.config.json').iosRewardedId||''")"
export TEAM_ID="$(node -p "require('./ios-config.json').teamId||''")"
export IOS_APP_ID="$(node -p "require('./ios-config.json').appStoreId||''")"
npm run build
npx cap sync ios
[ -n "$ADMOB_IOS_APP_ID" ] && /usr/libexec/PlistBuddy -c "Set :GADApplicationIdentifier $ADMOB_IOS_APP_ID" ios/App/App/Info.plist

say "5/6 Fabrication et signature (5 à 15 minutes)"
cd ios/App
AUTH=(-allowProvisioningUpdates -authenticationKeyPath "$KEY" -authenticationKeyID "$KEY_ID" -authenticationKeyIssuerID "$ISSUER_ID")
xcodebuild -project App.xcodeproj -scheme App -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$W/App.xcarchive" \
  DEVELOPMENT_TEAM="$TEAM_ID" CODE_SIGN_STYLE=Automatic \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" "${AUTH[@]}" archive | tail -25

say "6/6 Envoi sur App Store Connect"
cat > "$W/export.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>teamID</key><string>$TEAM_ID</string>
  <key>signingStyle</key><string>automatic</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict></plist>
PLIST
xcodebuild -exportArchive -archivePath "$W/App.xcarchive" \
  -exportOptionsPlist "$W/export.plist" -exportPath "$W/export" "${AUTH[@]}"

printf '\n\033[1;32m✅ C’EST ENVOYÉ ! L’app apparaîtra dans TestFlight dans 10 à 30 minutes.\033[0m\n\n'
