#!/usr/bin/env python3
"""
download-ai-docs.py — Discover and download llms.txt reference docs for project dependencies.

Scans package.json files (and other manifests) across a monorepo, discovers llms.txt
endpoints for each dependency, downloads them to a local docs directory, and maintains
a known-sources cache for fast subsequent runs.

Usage:
    python3 scripts/download-ai-docs.py              # Human-readable output
    python3 scripts/download-ai-docs.py --json        # JSON output for automation

No external dependencies — uses only Python stdlib (urllib, json, pathlib, etc.).
Works with Python 3.8+.
"""

import argparse
import json
import os
import re
import sys
import time
from pathlib import Path
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError
from urllib.parse import urlparse

# ── Configuration ────────────────────────────────────────────────────────────

DOCS_DIR = Path("docs/llms-txt")
KNOWN_SOURCES_FILE = DOCS_DIR / "known-sources.json"
CONFIG_FILE = Path(".llmstxt.json")

# Packages that aren't project dependencies but have useful llms.txt docs.
# Customize this for your project.
EXTRA_PACKAGES = [
    # "bun",
    # "vercel",
    # "@neondatabase/serverless",
    # "shadcn-ui",
]

# Packages matching these patterns are skipped (no useful llms.txt).
SKIP_PATTERNS = [
    r"^@types/",          # Type definitions
    r"^eslint",           # Linting tools
    r"^@eslint/",         # ESLint ecosystem
    r"^prettier",         # Formatter
    r"^@tailwindcss/",    # CSS engine internals
    r"^@storybook/",      # Build tooling
    r"^typescript$",      # TS compiler itself
    r"^@babel/",          # Transpiler internals
    r"^webpack",          # Bundler internals
    r"^postcss",          # CSS processing
    r"^autoprefixer$",    # CSS processing
    r"-stubs$",           # Python type stubs
    r"^types-",           # Python type stubs
    r"^pip$",             # Python packaging
    r"^setuptools$",      # Python packaging
    r"^wheel$",           # Python packaging
    r"^bundler$",         # Ruby packaging
    r"^rake$",            # Ruby build tool
    r"^proc-macro2$",     # Rust macro infra
    r"^syn$",             # Rust macro infra
    r"^quote$",           # Rust macro infra
]

# URL patterns to probe for each package homepage
PROBE_SUFFIXES = [
    "/llms-full.txt",
    "/llms.txt",
    "/docs/llms-full.txt",
    "/docs/llms.txt",
]

AGGREGATORS = [
    "https://llmstxt.site/{}",
    "https://llmstxthub.com/{}",
]

REQUEST_TIMEOUT = 15  # seconds
MAX_CONCURRENT = 5

# ── Helpers ──────────────────────────────────────────────────────────────────


def load_config():
    """Load .llmstxt.json config, merging with defaults."""
    config = {
        "docs_dir": "docs/llms-txt/",
        "skip": [],
        "extra_packages": [],
        "claude_md": "CLAUDE.md",
        "agent_dir": ".claude/agents/",
    }
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE) as f:
            user_config = json.load(f)
            config.update(user_config)
    return config


def load_known_sources():
    """Load the known-sources cache."""
    if KNOWN_SOURCES_FILE.exists():
        with open(KNOWN_SOURCES_FILE) as f:
            return json.load(f)
    return {}


def save_known_sources(sources):
    """Save the known-sources cache."""
    DOCS_DIR.mkdir(parents=True, exist_ok=True)
    with open(KNOWN_SOURCES_FILE, "w") as f:
        json.dump(sources, f, indent=2, sort_keys=True)
        f.write("\n")


def should_skip(name, extra_skip_patterns=None):
    """Check if a package should be skipped."""
    all_patterns = SKIP_PATTERNS + (extra_skip_patterns or [])
    return any(re.search(p, name) for p in all_patterns)


def normalize_filename(name):
    """Convert a package name to a safe filename."""
    # @scope/pkg -> scope-pkg
    name = name.lstrip("@").replace("/", "-")
    # Remove special chars
    name = re.sub(r"[^a-zA-Z0-9._-]", "-", name)
    return f"{name}.txt"


