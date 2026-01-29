#!/usr/bin/env python3
"""
Translation Audit Script
Checks translations.csv for missing or empty translations and reports completeness per language.

Usage:
    python scripts/audit_translations.py
    python scripts/audit_translations.py --verbose    # Show all missing keys
    python scripts/audit_translations.py --threshold 95  # Fail if any language < 95% complete
"""

import csv
import sys
import os
import argparse
from collections import defaultdict

def audit_translations(csv_path='translations.csv', verbose=False, threshold=None):
    """Audit the translations CSV file for completeness."""
    
    if not os.path.exists(csv_path):
        print(f"Error: {csv_path} not found")
        return False
    
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        headers = reader.fieldnames
        
        if not headers or 'key' not in headers:
            print("Error: CSV must have a 'key' column")
            return False
        
        languages = [h for h in headers if h != 'key']
        
        stats = {lang: {'total': 0, 'filled': 0, 'missing': []} for lang in languages}
        duplicate_keys = []
        seen_keys = set()
        all_keys = []
        
        for row in reader:
            key = row.get('key', '').strip()
            if not key:
                continue
            
            all_keys.append(key)
            
            if key in seen_keys:
                duplicate_keys.append(key)
            seen_keys.add(key)
            
            for lang in languages:
                stats[lang]['total'] += 1
                value = row.get(lang, '').strip()
                if value:
                    stats[lang]['filled'] += 1
                else:
                    stats[lang]['missing'].append(key)
    
    print("\n" + "=" * 60)
    print("TRANSLATION AUDIT REPORT")
    print("=" * 60)
    
    print(f"\nTotal translation keys: {len(all_keys)}")
    print(f"Languages: {', '.join(languages)}")
    
    if duplicate_keys:
        print(f"\n⚠️  Duplicate keys found: {len(duplicate_keys)}")
        for key in duplicate_keys[:10]:
            print(f"   - {key}")
        if len(duplicate_keys) > 10:
            print(f"   ... and {len(duplicate_keys) - 10} more")
    
    print("\n" + "-" * 60)
    print("COMPLETENESS BY LANGUAGE")
    print("-" * 60)
    
    all_pass = True
    
    for lang in languages:
        total = stats[lang]['total']
        filled = stats[lang]['filled']
        missing_count = len(stats[lang]['missing'])
        percentage = (filled / total * 100) if total > 0 else 0
        
        status = "✅" if missing_count == 0 else "⚠️"
        if threshold and percentage < threshold:
            status = "❌"
            all_pass = False
        
        print(f"{status} {lang.upper():5} : {filled:4}/{total:4} ({percentage:5.1f}%) - {missing_count} missing")
        
        if verbose and stats[lang]['missing']:
            print(f"      Missing keys:")
            for key in stats[lang]['missing'][:20]:
                print(f"         - {key}")
            if len(stats[lang]['missing']) > 20:
                print(f"         ... and {len(stats[lang]['missing']) - 20} more")
    
    print("\n" + "-" * 60)
    
    if threshold:
        if all_pass:
            print(f"✅ All languages meet the {threshold}% threshold")
        else:
            print(f"❌ Some languages are below the {threshold}% threshold")
            return False
    
    total_missing = sum(len(stats[lang]['missing']) for lang in languages)
    if total_missing == 0:
        print("✅ All translations are complete!")
    else:
        print(f"📝 Total missing translations across all languages: {total_missing}")
        print("   Run with --verbose to see all missing keys")
    
    print()
    return all_pass and total_missing == 0


def main():
    parser = argparse.ArgumentParser(description='Audit translations for completeness')
    parser.add_argument('--verbose', '-v', action='store_true', 
                        help='Show all missing translation keys')
    parser.add_argument('--threshold', '-t', type=float, default=None,
                        help='Minimum percentage required (fails if any language is below)')
    parser.add_argument('--csv', default='translations.csv',
                        help='Path to translations CSV file')
    
    args = parser.parse_args()
    
    success = audit_translations(args.csv, args.verbose, args.threshold)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
