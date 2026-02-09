#!/usr/bin/env python3
import os
import shutil
import re
import json

SOURCE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT_DIR = os.path.join(SOURCE_DIR, "mindspace-build")

EXCLUDE_DIRS = {
    "docs",
    "scripts",
    "mindspace-build",
    ".git",
    ".cache",
    ".config",
    ".upm",
    ".pythonlibs",
    "node_modules",
    "__pycache__",
    "attached_assets",
    ".local",
}

EXCLUDE_FILES = {
    "main.py",
    "replit.md",
    ".replit",
    "replit.nix",
    ".gitignore",
    "poetry.lock",
    "pyproject.toml",
    ".replit.nix",
    "docs.css",
}

TEXT_EXTENSIONS = {
    ".html", ".css", ".js", ".json", ".py", ".md", ".txt", ".svg",
}

NAVBAR_DOCS_PATTERN = re.compile(
    r'<li\s+class="navbar-item">\s*'
    r'<a\s+href="/docs/"[^>]*>\s*'
    r'<div\s+class="separator"></div>\s*'
    r'<span[^>]*data-translate="nav_docs"[^>]*>[^<]*</span>\s*'
    r'</a>\s*'
    r'</li>',
    re.DOTALL
)

VERCEL_DOCS_REWRITE = re.compile(
    r'\s*\{\s*"source"\s*:\s*"/docs/"\s*,\s*"destination"\s*:\s*"/docs/index\.html"\s*\}\s*,?',
)

CSS_DOCS_LINK = re.compile(
    r'<link\s+rel="stylesheet"\s+href="/css/docs\.css"\s*/?>\s*\n?',
)


def should_exclude(path):
    parts = path.split(os.sep)
    for part in parts:
        if part in EXCLUDE_DIRS:
            return True
    basename = os.path.basename(path)
    if basename in EXCLUDE_FILES:
        return True
    return False


def is_text_file(filepath):
    _, ext = os.path.splitext(filepath)
    return ext.lower() in TEXT_EXTENSIONS


def transform_content(content, filepath):
    basename = os.path.basename(filepath)
    _, ext = os.path.splitext(filepath)

    content = NAVBAR_DOCS_PATTERN.sub("", content)

    content = CSS_DOCS_LINK.sub("", content)

    if basename == "vercel.json":
        content = VERCEL_DOCS_REWRITE.sub("", content)

    content = content.replace("MindBalance", "MindSpace")
    content = content.replace("mindbalance", "mindspace")
    content = content.replace("MINDBALANCE", "MINDSPACE")
    content = content.replace("Mindbalance", "Mindspace")

    return content


def build():
    if os.path.exists(OUTPUT_DIR):
        shutil.rmtree(OUTPUT_DIR)
    os.makedirs(OUTPUT_DIR)

    file_count = 0
    skipped = 0

    for root, dirs, files in os.walk(SOURCE_DIR):
        rel_root = os.path.relpath(root, SOURCE_DIR)

        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]

        for filename in files:
            rel_path = os.path.join(rel_root, filename) if rel_root != "." else filename

            if should_exclude(rel_path):
                skipped += 1
                continue

            src_path = os.path.join(root, filename)
            dst_path = os.path.join(OUTPUT_DIR, rel_path)

            os.makedirs(os.path.dirname(dst_path), exist_ok=True)

            if is_text_file(src_path):
                try:
                    with open(src_path, "r", encoding="utf-8") as f:
                        content = f.read()
                    content = transform_content(content, src_path)
                    with open(dst_path, "w", encoding="utf-8") as f:
                        f.write(content)
                except (UnicodeDecodeError, PermissionError):
                    shutil.copy2(src_path, dst_path)
            else:
                shutil.copy2(src_path, dst_path)

            file_count += 1

    rename_map = {
        "MindBalanceLogo.svg": "MindSpaceLogo.svg",
        "MindBalanceVideo.mp4": "MindSpaceVideo.mp4",
        "MindBalanceHub.mp4": "MindSpaceHub.mp4",
    }
    images_dir = os.path.join(OUTPUT_DIR, "assets", "images")
    for old_name, new_name in rename_map.items():
        old_path = os.path.join(images_dir, old_name)
        if os.path.exists(old_path):
            os.rename(old_path, os.path.join(images_dir, new_name))
            print(f"  Renamed: {old_name} -> {new_name}")

    print(f"MindSpace build complete!")
    print(f"  Output: {OUTPUT_DIR}")
    print(f"  Files copied: {file_count}")
    print(f"  Files skipped: {skipped}")


if __name__ == "__main__":
    build()
