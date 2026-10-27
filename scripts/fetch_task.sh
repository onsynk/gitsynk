#!/usr/bin/env bash
# ==============================================================================
# fetch_task.sh
# Ingest GitHub Task/Issue Context and Prepare Branching
# Part of GitSynk Autonomous Engineering Workflow
# ==============================================================================

set -euo pipefail

ISSUE_INPUT="${1:-}"
CHECKOUT_FLAG=false
CUSTOM_PREFIX=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --checkout|-c)
            CHECKOUT_FLAG=true
            shift
            ;;
        --prefix|-p)
            CUSTOM_PREFIX="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            if [[ -z "$ISSUE_INPUT" ]]; then
                ISSUE_INPUT="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$ISSUE_INPUT" ]]; then
    echo "Usage: $0 <#ID|ID|URL> [--checkout] [--prefix <prefix>]" >&2
    echo "Example: $0 #42 --checkout" >&2
    exit 1
fi

# Sanitize issue identifier (remove leading '#' or extract ID from github url)
ISSUE_ID=$(echo "$ISSUE_INPUT" | sed -E 's/.*\/issues\/([0-9]+).*/\1/' | sed 's/^#//')

if ! [[ "$ISSUE_ID" =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid Issue ID '$ISSUE_INPUT'. Must be a numeric ID or GitHub issue URL." >&2
    exit 1
fi

# Verify gh CLI is available
if ! command -v gh &>/dev/null; then
    echo "Error: GitHub CLI ('gh') is not installed or not in PATH." >&2
    exit 1
fi

# Fetch issue data via gh CLI
ISSUE_JSON=$(gh issue view "$ISSUE_ID" --json number,title,body,labels,state,assignees,url 2>/dev/null) || {
    echo "Error: Failed to fetch issue #$ISSUE_ID using 'gh issue view'." >&2
    exit 1
}

# Parse fields
TITLE=$(echo "$ISSUE_JSON" | grep -o '"title":"[^"]*"' | head -1 | cut -d'"' -f4)
STATE=$(echo "$ISSUE_JSON" | grep -o '"state":"[^"]*"' | head -1 | cut -d'"' -f4)
URL=$(echo "$ISSUE_JSON" | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)

# Determine branch prefix
PREFIX="feat"
if [[ -n "$CUSTOM_PREFIX" ]]; then
    PREFIX="$CUSTOM_PREFIX"
elif echo "$ISSUE_JSON" | grep -qi '"name":"[^"]*bug[^"]*"'; then
    PREFIX="fix"
elif echo "$ISSUE_JSON" | grep -qi '"name":"[^"]*refactor[^"]*"'; then
    PREFIX="refactor"
elif echo "$ISSUE_JSON" | grep -qi '"name":"[^"]*security[^"]*"'; then
    PREFIX="fix"
elif echo "$ISSUE_JSON" | grep -qi '"name":"[^"]*perf[^"]*"'; then
    PREFIX="perf"
fi

# Generate slug from title
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-+|-+$//g' | cut -c 1-35)
BRANCH_NAME="${PREFIX}/issue-${ISSUE_ID}-${SLUG}"

# Display formatted details
echo -e "\033[1;36m============================================================\033[0m"
echo -e "\033[1;32mGitSynk Task Ingested\033[0m: #$ISSUE_ID ($STATE)"
echo -e "\033[1;37mTitle\033[0m: $TITLE"
echo -e "\033[1;37mURL\033[0m: $URL"
echo -e "\033[1;37mSuggested Branch\033[0m: $BRANCH_NAME"
echo -e "\033[1;36m============================================================\033[0m"

# Print raw issue body for agent consumption
echo -e "\n\033[1;33m--- ISSUE BODY ---\033[0m"
gh issue view "$ISSUE_ID"
echo -e "\033[1;33m------------------\033[0m\n"

# Switch branch if requested
if [[ "$CHECKOUT_FLAG" == true ]]; then
    if git rev-parse --verify "$BRANCH_NAME" &>/dev/null; then
        echo "Branch '$BRANCH_NAME' already exists locally. Switching to it..."
        git checkout "$BRANCH_NAME"
    elif git rev-parse --verify "origin/$BRANCH_NAME" &>/dev/null; then
        echo "Tracking remote branch 'origin/$BRANCH_NAME'..."
        git checkout -b "$BRANCH_NAME" --track "origin/$BRANCH_NAME"
    else
        echo "Creating and switching to new branch '$BRANCH_NAME'..."
        git checkout -b "$BRANCH_NAME"
    fi
    echo -e "\033[1;32mActive Git Branch:\033[0m $(git rev-parse --abbrev-ref HEAD)"
fi
