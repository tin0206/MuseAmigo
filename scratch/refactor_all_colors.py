import os
import glob
import re

color_map = {
    # Text/Icons (Dark/Medium greys)
    r'const\s+Color\(0xFF374151\)|Color\(0xFF374151\)': 'themeNotifier.textSecondaryColor',
    r'const\s+Color\(0xFF9CA3AF\)|Color\(0xFF9CA3AF\)': 'themeNotifier.textSecondaryColor',
    r'const\s+Color\(0xFF6D7785\)|Color\(0xFF6D7785\)': 'themeNotifier.textSecondaryColor',
    r'const\s+Color\(0xFFAAAAAA\)|Color\(0xFFAAAAAA\)': 'themeNotifier.textSecondaryColor',
    r'const\s+Color\(0xFF8A93A3\)|Color\(0xFF8A93A3\)': 'themeNotifier.textSecondaryColor',
    r'const\s+Color\(0xFF4D5562\)|Color\(0xFF4D5562\)': 'themeNotifier.textSecondaryColor',
    r'const\s+Color\(0xFF8C93A1\)|Color\(0xFF8C93A1\)': 'themeNotifier.textSecondaryColor',
    r'const\s+Color\(0xFFB4BAC5\)|Color\(0xFFB4BAC5\)': 'themeNotifier.textSecondaryColor',
    r'const\s+Color\(0xFF2F343C\)|Color\(0xFF2F343C\)': 'themeNotifier.textPrimaryColor',
    r'const\s+Color\(0xFF111827\)|Color\(0xFF111827\)': 'themeNotifier.textPrimaryColor',
    
    # Backgrounds/Borders (Light greys/Whites)
    r'const\s+Color\(0xFFDDDDDD\)|Color\(0xFFDDDDDD\)': 'themeNotifier.borderColor',
    r'const\s+Color\(0xFFF3F3F4\)|Color\(0xFFF3F3F4\)': 'themeNotifier.surfaceColor',
    r'const\s+Color\(0xFFF5F5F5\)|Color\(0xFFF5F5F5\)': 'themeNotifier.surfaceColor',
    r'const\s+Color\(0xFFF9FAFB\)|Color\(0xFFF9FAFB\)': 'themeNotifier.backgroundColor',
    r'const\s+Color\(0xFFE3E3E5\)|Color\(0xFFE3E3E5\)': 'themeNotifier.surfaceColor',
    r'const\s+Color\(0xFFE5E5E7\)|Color\(0xFFE5E5E7\)': 'themeNotifier.borderColor',
    r'const\s+Color\(0xFFD6D8DD\)|Color\(0xFFD6D8DD\)': 'themeNotifier.borderColor',
    r'const\s+Color\(0xFFD8DADE\)|Color\(0xFFD8DADE\)': 'themeNotifier.borderColor',
    r'const\s+Color\(0xFFD9DCE2\)|Color\(0xFFD9DCE2\)': 'themeNotifier.borderColor',
    r'const\s+Color\(0xFFEFF1F4\)|Color\(0xFFEFF1F4\)': 'themeNotifier.surfaceColor',
    r'const\s+Color\(0xFFD1D5DB\)|Color\(0xFFD1D5DB\)': 'themeNotifier.borderColor',
    r'const\s+Color\(0xFFEFF6FF\)|Color\(0xFFEFF6FF\)': 'themeNotifier.backgroundColor',
    r'const\s+Color\(0xFFBFDBFE\)|Color\(0xFFBFDBFE\)': 'themeNotifier.borderColor',

    # Specific colors in settings/payments
    r'const\s+Color\(0xFFEFCDD0\)|Color\(0xFFEFCDD0\)': 'themeNotifier.borderColor',
    r'const\s+Color\(0xFFFFF5F5\)|Color\(0xFFFFF5F5\)': 'themeNotifier.surfaceColor',
    r'const\s+Color\(0xFFFFF8E1\)|Color\(0xFFFFF8E1\)': 'themeNotifier.surfaceColor',
    r'const\s+Color\(0xFFFFCC02\)|Color\(0xFFFFCC02\)': 'Theme.of(context).colorScheme.primary',
    r'const\s+Color\(0xFFE65100\)|Color\(0xFFE65100\)': 'Theme.of(context).colorScheme.primary',
}

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    orig_content = content
    for pattern, replacement in color_map.items():
        # Do not replace inside const quickPicks = [ ... ]
        # We will split by `const quickPicks = [` and only process the rest
        if 'quickPicks' in content and filepath.endswith('settings_screen.dart'):
            parts = content.split('const quickPicks = [')
            if len(parts) == 2:
                subparts = parts[1].split('];', 1)
                if len(subparts) == 2:
                    before = parts[0]
                    inside_array = subparts[0]
                    after = subparts[1]
                    # Only replace in before and after
                    before = re.sub(pattern, replacement, before)
                    after = re.sub(pattern, replacement, after)
                    content = before + 'const quickPicks = [' + inside_array + '];' + after
                else:
                    content = re.sub(pattern, replacement, content)
            else:
                content = re.sub(pattern, replacement, content)
        else:
            content = re.sub(pattern, replacement, content)

    if content != orig_content:
        if 'themeNotifier' in content and 'package:museamigo/theme_notifier.dart' not in content:
            imports = re.findall(r"^import\s+['\"].*?['\"];", content, re.MULTILINE)
            if imports:
                last_import = imports[-1]
                content = content.replace(last_import, last_import + "\nimport 'package:museamigo/theme_notifier.dart';")
            else:
                content = "import 'package:museamigo/theme_notifier.dart';\n" + content
                
        # Fix const issues
        content = re.sub(r'const\s+(TextStyle|BoxDecoration|BorderSide|Border|EdgeInsets|ColorFilter)', r'\1', content)
        content = re.sub(r'const\s+(Icon|Text|Padding|Container|SizedBox|Column|Row|Center|Expanded|Stack|Positioned)', r'\1', content)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

for f in glob.glob('lib/**/*.dart', recursive=True):
    if f.endswith('theme_notifier.dart') or f.endswith('main.dart'):
        continue
    process_file(f)
