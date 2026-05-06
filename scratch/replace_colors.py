import os
import glob
import re

for f in glob.glob('lib/**/*.dart', recursive=True):
    if f.endswith('main.dart') or f.endswith('theme_notifier.dart'):
        continue
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    original_content = content

    content = re.sub(r'const\s+Color\(0xFFF3F4F6\)|Color\(0xFFF3F4F6\)', r'themeNotifier.backgroundColor', content)
    content = re.sub(r'Colors\.white', r'themeNotifier.surfaceColor', content)
    content = re.sub(r'const\s+Color\(0xFF171A21\)|Color\(0xFF171A21\)', r'themeNotifier.textPrimaryColor', content)
    content = re.sub(r'const\s+Color\(0xFF6B7280\)|Color\(0xFF6B7280\)', r'themeNotifier.textSecondaryColor', content)
    content = re.sub(r'const\s+Color\(0xFFE5E7EB\)|Color\(0xFFE5E7EB\)', r'themeNotifier.borderColor', content)
    content = re.sub(r'const\s+Color\(0xFF1D4ED8\)|Color\(0xFF1D4ED8\)', r'themeNotifier.textPrimaryColor', content)

    if content != original_content:
        if 'package:museamigo/theme_notifier.dart' not in content:
            imports = re.findall(r"^import\s+['\"].*?['\"];", content, re.MULTILINE)
            if imports:
                last_import = imports[-1]
                content = content.replace(last_import, last_import + "\nimport 'package:museamigo/theme_notifier.dart';")
            else:
                content = "import 'package:museamigo/theme_notifier.dart';\n" + content
        
        content = re.sub(r'const\s+(TextStyle|BoxDecoration|BorderSide|Border|EdgeInsets)', r'\1', content)
        content = re.sub(r'const\s+(Icon|Text|Padding|Container|SizedBox|Column|Row|Center|Expanded|Stack|Positioned)', r'\1', content)
        
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)
