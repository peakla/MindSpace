#!/usr/bin/env python3
"""
Convert translations.csv to individual JSON files per language.
Run this script whenever you update the CSV file.

Usage:
    python scripts/csv_to_json.py

This will read translations.csv and generate:
    - i18n/en.json
    - i18n/es.json
    - i18n/fr.json
    - i18n/zh.json
    - i18n/hi.json
    - i18n/ko.json
"""

import csv
import json
import os

def csv_to_json(csv_path='translations.csv', output_dir='i18n'):
    """Convert CSV file to individual JSON files per language."""
    
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Read CSV
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = list(reader)
    
    if not rows:
        print("Error: CSV file is empty")
        return
    
    # Get language columns (all columns except 'key')
    languages = [col for col in rows[0].keys() if col != 'key']
    print(f"Found languages: {languages}")
    
    # Build translation objects
    translations = {lang: {} for lang in languages}
    
    for row in rows:
        key = row['key']
        for lang in languages:
            value = row.get(lang, '')
            if value:  # Only include non-empty values
                translations[lang][key] = value
    
    # Write JSON files
    for lang, data in translations.items():
        output_path = os.path.join(output_dir, f'{lang}.json')
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"Generated {output_path} ({len(data)} keys)")
    
    print(f"\nDone! Generated {len(languages)} JSON files in '{output_dir}/'")

if __name__ == '__main__':
    csv_to_json()
