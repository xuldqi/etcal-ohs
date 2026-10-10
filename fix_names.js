const fs = require('fs');
const path = require('path');

function replaceInFile(filePath) {
    if (!fs.existsSync(filePath)) return;
    let content = fs.readFileSync(filePath, 'utf8');
    
    const targets = [
        '趣算宝',
        '小鹿儿童口算计算器',
        '儿童数学计算器',
        '儿童语音计算器',
        '语音计算器'
    ];
    
    let modified = false;
    for (const t of targets) {
        if (content.includes(t)) {
            content = content.replace(new RegExp(t, 'g'), '小鹿口算计算器');
            modified = true;
        }
    }
    
    if (modified) {
        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`Updated ${filePath}`);
    }
}

function walkDir(dir) {
    if (!fs.existsSync(dir)) return;
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (file === 'node_modules' || file === '.git' || file === 'build' || file === 'dist' || file === '.preview' || file === 'cache') {
            continue;
        }
        if (fs.statSync(fullPath).isDirectory()) {
            walkDir(fullPath);
        } else {
            if (fullPath.match(/\.(html|ets|ts|js|tsx|json|json5|md|xml|sh)$/)) {
                replaceInFile(fullPath);
            }
        }
    }
}

walkDir('/Users/macmima1234/Documents/harmony/chmath/react/react-src');
walkDir('/Users/macmima1234/Documents/harmony/chmath/chmath_new/chamath_harmony/entry');
walkDir('/Users/macmima1234/Documents/harmony/chmath/chmath_new/chamath_harmony/AppScope');
replaceInFile('/Users/macmima1234/Documents/harmony/chmath/chmath_new/chamath_harmony/tstocal-harmony-privacy_policy.html');
replaceInFile('/Users/macmima1234/Documents/harmony/chmath/chmath_new/chamath_harmony/privacy-policy.html');
replaceInFile('/Users/macmima1234/Documents/harmony/chmath/chmath_new/chamath_harmony/install.sh');
replaceInFile('/Users/macmima1234/Documents/harmony/chmath/chmath_new/chamath_harmony/build-and-install.sh');
