#!/usr/bin/env python3
"""
Extract translations from js/translations.js and convert to CSV format.
This is a one-time migration script.
"""

import re
import csv
import json

def extract_translations_from_js(js_file_path):
    """Parse the translations.js file and extract all translation objects."""
    with open(js_file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find the translations object
    # Match pattern: lang_code: { ... }
    languages = ['en', 'es', 'fr', 'zh', 'hi', 'ko']
    translations = {}
    
    for lang in languages:
        # Find the language block
        pattern = rf'^\s*{lang}:\s*\{{'
        matches = list(re.finditer(pattern, content, re.MULTILINE))
        
        if not matches:
            print(f"Warning: Could not find language block for '{lang}'")
            continue
        
        start_pos = matches[0].end() - 1  # Start at the opening brace
        
        # Find matching closing brace
        brace_count = 0
        end_pos = start_pos
        for i, char in enumerate(content[start_pos:]):
            if char == '{':
                brace_count += 1
            elif char == '}':
                brace_count -= 1
                if brace_count == 0:
                    end_pos = start_pos + i + 1
                    break
        
        lang_block = content[start_pos:end_pos]
        
        # Parse key-value pairs
        translations[lang] = {}
        
        # Match: key: "value" or key: 'value'
        kv_pattern = r'^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:\s*(["\'])((?:(?!\2)[^\\]|\\.)*)\2'
        
        for match in re.finditer(kv_pattern, lang_block, re.MULTILINE):
            key = match.group(1)
            value = match.group(3)
            # Unescape quotes
            value = value.replace("\\'", "'").replace('\\"', '"')
            translations[lang][key] = value
        
        print(f"Extracted {len(translations[lang])} keys for '{lang}'")
    
    return translations

def create_csv(translations, output_path):
    """Create CSV file with all translations."""
    languages = ['en', 'es', 'fr', 'zh', 'hi', 'ko']
    
    # Get all unique keys from all languages
    all_keys = set()
    for lang in languages:
        if lang in translations:
            all_keys.update(translations[lang].keys())
    
    # Sort keys for consistent ordering
    all_keys = sorted(all_keys)
    
    print(f"Total unique keys: {len(all_keys)}")
    
    # Write CSV
    with open(output_path, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        
        # Header row
        writer.writerow(['key'] + languages)
        
        # Data rows
        for key in all_keys:
            row = [key]
            for lang in languages:
                value = translations.get(lang, {}).get(key, '')
                row.append(value)
            writer.writerow(row)
    
    print(f"CSV written to {output_path}")

def create_json_files(translations, output_dir):
    """Create individual JSON files per language."""
    import os
    os.makedirs(output_dir, exist_ok=True)
    
    for lang, data in translations.items():
        output_path = os.path.join(output_dir, f'{lang}.json')
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"JSON written to {output_path}")

if __name__ == '__main__':
    js_file = 'js/translations.js'
    csv_output = 'translations.csv'
    json_output_dir = 'i18n'
    
    print("Extracting translations from JS...")
    translations = extract_translations_from_js(js_file)
    
    print("\nCreating CSV master file...")
    create_csv(translations, csv_output)
    
    print("\nCreating JSON files...")
    create_json_files(translations, json_output_dir)
    
    print("\nDone!")
