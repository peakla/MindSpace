#!/usr/bin/env python3
"""
HTML Markup Audit Script
Scans HTML files for text content that might need translation attributes.

Usage:
    python scripts/audit_markup.py
    python scripts/audit_markup.py --verbose    # Show all findings
    python scripts/audit_markup.py --dir ./blog  # Scan specific directory
"""

import os
import re
import argparse
from html.parser import HTMLParser
from collections import defaultdict

SKIP_TAGS = {'script', 'style', 'code', 'pre', 'svg', 'path', 'noscript', 'template'}

SKIP_CLASSES = {'fa', 'fas', 'far', 'fab', 'icon', 'swiper-pagination-bullet'}

SKIP_PATTERNS = [
    r'^[\s\d\.,\-\+\*\/\(\)\[\]\{\}:;\'\"<>=!@#$%^&|\\~`]+$',
    r'^https?://',
    r'^mailto:',
    r'^tel:',
    r'^\s*$',
    r'^[A-Z_]+$',
    r'^\d+(\.\d+)?%?$',
    r'^[\u2022\u2023\u25E6\u2043\u2219]+$',
]

class TranslationAuditParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.findings = []
        self.current_file = ""
        self.tag_stack = []
        self.skip_depth = 0
        self.line_offset = 0
        
    def set_file(self, filepath):
        self.current_file = filepath
        self.findings = []
        self.tag_stack = []
        self.skip_depth = 0
        
    def handle_starttag(self, tag, attrs):
        attrs_dict = dict(attrs)
        
        if tag.lower() in SKIP_TAGS:
            self.skip_depth += 1
        
        self.tag_stack.append({
            'tag': tag,
            'attrs': attrs_dict,
            'has_translate': 'data-translate' in attrs_dict or 
                            'data-translate-html' in attrs_dict,
            'line': self.getpos()[0]
        })
        
        if tag.lower() == 'img':
            alt = attrs_dict.get('alt', '')
            if alt and 'data-translate-alt' not in attrs_dict:
                if not self._should_skip_text(alt):
                    self.findings.append({
                        'type': 'img-alt',
                        'file': self.current_file,
                        'line': self.getpos()[0],
                        'tag': tag,
                        'text': alt[:50] + ('...' if len(alt) > 50 else ''),
                        'suggestion': 'Add data-translate-alt attribute'
                    })
        
        if tag.lower() == 'input':
            placeholder = attrs_dict.get('placeholder', '')
            if placeholder and 'data-translate-placeholder' not in attrs_dict:
                if not self._should_skip_text(placeholder):
                    self.findings.append({
                        'type': 'placeholder',
                        'file': self.current_file,
                        'line': self.getpos()[0],
                        'tag': tag,
                        'text': placeholder[:50] + ('...' if len(placeholder) > 50 else ''),
                        'suggestion': 'Add data-translate-placeholder attribute'
                    })
        
        title = attrs_dict.get('title', '')
        if title and 'data-translate-title' not in attrs_dict:
            if not self._should_skip_text(title):
                self.findings.append({
                    'type': 'title-attr',
                    'file': self.current_file,
                    'line': self.getpos()[0],
                    'tag': tag,
                    'text': title[:50] + ('...' if len(title) > 50 else ''),
                    'suggestion': 'Add data-translate-title attribute'
                })
    
    def handle_endtag(self, tag):
        if tag.lower() in SKIP_TAGS:
            self.skip_depth = max(0, self.skip_depth - 1)
        
        while self.tag_stack and self.tag_stack[-1]['tag'].lower() != tag.lower():
            self.tag_stack.pop()
        if self.tag_stack:
            self.tag_stack.pop()
    
    def handle_data(self, data):
        if self.skip_depth > 0:
            return
        
        text = data.strip()
        if not text or len(text) < 2:
            return
        
        if self._should_skip_text(text):
            return
        
        has_translate = False
        parent_tag = 'unknown'
        if self.tag_stack:
            for tag_info in reversed(self.tag_stack):
                if tag_info.get('has_translate'):
                    has_translate = True
                    break
            parent_tag = self.tag_stack[-1]['tag'] if self.tag_stack else 'root'
        
        if not has_translate:
            self.findings.append({
                'type': 'text',
                'file': self.current_file,
                'line': self.getpos()[0],
                'tag': parent_tag,
                'text': text[:60] + ('...' if len(text) > 60 else ''),
                'suggestion': 'Add data-translate attribute to parent element'
            })
    
    def _should_skip_text(self, text):
        """Check if text should be skipped (not translatable)."""
        for pattern in SKIP_PATTERNS:
            if re.match(pattern, text, re.IGNORECASE):
                return True
        
        if self.tag_stack:
            classes = self.tag_stack[-1]['attrs'].get('class', '')
            for skip_class in SKIP_CLASSES:
                if skip_class in classes:
                    return True
        
        return False


