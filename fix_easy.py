import re
import os
import glob

# 1. Fix withOpacity multiline
files = glob.glob('lib/screens/*.dart') + glob.glob('lib/widgets/*.dart')
for fpath in files:
    with open(fpath, 'r') as f:
        content = f.read()
    
    # replace .withOpacity( \n value \n )
    # regex to match .withOpacity(anything)
    new_content = re.sub(r'\.withOpacity\s*\(\s*([^)]+)\s*\)', r'.withValues(alpha: \1)', content)
    
    if new_content != content:
        with open(fpath, 'w') as f:
            f.write(new_content)

# 2. Fix fetch_demo_assets.dart braces
fetch_path = 'scripts/fetch_demo_assets.dart'
if os.path.exists(fetch_path):
    with open(fetch_path, 'r') as f:
        content = f.read()
    content = re.sub(r'if \((.*?)\) continue;', r'if (\1) {\n      continue;\n    }', content)
    with open(fetch_path, 'w') as f:
        f.write(content)

# 3. Add ignore for unnecessary_this in catalog_screen.dart
cat_path = 'lib/screens/catalog_screen.dart'
if os.path.exists(cat_path):
    with open(cat_path, 'r') as f:
        content = f.read()
    content = content.replace('// ignore: use_build_context_synchronously', '// ignore: use_build_context_synchronously, unnecessary_this')
    with open(cat_path, 'w') as f:
        f.write(content)

print("Done")
