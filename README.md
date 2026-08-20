# fsi-cloud-architect

Private Claude Code / Cowork **plugin marketplace**, containing a single
plugin: `fsi-cloud-architect` — a principal-level cloud architecture and
platform enablement agent + skill for financial services, GCP-first with AWS.

See [`plugins/fsi-cloud-architect/README.md`](plugins/fsi-cloud-architect/README.md)
for what the plugin actually contains.

---

## Install

**In Claude Code (CLI):**

```
/plugin marketplace add thespamer/fsi-cloud-architect
/plugin install fsi-cloud-architect@fsi-cloud-architect
```

**In Cowork:** open **Customize → Plugins → Add marketplace**, enter
`thespamer/fsi-cloud-architect`, then find `fsi-cloud-architect` under
**Browse plugins** and click **Install**.

Since this repo is private, whoever installs it needs read access to it on
GitHub — you'll be prompted to authenticate when adding the marketplace.

Once installed, the skill is invoked automatically when a prompt matches its
domain, or explicitly via `/fsi-hybrid-cloud`. The agent can be invoked
explicitly for larger deliverables (a full design, a review report, a
migration plan).

To pick up changes: in Claude Code, run `/plugin marketplace update
fsi-cloud-architect` (or remove and re-add it) and reinstall; in Cowork, click
**Update** on the marketplace under Customize → Plugins.

---

## Repository layout

```
.
├── .claude-plugin/
│   └── marketplace.json          # marketplace manifest — lists the plugin(s) below
├── .github/workflows/
│   └── validate.yml              # CI: validates on every push and pull request
├── scripts/
│   └── validate.py               # the validation suite CI runs
└── plugins/
    └── fsi-cloud-architect/      # the plugin itself — this is what gets installed
        ├── .claude-plugin/plugin.json
        ├── agents/fsi-cloud-architect.md
        └── skills/fsi-hybrid-cloud/
```

## CI

Every push and pull request runs `scripts/validate.py`, which checks:

- `marketplace.json` and `plugin.json` are valid JSON with the required fields
- every agent file and `SKILL.md` has YAML frontmatter that parses
- `SKILL.md`'s `description` is non-empty and ≤ 1024 characters (the Claude
  Code plugin validator's limit)
- cross-references between the skill's reference files (`NN-filename.md`,
  `§N`) point at files and sections that actually exist
- every `.tf` example under the skill parses as valid HCL

Run it locally before pushing:

```
pip install pyyaml python-hcl2
python scripts/validate.py
```

## Versioning

Bump `version` in both `plugins/fsi-cloud-architect/.claude-plugin/plugin.json`
and the matching plugin entry in `.claude-plugin/marketplace.json` together —
CI does not currently enforce that they match.