def fetch_text(url, timeout=REQUEST_TIMEOUT):
    """Fetch a URL and return text content, or None on failure."""
    try:
        req = Request(url, headers={"User-Agent": "llmstxt-downloader/1.0"})
        with urlopen(req, timeout=timeout) as resp:
            if resp.status != 200:
                return None
            content_type = resp.headers.get("Content-Type", "")
            if "html" in content_type.lower() and "text/plain" not in content_type.lower():
                return None
            body = resp.read().decode("utf-8", errors="replace")
            # Reject HTML served as text
            if body.strip().startswith(("<!DOCTYPE", "<html", "<!doctype")):
                return None
            # Reject stubs/placeholders
            if len(body.strip()) < 100:
                return None
            return body
    except (URLError, HTTPError, OSError, TimeoutError, ValueError):
        return None


# ── Dependency Scanning ──────────────────────────────────────────────────────


def scan_js_deps():
    """Scan all package.json files for dependencies."""
    deps = set()
    for pj_path in Path(".").rglob("package.json"):
        # Skip node_modules, .git, vendor dirs
        parts = pj_path.parts
        if any(p in parts for p in ("node_modules", ".git", "vendor", "dist", "build")):
            continue
        try:
            with open(pj_path) as f:
                pkg = json.load(f)
            for key in ("dependencies", "devDependencies", "peerDependencies"):
                if key in pkg:
                    deps.update(pkg[key].keys())
        except (json.JSONDecodeError, KeyError):
            continue
    return deps


def scan_python_deps():
    """Scan Python dependency files."""
    deps = set()
    # requirements.txt files
    for req_file in Path(".").rglob("requirements*.txt"):
        parts = req_file.parts
        if any(p in parts for p in (".git", "vendor", "venv", ".venv")):
            continue
        try:
            for line in open(req_file):
                line = line.strip()
                if line and not line.startswith(("#", "-")):
                    # Extract package name (before ==, >=, etc.)
                    name = re.split(r"[>=<!\[\];]", line)[0].strip()
                    if name:
                        deps.add(name)
        except OSError:
            continue
    # pyproject.toml (basic parsing)
    for toml_file in Path(".").rglob("pyproject.toml"):
        parts = toml_file.parts
        if any(p in parts for p in (".git", "vendor", "venv", ".venv")):
            continue
        try:
            content = open(toml_file).read()
            # Extract from dependencies = ["pkg>=1.0", ...]
            for match in re.finditer(r'"([a-zA-Z0-9_-]+)[>=<\[!]?', content):
                deps.add(match.group(1))
        except OSError:
            continue
    return deps


def scan_rust_deps():
    """Scan Cargo.toml files for dependencies."""
    deps = set()
    for cargo_file in Path(".").rglob("Cargo.toml"):
        parts = cargo_file.parts
        if any(p in parts for p in (".git", "target", "vendor")):
            continue
        try:
            content = open(cargo_file).read()
            in_deps = False
            for line in content.splitlines():
                if re.match(r"\[(.*dependencies.*)\]", line):
                    in_deps = True
                    continue
                if line.startswith("[") and in_deps:
                    in_deps = False
                    continue
                if in_deps:
                    match = re.match(r"([a-zA-Z0-9_-]+)\s*=", line)
                    if match:
                        deps.add(match.group(1))
        except OSError:
            continue
    return deps


def scan_go_deps():
    """Scan go.mod files for dependencies."""
    deps = set()
    for gomod in Path(".").rglob("go.mod"):
        parts = gomod.parts
        if any(p in parts for p in (".git", "vendor")):
            continue
        try:
            content = open(gomod).read()
            in_require = False
            for line in content.splitlines():
                if line.strip() == "require (":
                    in_require = True
                    continue
                if line.strip() == ")" and in_require:
                    in_require = False
                    continue
                if in_require:
                    match = re.match(r"\s+(\S+)\s+", line)
                    if match:
                        deps.add(match.group(1))
                elif line.startswith("require "):
                    match = re.match(r"require\s+(\S+)\s+", line)
                    if match:
                        deps.add(match.group(1))
        except OSError:
            continue
    return deps


