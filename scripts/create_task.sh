#!/usr/bin/env bash
# ==============================================================================
# create_task.sh
# Create a Categorized GitHub Issue with Type and Priority Badges
# Part of GitSynk Autonomous Engineering Workflow
# ==============================================================================

set -euo pipefail

TITLE=""
TYPE="enhancement"
PRIORITY="regular"
BODY=""
BODY_FILE=""
EXTRA_LABELS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --title|-t)
            TITLE="$2"
            shift 2
            ;;
        --type)
            TYPE="$2"
            shift 2
            ;;
        --priority|-p)
            PRIORITY="$2"
            shift 2
            ;;
        --body|-b)
            BODY="$2"
            shift 2
            ;;
        --body-file|-f)
            BODY_FILE="$2"
            shift 2
            ;;
        --extra-labels|-l)
            EXTRA_LABELS="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$TITLE" ]]; then
    echo "Error: --title is required." >&2
    echo "Usage: $0 --title <title> [--type bug|enhancement] [--priority high|medium|regular] [--body <body> | --body-file <file>]" >&2
    exit 1
fi

if [[ -n "$BODY_FILE" ]] && [[ -f "$BODY_FILE" ]]; then
    BODY=$(cat "$BODY_FILE")
fi

if [[ -z "$BODY" ]]; then
    BODY="Issue automatically tracked and generated via GitSynk."
fi

# Normalize Type label
TYPE_LABEL="enhancement"
case "$TYPE" in
    *bug*|*Bug*|*fix*)
        TYPE_LABEL="bug"
        ;;
    *enhancement*|*feat*|*Feature*)
        TYPE_LABEL="enhancement"
        ;;
    *refactor*|*Refactor*)
        TYPE_LABEL="refactor"
        ;;
    *security*|*Security*)
        TYPE_LABEL="security"
        ;;
    *perf*|*Performance*)
        TYPE_LABEL="performance"
        ;;
esac

# Normalize Priority label and badge
PRIORITY_LABEL="🌱 Regular"
case "$PRIORITY" in
    *high*|*High*|*🚨*|*top*|*Top*|*critical*|*Critical*)
        PRIORITY_LABEL="🚨 High-Top"
        ;;
    *med*|*Med*|*⚡*|*moderate*)
        PRIORITY_LABEL="⚡ Medium"
        ;;
    *reg*|*Reg*|*🌱*|*low*|*Low*)
        PRIORITY_LABEL="🌱 Regular"
        ;;
esac

# Function to ensure a label exists in the repo
ensure_label() {
    local LABEL_NAME="$1"
    local LABEL_COLOR="$2"
    local LABEL_DESC="$3"
    
    # Check if label exists
    if ! gh label list --search "$LABEL_NAME" --json name -q ".[].name" 2>/dev/null | grep -Fxq "$LABEL_NAME"; then
        # Try creating it
        gh label create "$LABEL_NAME" --color "$LABEL_COLOR" --description "$LABEL_DESC" 2>/dev/null || true
    fi
}

# Ensure priority labels exist with appropriate colors
ensure_label "🚨 High-Top" "B60205" "Top priority critical tasks and bugs"
ensure_label "⚡ Medium" "FBCA04" "Medium priority tasks and improvements"
ensure_label "🌱 Regular" "0E8A16" "Regular priority tasks and maintenance"

# Build gh issue create arguments
GH_ARGS=(
    issue create
    --title "$TITLE"
    --body "$BODY"
    --label "$TYPE_LABEL"
    --label "$PRIORITY_LABEL"
)

if [[ -n "$EXTRA_LABELS" ]]; then
    IFS=',' read -ra ADDR <<< "$EXTRA_LABELS"
    for l in "${ADDR[@]}"; do
        clean_l=$(echo "$l" | xargs)
        if [[ -n "$clean_l" ]]; then
            GH_ARGS+=(--label "$clean_l")
        fi
    done
fi

# Execute issue creation
echo "Creating GitHub issue: '$TITLE' [$TYPE_LABEL] [$PRIORITY_LABEL]..."
ISSUE_URL=$(gh "${GH_ARGS[@]}")

echo -e "\033[1;32mIssue successfully created!\033[0m"
echo -e "URL: $ISSUE_URL"
echo "$ISSUE_URL"
