# fsi-cloud-architect

Private Claude Code / Cowork **plugin marketplace**, containing a single
plugin: `fsi-cloud-architect` — a principal-level cloud architecture and
platform enablement agent + skill for financial services, GCP-first with AWS.

See [`plugins/fsi-cloud-architect/README.md`](plugins/fsi-cloud-architect/README.md)
for what the plugin actually contains.

---

## Install

Since this repo is private, whoever installs it needs read access to it on
GitHub — you'll be prompted to authenticate either way.

### Claude Code (terminal)

```
/plugin marketplace add thespamer/fsi-cloud-architect
/plugin install fsi-cloud-architect@fsi-cloud-architect
```

Run both lines inside a Claude Code session in your terminal. `/plugin` is a
CLI command — it does not work typed into a Cowork or claude.ai chat.

### Claude Desktop (Cowork)

1. Open the sidebar and go to **Customize → Plugins**
2. Click **Add marketplace**
3. Enter `thespamer/fsi-cloud-architect` (the `owner/repo` shorthand works)
4. Authenticate with GitHub if prompted
5. Click **Browse plugins**, find `fsi-cloud-architect`, click **Install**

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
