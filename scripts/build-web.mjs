// Construit www/ (le contenu de l'app) à partir de game.html, la même source que le prototype en ligne.
import { readFileSync, writeFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const www = join(root, 'www');
rmSync(www, { recursive: true, force: true });
mkdirSync(join(www, 'fonts'), { recursive: true });

// Polices embarquées : le jeu fonctionne sans internet.
const fonts = [
  ['Fredoka', 500, '@fontsource/fredoka/files/fredoka-latin-500-normal.woff2'],
  ['Fredoka', 600, '@fontsource/fredoka/files/fredoka-latin-600-normal.woff2'],
  ['Fredoka', 700, '@fontsource/fredoka/files/fredoka-latin-700-normal.woff2'],
  ['Nunito', 400, '@fontsource/nunito/files/nunito-latin-400-normal.woff2'],
  ['Nunito', 600, '@fontsource/nunito/files/nunito-latin-600-normal.woff2'],
  ['Nunito', 800, '@fontsource/nunito/files/nunito-latin-800-normal.woff2'],
];
let fontCss = '';
for (const [family, weight, src] of fonts) {
  const file = src.split('/').pop();
  copyFileSync(join(root, 'node_modules', src), join(www, 'fonts', file));
  fontCss += `@font-face{font-family:"${family}";font-weight:${weight};font-style:normal;font-display:swap;src:url(fonts/${file}) format("woff2")}\n`;
}

let game = readFileSync(join(root, 'game.html'), 'utf8');
// Vrai identifiant de pub avec récompense (fourni par GitHub) ; sinon, pubs de test.
if (process.env.ADMOB_REWARDED_ID) {
  game = game.replace(/const AD_CFG=\{[^}]*\};/, `const AD_CFG={rewarded:'${process.env.ADMOB_REWARDED_ID}',testing:false};`);
  console.log('Pubs réelles activées');
} else console.log('Pubs de TEST');
game = game.replace(/<link rel="stylesheet" href="https:\/\/fonts\.googleapis\.com[^>]*>\n?/, '');
game = game.replace(/<meta name="claude:viewport-fit-sides"[^>]*>\n?/, '');
const title = (game.match(/<title>[\s\S]*?<\/title>/) || ['<title>Hibou &amp; Bougie</title>'])[0];
game = game.replace(title, '');

const html = `<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover, user-scalable=no">
<meta name="theme-color" content="#141a33">
${title}
<style>
${fontCss}*,*::before,*::after{box-sizing:border-box}
:root{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}
body{margin:0;font:14px system-ui,-apple-system,sans-serif;-webkit-user-select:none;user-select:none;overscroll-behavior:none}
input,textarea{-webkit-user-select:text;user-select:text}
img{max-width:100%}
[hidden]{display:none!important}
</style>
</head>
<body>
${game}
</body>
</html>
`;
writeFileSync(join(www, 'index.html'), html);
console.log('www/index.html prêt');
