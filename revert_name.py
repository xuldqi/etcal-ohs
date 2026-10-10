import os

target = "口算语音计算器"
replacement = "小鹿口算计算器"
extensions = ('.html', '.json', '.ets', '.ts', '.tsx', '.xml')
exclude_dirs = {'build', 'node_modules', '.ohpm', '.git', 'cache', 'intermediates'}

for root, dirs, files in os.walk('.'):
    dirs[:] = [d for d in dirs if d not in exclude_dirs]
    for file in files:
        if file.endswith(extensions):
            path = os.path.join(root, file)
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                if target in content:
                    new_content = content.replace(target, replacement)
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Updated: {path}")
            except Exception as e:
                pass
