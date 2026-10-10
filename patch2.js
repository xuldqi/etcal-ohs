const fs = require('fs');
const file = '../cal_duolingo/src/pages/DuolingoHome.tsx';
let content = fs.readFileSync(file, 'utf8');

if (!content.includes('import { LevelPath }')) {
  content = content.replace("import { Check, Flame, Heart, LockKeyhole, SkipForward } from 'lucide-react'", "import { Check, Flame, Heart, LockKeyhole, SkipForward } from 'lucide-react'\nimport { LevelPath } from '@/components/LevelPath'");
}

content = content.replace(
  '<div className="duo-level-grid">',
  '<div className="duo-level-grid">\n                            <LevelPath numLevels={skillLevels.length} />'
);

// also set z-index of duo-level-card so it sits on top of the path
content = content.replace(
  "className={[\n                                    'duo-level-card',",
  "style={{ zIndex: 1, position: 'relative' }}\n                                  className={[\n                                    'duo-level-card',"
);

fs.writeFileSync(file, content);