def scan_html_files(directory='.', verbose=False, threshold=None, extensions=['.html']):
    """Scan all HTML files in directory for translation issues."""
    
    parser = TranslationAuditParser()
    all_findings = defaultdict(list)
    files_scanned = 0
    
    for root, dirs, files in os.walk(directory):
        dirs[:] = [d for d in dirs if d not in ['node_modules', '.git', 'i18n', '__pycache__']]
        
        for filename in files:
            if any(filename.endswith(ext) for ext in extensions):
                filepath = os.path.join(root, filename)
                files_scanned += 1
                
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    parser.set_file(filepath)
                    parser.feed(content)
                    
                    for finding in parser.findings:
                        all_findings[filepath].append(finding)
                        
                except Exception as e:
                    print(f"Warning: Could not parse {filepath}: {e}")
    
    print("\n" + "=" * 60)
    print("HTML MARKUP AUDIT REPORT")
    print("=" * 60)
    
    print(f"\nFiles scanned: {files_scanned}")
    
    total_findings = sum(len(f) for f in all_findings.values())
    files_with_issues = len(all_findings)
    
    if total_findings == 0:
        print("\n✅ No translation issues found!")
        print("   All visible text appears to have proper data-translate attributes.")
        return True
    
    print(f"\n⚠️  Found {total_findings} potential issues in {files_with_issues} files")
    
    by_type = defaultdict(int)
    for findings in all_findings.values():
        for f in findings:
            by_type[f['type']] += 1
    
    print("\n" + "-" * 60)
    print("ISSUES BY TYPE")
    print("-" * 60)
    
    type_labels = {
        'text': 'Text without data-translate',
        'img-alt': 'Image alt without data-translate-alt',
        'placeholder': 'Input placeholder without data-translate-placeholder',
        'title-attr': 'Title attribute without data-translate-title'
    }
    
    for issue_type, count in sorted(by_type.items(), key=lambda x: -x[1]):
        label = type_labels.get(issue_type, issue_type)
        print(f"   {count:4} - {label}")
    
    if verbose:
        print("\n" + "-" * 60)
        print("DETAILED FINDINGS")
        print("-" * 60)
        
        for filepath, findings in sorted(all_findings.items()):
            print(f"\n📄 {filepath}")
            for f in findings[:15]:
                print(f"   Line {f['line']:4}: [{f['type']}] \"{f['text']}\"")
            if len(findings) > 15:
                print(f"   ... and {len(findings) - 15} more")
    else:
        print("\n💡 Run with --verbose to see all findings")
    
    if threshold is not None:
        if total_findings <= threshold:
            print(f"\n✅ Issue count ({total_findings}) is within threshold ({threshold})")
        else:
            print(f"\n❌ Issue count ({total_findings}) exceeds threshold ({threshold})")
    
    print("\n" + "-" * 60)
    print("NEXT STEPS")
    print("-" * 60)
    print("1. Review each finding to determine if translation is needed")
    print("2. Add appropriate data-translate attributes to elements")
    print("3. Add translation keys to translations.csv")
    print("4. Run: python scripts/csv_to_json.py")
    print()
    
    if threshold is not None:
        return total_findings <= threshold
    return True


def main():
    parser = argparse.ArgumentParser(description='Audit HTML for missing translation attributes')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Show all findings in detail')
    parser.add_argument('--dir', '-d', default='.',
                        help='Directory to scan (default: current directory)')
    parser.add_argument('--threshold', '-t', type=int, default=None,
                        help='Maximum allowed issues (fails if count exceeds this)')
    
    args = parser.parse_args()
    
    success = scan_html_files(args.dir, args.verbose, args.threshold)
    exit(0 if success else 1)


if __name__ == '__main__':
    main()
