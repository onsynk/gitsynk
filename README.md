# GitSynk

> Universal, language-agnostic autonomous engineering workflow integrating with Git and GitHub CLI (`gh`).

[![Skill: GitSynk](https://img.shields.io/badge/Agent%20Skill-GitSynk-blue.svg)](./SKILL.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

GitSynk provides an end-to-end autonomous engineering loop for AI coding agents and human engineers. It bridges high-level architectural auditing and planning with day-to-day Git, GitHub CLI (`gh`), and multi-language lint/test execution.

---

## Architecture & Tracks

```
gitsynk/
├── SKILL.md                          # Primary agent skill definition & runbook
├── scripts/
│   ├── detect_quality_tools.sh       # Multi-language linter & test runner auto-detector
│   ├── fetch_task.sh                 # Ingests #ID, extracts context & checks out branch
│   ├── create_task.sh                # Creates categorized issue with priority badges
│   ├── parse_plan.sh                 # Parses plan.txt and executes bulk issue creation
│   └── open_pr.sh                    # Pushes branch and opens PR linked to issue
└── references/
    ├── plan_format.md                # Specification for plan.txt
    └── stack_matrix.md               # Supported language & verification matrix
```

### 🎯 Track 1: Universal Technical Audit, Plan Generation & GitHub Issues
- **Target Audit**: Evaluates any codebase or specific file across any programming language (PHP, Node/TS, Python, Rust, Go, Flutter, Java, C#, Ruby).
- **4 Core Pillars**:
  1. *Critical Bugs & Runtime Safety*
  2. *Performance Bottlenecks*
  3. *Security & Concurrency*
  4. *Architecture & Code Quality*
- **Plan Generation**: Compiles actionable findings into structured `plan.txt`.
- **Bulk GitHub Issues**: Automatically parses `plan.txt` and creates issues with type labels (`bug`, `enhancement`) and priority badges (`🚨 High-Top`, `⚡ Medium`, `🌱 Regular`).

### 🛠️ Track 2: Task Implementation, Auto-Detection & Git/PR Automation
- **Context & Branching**: Ingests issue `#ID`, extracts specifications via `gh issue view`, and switches to a dedicated `fix/issue-<ID>-<slug>` or `feat/issue-<ID>-<slug>` branch.
- **Auto-Detected Verification**: Dynamically detects project configuration (`composer.json`, `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `pubspec.yaml`, etc.) to run native linters, typecheckers, and test suites.
- **Automated Commit & PR**: Stages modified files, generates a conventional commit referencing `#ID`, pushes the branch, and opens a Pull Request linking the issue.

---

## Quick Usage Guide

### 1. Audit & Issue Generation
```bash
# Preview parsed issues from plan.txt
bash scripts/parse_plan.sh plan.txt --preview

# Bulk-create issues in GitHub
bash scripts/parse_plan.sh plan.txt --execute
```

### 2. Task Fetching & Branching
```bash
# Ingest issue #42 and create branch fix/issue-42-sanitize-query
bash scripts/fetch_task.sh #42 --checkout
```

### 3. Stack Verification Auto-Detection
```bash
# Inspect detected tooling
bash scripts/detect_quality_tools.sh . --detect

# Run all linters and tests
bash scripts/detect_quality_tools.sh . --all
```

### 4. Push & Open Linked Pull Request
```bash
# Stage and commit
git add src/ tests/
git commit -m "fix(auth): sanitize user lookup queries (fixes #42)"

# Open Pull Request
bash scripts/open_pr.sh --issue 42
```

---

## Installation as an Antigravity Agent Skill

### Global User Installation
Copy the `gitsynk` folder into your global Antigravity skills directory:
```bash
mkdir -p ~/.gemini/config/skills/gitsynk
cp -r * ~/.gemini/config/skills/gitsynk/
```

### Workspace Installation
Place directly in `.agents/skills/gitsynk/` inside your target project repository.

---

## License

MIT © [OnSynk](https://github.com/onsynk)
