const fs = require('fs');
const path = require('path');

function replaceInFile(filePath) {
    if (!fs.existsSync(filePath)) return;
    let content = fs.readFileSync(filePath, 'utf8');
    const legacyChildrenName = '\u513f\u7ae5\u8bed\u97f3\u8ba1\u7b97\u5668';
    const legacyFeatureName = '\u8bed\u97f3\u8ba1\u7b97\u5668';
    if (content.includes(legacyChildrenName) || content.includes(legacyFeatureName)) {
        content = content
            .replace(new RegExp(legacyChildrenName, 'g'), '趣算宝')
            .replace(new RegExp(legacyFeatureName, 'g'), '趣算宝');
        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`Updated ${filePath}`);
    }
}

function walkDir(dir) {
    if (!fs.existsSync(dir)) return;
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            walkDir(fullPath);
        } else {
            if (fullPath.endsWith('.html') || fullPath.endsWith('.ets') || fullPath.endsWith('.ts') || fullPath.endsWith('.js') || fullPath.endsWith('.tsx') || fullPath.endsWith('.json') || fullPath.endsWith('.json5') || fullPath.endsWith('.md') || fullPath.endsWith('.xml')) {
                replaceInFile(fullPath);
            }
        }
    }
}

walkDir('/Users/macmima1234/Documents/harmony/chmath/react/react-src');
walkDir('/Users/macmima1234/Documents/harmony/chmath/chmath_new/chamath_harmony/entry/src');
replaceInFile('/Users/macmima1234/Documents/harmony/chmath/chmath_new/chamath_harmony/tstocal-harmony-privacy_policy.html');
replaceInFile('/Users/macmima1234/Documents/harmony/chmath/chmath_new/chamath_harmony/privacy-policy.html');
