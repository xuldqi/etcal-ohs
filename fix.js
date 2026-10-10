const fs = require('fs');
const file = '../cal_duolingo/src/pages/DuolingoHome.tsx';
let content = fs.readFileSync(file, 'utf8');

// Remove the injected ones
content = content.replace(/style=\{\{\n\s*zIndex: 1, position: 'relative',\s*zIndex: 1, position: 'relative' \}\}/g, '');
content = content.replace(/style=\{\{\n\s*zIndex: 1, position: 'relative',/g, 'style={{');

// Inject correctly into the actual style
content = content.replace(
  "                                  style={{",
  "                                  style={{\n                                    zIndex: 1, position: 'relative',"
);

fs.writeFileSync(file, content);
