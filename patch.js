const fs = require('fs');
const file = '../cal_duolingo/src/pages/DuolingoHome.tsx';
let content = fs.readFileSync(file, 'utf8');

// Replace page title
content = content.replace('<h1 className="duo-page-title">学习</h1>', '<h1 className="duo-page-title">冒险</h1>');

// Change level pattern from 3-step to 4-step sine wave
content = content.replace(
  'const levelColumn = logicalIndex % 3 === 0 ? 2 : logicalIndex % 3 === 1 ? 1 : 3',
  'const mod = logicalIndex % 4;\n                              const levelColumn = (mod === 0 || mod === 2) ? 2 : (mod === 1) ? 1 : 3;'
);
content = content.replace(
  "const levelX = logicalIndex % 3 === 1 ? '15px' : logicalIndex % 3 === 2 ? '-15px' : '0px'",
  "const levelX = (mod === 1) ? '15px' : (mod === 3) ? '-15px' : '0px'"
);
content = content.replace(
  "const levelY = logicalIndex % 3 === 0 ? '0px' : logicalIndex % 3 === 1 ? '9px' : '22px'",
  "const levelY = (mod === 0) ? '0px' : (mod === 1 || mod === 3) ? '12px' : '24px'"
);

fs.writeFileSync(file, content);
