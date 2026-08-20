#!/usr/bin/env python3
"""Validate this repository's marketplace and plugin content.

Run locally with:  python scripts/validate.py
Runs in CI on every push and pull request (see .github/workflows/validate.yml).

Checks:
  1. marketplace.json and plugin.json are valid JSON with the required fields.
  2. Every agent .md and SKILL.md has YAML frontmatter that parses cleanly.
  3. SKILL.md 'description' is <= 1024 characters (the Claude Code plugin
     validator's hard limit) and non-empty.
  4. Cross-references of the form `NN-filename.md` (optionally `§N` / `§Na`)
     inside the skill's reference docs point at files, and section numbers
     that actually exist in the target file.
  5. Every .tf file under the skill's examples/ directory parses as valid HCL.

Exits 1 with a report if anything fails, 0 with a summary otherwise.
"""
import json
import re
import sys
from pathlib import Path

import yaml

try:
    import hcl2
except ImportError:
    hcl2 = None

ROOT = Path(__file__).resolve().parent.parent
PLUGIN_ROOT = ROOT / "plugins" / "fsi-cloud-architect"
SKILL_ROOT = PLUGIN_ROOT / "skills" / "fsi-hybrid-cloud"

errors = []


def fail(msg):
    errors.append(msg)


def rel(path):
    return str(path.relative_to(ROOT))


# --- 1. JSON validity + required fields -------------------------------------

marketplace_json = ROOT / ".claude-plugin" / "marketplace.json"
plugin_json = PLUGIN_ROOT / ".claude-plugin" / "plugin.json"

marketplace_data = None
if not marketplace_json.exists():
    fail(f"missing {rel(marketplace_json)}")
else:
    try:
        marketplace_data = json.loads(marketplace_json.read_text())
    except json.JSONDecodeError as e:
        fail(f"{rel(marketplace_json)}: invalid JSON — {e}")

if marketplace_data is not None:
    for field in ("name", "owner", "plugins"):
        if field not in marketplace_data:
            fail(f"{rel(marketplace_json)}: missing required field '{field}'")
    owner = marketplace_data.get("owner")
    if isinstance(owner, dict) and "name" not in owner:
        fail(f"{rel(marketplace_json)}: owner.name is required")
    for i, p in enumerate(marketplace_data.get("plugins", [])):
        for field in ("name", "source"):
            if field not in p:
                fail(f"{rel(marketplace_json)}: plugins[{i}] missing required field '{field}'")
        source = p.get("source")
        if isinstance(source, str) and source.startswith("./"):
            if not (ROOT / source).is_dir():
                fail(f"{rel(marketplace_json)}: plugins[{i}].source '{source}' does not exist")

plugin_data = None
if not plugin_json.exists():
    fail(f"missing {rel(plugin_json)}")
else:
    try:
        plugin_data = json.loads(plugin_json.read_text())
    except json.JSONDecodeError as e:
        fail(f"{rel(plugin_json)}: invalid JSON — {e}")

if plugin_data is not None:
    for field in ("name", "version", "description"):
        if field not in plugin_data:
            fail(f"{rel(plugin_json)}: missing required field '{field}'")

# --- 2 & 3. Frontmatter YAML + SKILL.md description length ------------------


def extract_frontmatter(path):
    text = path.read_text()
    if not text.startswith("---"):
        return None
    parts = text.split("---", 2)
    if len(parts) < 3:
        return None
    return parts[1]


agent_files = sorted((PLUGIN_ROOT / "agents").glob("*.md")) if (PLUGIN_ROOT / "agents").is_dir() else []
skill_files = sorted(PLUGIN_ROOT.glob("skills/*/SKILL.md"))
frontmatter_files = agent_files + skill_files

for md in frontmatter_files:
    fm_text = extract_frontmatter(md)
    if fm_text is None:
        fail(f"{rel(md)}: no YAML frontmatter block found (expected leading '---')")
        continue
    try:
        fm = yaml.safe_load(fm_text)
    except yaml.YAMLError as e:
        fail(f"{rel(md)}: frontmatter YAML parse error — {e}")
        continue
    if fm is None or not isinstance(fm, dict):
        fail(f"{rel(md)}: frontmatter did not parse to a mapping")
        continue
    if "name" not in fm:
        fail(f"{rel(md)}: frontmatter missing 'name'")
    if "description" not in fm:
        fail(f"{rel(md)}: frontmatter missing 'description'")
    if md.name == "SKILL.md":
        desc = fm.get("description") or ""
        if len(desc) > 1024:
            fail(f"{rel(md)}: description is {len(desc)} characters, must be <= 1024")
        if not desc.strip():
            fail(f"{rel(md)}: description is empty")

# --- 4. Cross-reference integrity -------------------------------------------

refs_dir = SKILL_ROOT / "references"
if not refs_dir.is_dir():
    fail(f"missing references directory: {rel(SKILL_ROOT)}/references")
else:
    ref_files = {f.name: f for f in refs_dir.glob("*.md")}
    heading_re_cache = {}

    def has_section(target_path, section):
        if target_path not in heading_re_cache:
            heading_re_cache[target_path] = target_path.read_text()
        text = heading_re_cache[target_path]
        pattern = rf"(?m)^#{{2,3}}\s+{re.escape(section)}\.\s"
        return re.search(pattern, text) is not None

    citing_files = list(refs_dir.glob("*.md")) + agent_files + skill_files
    ref_pattern = re.compile(r"`(\d{2}-[a-z0-9-]+\.md)`(?:\s*§(\d+[a-z]?))?")

    for md in citing_files:
        text = md.read_text()
        for m in ref_pattern.finditer(text):
            fname, section = m.group(1), m.group(2)
            target = ref_files.get(fname)
            if target is None:
                fail(f"{rel(md)}: references missing file '{fname}'")
                continue
            if section and not has_section(target, section):
                fail(
                    f"{rel(md)}: references '{fname} §{section}', "
                    f"but no '## {section}.' or '### {section}.' heading exists in {fname}"
                )

# --- 5. Terraform HCL validity ----------------------------------------------

examples_dir = SKILL_ROOT / "examples"
if hcl2 is None:
    fail("python-hcl2 is not installed — cannot validate Terraform examples (pip install python-hcl2)")
elif examples_dir.is_dir():
    tf_files = sorted(examples_dir.glob("*.tf"))
    for tf in tf_files:
        try:
            with open(tf, "r") as f:
                hcl2.load(f)
        except Exception as e:
            fail(f"{rel(tf)}: HCL parse error — {e}")

# --- Report -------------------------------------------------------------

if errors:
    print(f"VALIDATION FAILED — {len(errors)} error(s):\n")
    for e in errors:
        print(f"  ✗ {e}")
    sys.exit(1)

print("All validation checks passed:")
print(f"  ✓ JSON validity — marketplace.json, plugin.json")
print(f"  ✓ Frontmatter YAML + SKILL.md description length — {len(frontmatter_files)} file(s)")
print(f"  ✓ Cross-reference integrity — {len(list(refs_dir.glob('*.md')))} reference file(s)")
print(f"  ✓ Terraform HCL validity — {len(list(examples_dir.glob('*.tf')))} file(s)")
sys.exit(0)