def scan_ruby_deps():
    """Scan Gemfile for dependencies."""
    deps = set()
    for gemfile in Path(".").rglob("Gemfile"):
        parts = gemfile.parts
        if any(p in parts for p in (".git", "vendor")):
            continue
        try:
            for line in open(gemfile):
                match = re.match(r"""gem\s+['"]([a-zA-Z0-9_-]+)['"]""", line.strip())
                if match:
                    deps.add(match.group(1))
        except OSError:
            continue
    return deps


def scan_all_deps():
    """Scan all ecosystems and return deduplicated dependency set."""
    deps = set()
    ecosystems = []

    js_deps = scan_js_deps()
    if js_deps:
        deps.update(js_deps)
        ecosystems.append(f"JavaScript ({len(js_deps)} deps)")

    py_deps = scan_python_deps()
    if py_deps:
        deps.update(py_deps)
        ecosystems.append(f"Python ({len(py_deps)} deps)")

    rust_deps = scan_rust_deps()
    if rust_deps:
        deps.update(rust_deps)
        ecosystems.append(f"Rust ({len(rust_deps)} deps)")

    go_deps = scan_go_deps()
    if go_deps:
        deps.update(go_deps)
        ecosystems.append(f"Go ({len(go_deps)} deps)")

    ruby_deps = scan_ruby_deps()
    if ruby_deps:
        deps.update(ruby_deps)
        ecosystems.append(f"Ruby ({len(ruby_deps)} deps)")

    return deps, ecosystems


# ── URL Discovery ────────────────────────────────────────────────────────────


def get_npm_homepage(name):
    """Look up a package's homepage from the npm registry."""
    url = f"https://registry.npmjs.org/{name}/latest"
    try:
        req = Request(url, headers={"User-Agent": "llmstxt-downloader/1.0"})
        with urlopen(req, timeout=REQUEST_TIMEOUT) as resp:
            data = json.loads(resp.read())
            return data.get("homepage") or data.get("repository", {}).get("url", "")
    except (URLError, HTTPError, json.JSONDecodeError, OSError):
        return ""


def clean_homepage(url):
    """Normalize a homepage URL."""
    if not url:
        return ""
    # Remove git+ prefix and .git suffix
    url = url.replace("git+", "").replace("git://", "https://")
    url = re.sub(r"\.git$", "", url)
    # Convert SSH to HTTPS
    url = re.sub(r"git@github\.com:", "https://github.com/", url)
    # Ensure https
    if url.startswith("http://"):
        url = "https://" + url[7:]
    return url.rstrip("/")


def discover_url(name, known_sources):
    """Try to find a working llms.txt URL for a package."""
    # Strategy 1: Check cache
    if name in known_sources:
        cached_url = known_sources[name]
        content = fetch_text(cached_url)
        if content:
            return cached_url, content, "cached"

    # Strategy 2: npm registry lookup + URL probing
    homepage = clean_homepage(get_npm_homepage(name))
    if homepage:
        # Skip GitHub repo URLs for probing (they don't host docs)
        probe_base = homepage
        if "github.com" in homepage:
            # Try the GitHub Pages equivalent
            parsed = urlparse(homepage)
            path_parts = parsed.path.strip("/").split("/")
            if len(path_parts) >= 2:
                org, repo = path_parts[0], path_parts[1]
                # Try common doc sites
                for base in [f"https://{org}.github.io/{repo}", homepage]:
                    for suffix in PROBE_SUFFIXES:
                        content = fetch_text(base + suffix)
                        if content:
                            return base + suffix, content, "probed"
        else:
            for suffix in PROBE_SUFFIXES:
                content = fetch_text(probe_base + suffix)
                if content:
                    return probe_base + suffix, content, "probed"

    # Strategy 3: GitHub raw content
    if homepage and "github.com" in homepage:
        parsed = urlparse(homepage)
        path_parts = parsed.path.strip("/").split("/")
        if len(path_parts) >= 2:
            org, repo = path_parts[0], path_parts[1]
            for branch in ["main", "master"]:
                for fname in ["llms-full.txt", "llms.txt"]:
                    raw_url = f"https://raw.githubusercontent.com/{org}/{repo}/{branch}/{fname}"
                    content = fetch_text(raw_url)
                    if content:
                        return raw_url, content, "github-raw"

    # Strategy 4: Aggregator sites
    clean_name = name.lstrip("@").replace("/", "-")
    for pattern in AGGREGATORS:
        agg_url = pattern.format(clean_name)
        content = fetch_text(agg_url)
        if content:
            return agg_url, content, "aggregator"

    return None, None, "not-found"


