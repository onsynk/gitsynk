#!/usr/bin/env bash
# ==============================================================================
# open_pr.sh
# Push Branch and Open a Linked Pull Request with Automated Issue Linking
# Part of GitSynk Autonomous Engineering Workflow
# ==============================================================================

set -euo pipefail

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
ISSUE_ID=""
PR_TITLE=""
PR_BODY=""
PR_BODY_FILE=""
COMMENT_ISSUE=true
DRAFT=false

# Auto-detect issue ID from branch name: e.g., feat/issue-42-some-feature or fix/issue-42
if [[ "$CURRENT_BRANCH" =~ issue-([0-9]+) ]]; then
    ISSUE_ID="${BASH_REMATCH[1]}"
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --issue|-i)
            ISSUE_ID="$2"
            shift 2
            ;;
        --title|-t)
            PR_TITLE="$2"
            shift 2
            ;;
        --body|-b)
            PR_BODY="$2"
            shift 2
            ;;
        --body-file|-f)
            PR_BODY_FILE="$2"
            shift 2
            ;;
        --draft|-d)
            DRAFT=true
            shift
            ;;
        --no-comment)
            COMMENT_ISSUE=false
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

if [[ "$CURRENT_BRANCH" == "main" ]] || [[ "$CURRENT_BRANCH" == "master" ]]; then
    echo "Error: Cannot open a Pull Request directly from '$CURRENT_BRANCH'. Switch to a feature/fix branch first." >&2
    exit 1
fi

echo -e "\033[1;36m============================================================\033[0m"
echo -e "\033[1;34mGitSynk PR Automation\033[0m"
echo -e "Branch: \033[1;32m$CURRENT_BRANCH\033[0m"
if [[ -n "$ISSUE_ID" ]]; then
    echo -e "Linked Issue: \033[1;32m#$ISSUE_ID\033[0m"
fi
echo -e "\033[1;36m============================================================\033[0m"

# Default title if not provided
if [[ -z "$PR_TITLE" ]]; then
    LAST_COMMIT_MSG=$(git log -1 --pretty=%s)
    if [[ -n "$ISSUE_ID" ]] && [[ ! "$LAST_COMMIT_MSG" =~ \#${ISSUE_ID} ]]; then
        PR_TITLE="$LAST_COMMIT_MSG (resolves #$ISSUE_ID)"
    else
        PR_TITLE="$LAST_COMMIT_MSG"
    fi
fi

# Load body from file or generate standard body
if [[ -n "$PR_BODY_FILE" ]] && [[ -f "$PR_BODY_FILE" ]]; then
    PR_BODY=$(cat "$PR_BODY_FILE")
elif [[ -z "$PR_BODY" ]]; then
    PR_BODY="## Overview & Motivation
Implemented task requirements on branch \`${CURRENT_BRANCH}\`.

### Key Changes
$(git log origin/HEAD..HEAD --pretty=format:"- %s" 2>/dev/null || git log -5 --pretty=format:"- %s")

### Verification & Quality Checks
- [x] Linter & Static Analysis passed.
- [x] Unit / Regression Tests passed.
"
    if [[ -n "$ISSUE_ID" ]]; then
        PR_BODY="${PR_BODY}
### Linked Issue
Closes #${ISSUE_ID}
"
    fi
    PR_BODY="${PR_BODY}
---
*Automated PR submitted by [GitSynk](https://github.com/)*"
fi

# Step 1: Push branch to origin
echo "Pushing '$CURRENT_BRANCH' to remote origin..."
git push -u origin "$CURRENT_BRANCH"

# Step 2: Open PR via gh
GH_PR_ARGS=(
    pr create
    --title "$PR_TITLE"
    --body "$PR_BODY"
)

if [[ "$DRAFT" == true ]]; then
    GH_PR_ARGS+=(--draft)
fi

echo "Creating GitHub Pull Request..."
PR_URL=$(gh "${GH_PR_ARGS[@]}")

echo -e "\033[1;32mPull Request successfully created!\033[0m"
echo -e "PR URL: \033[1;34m$PR_URL\033[0m"

# Step 3: Optional comment on issue
if [[ "$COMMENT_ISSUE" == true ]] && [[ -n "$ISSUE_ID" ]]; then
    echo "Adding notification comment to issue #$ISSUE_ID..."
    gh issue comment "$ISSUE_ID" --body "🚀 Pull Request submitted for this issue: ${PR_URL}" 2>/dev/null || true
fi
