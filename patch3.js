const fs = require('fs');
const file = '../cal_duolingo/src/pages/DuolingoHome.tsx';
let content = fs.readFileSync(file, 'utf8');

content = content.replace(
  'style={{',
  "style={{\n                                    zIndex: 1, position: 'relative',"
);

fs.writeFileSync(file, content);
