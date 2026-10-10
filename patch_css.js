const fs = require('fs');
const file = '../cal_duolingo/src/styles/duolingo-page.css';
let content = fs.readFileSync(file, 'utf8');

// Replace opacity
content = content.replace(
  /\.duo-level-card\.is-locked \{\s*opacity: 0\.52;\s*\}/,
  '.duo-level-card.is-locked {\n  /* no opacity so line doesnt show through */\n}'
);

// Replace locked colors to standard gray
content = content.replace(
  /\.duo-level-card\.is-locked \.duo-level-orb \{\s*color: #76a79e;\s*background: #c8d9d5;\s*--level-shadow: #a9bfba !important;\s*\}/,
  '.duo-level-card.is-locked .duo-level-orb {\n  color: #afafaf;\n  background: #e5e5e5;\n  --level-shadow: #c9c9c9 !important;\n}'
);

fs.writeFileSync(file, content);