# ── Main ─────────────────────────────────────────────────────────────────────


def main():
    parser = argparse.ArgumentParser(description="Download llms.txt reference docs")
    parser.add_argument("--json", action="store_true", help="Output JSON for automation")
    args = parser.parse_args()

    config = load_config()
    docs_dir = Path(config["docs_dir"])
    docs_dir.mkdir(parents=True, exist_ok=True)

    known_sources = load_known_sources()
    extra_skip = config.get("skip", [])
    extra_packages = set(config.get("extra_packages", []) + EXTRA_PACKAGES)

    # Scan dependencies
    deps, ecosystems = scan_all_deps()
    deps.update(extra_packages)

    skipped = set()
    significant = set()
    for dep in deps:
        if should_skip(dep, extra_skip):
            skipped.add(dep)
        else:
            significant.add(dep)

    if not args.json:
        print(f"Scanned monorepo: {len(significant)} significant deps "
              f"({len(skipped)} skipped, {len(extra_packages)} extra)")
        print(f"Ecosystems: {', '.join(ecosystems) if ecosystems else 'none detected'}")
        print()

    # Discover and download
    results = {"new": [], "updated": [], "unchanged": [], "failed": [], "orphaned": []}

    for name in sorted(significant):
        url, content, method = discover_url(name, known_sources)

        if not url or not content:
            results["failed"].append({"name": name, "reason": "no llms.txt endpoint found"})
            if not args.json:
                print(f"  SKIP  {name} — no llms.txt endpoint found")
            continue

        filename = normalize_filename(name)
        filepath = docs_dir / filename
        size_kb = len(content.encode("utf-8")) / 1024

        if filepath.exists():
            existing = filepath.read_text(errors="replace")
            if existing == content:
                results["unchanged"].append({"name": name, "file": filename, "size_kb": round(size_kb, 1)})
                if not args.json:
                    print(f"  SAME  {name:<35} {size_kb:>8.1f} KB")
            else:
                filepath.write_text(content)
                results["updated"].append({"name": name, "file": filename, "size_kb": round(size_kb, 1), "url": url})
                if not args.json:
                    print(f"  UPD   {name:<35} {size_kb:>8.1f} KB")
        else:
            filepath.write_text(content)
            results["new"].append({"name": name, "file": filename, "size_kb": round(size_kb, 1), "url": url})
            if not args.json:
                print(f"  NEW   {name:<35} {size_kb:>8.1f} KB")

        # Update cache
        known_sources[name] = url

    # Detect orphans
    dep_filenames = {normalize_filename(name) for name in significant}
    if docs_dir.exists():
        for f in docs_dir.iterdir():
            if f.suffix == ".txt" and f.name != "known-sources.json" and f.name not in dep_filenames:
                results["orphaned"].append({"file": f.name})
                if not args.json:
                    print(f"  ORPHAN {f.name}")

    # Save cache
    save_known_sources(known_sources)

    # Summary
    if args.json:
        output = {
            "ecosystems": ecosystems,
            "total_deps": len(deps),
            "significant": len(significant),
            "skipped": len(skipped),
            "results": results,
        }
        print(json.dumps(output, indent=2))
    else:
        print()
        print(f"Done: {len(results['new'])} new, {len(results['updated'])} updated, "
              f"{len(results['unchanged'])} unchanged, {len(results['failed'])} failed, "
              f"{len(results['orphaned'])} orphaned")

    # Exit code: 0 if any docs exist, 1 if none found
    total_docs = len(results["new"]) + len(results["updated"]) + len(results["unchanged"])
    sys.exit(0 if total_docs > 0 else 1)


if __name__ == "__main__":
    main()
