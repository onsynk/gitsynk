#!/usr/bin/env bash
# ==============================================================================
# parse_plan.sh
# Ingest and Parse .onsynk/gitsynk/plans/*.text to Bulk-Create GitHub Issues
# Part of GitSynk Autonomous Engineering Workflow
# ==============================================================================

set -euo pipefail

PLAN_FILE=""
MODE="--preview"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --help|-h)
            echo "Usage: $0 [path_to_plan.text] [--preview|--execute]"
            echo ""
            echo "Plans are located at: .onsynk/gitsynk/plans/*.text"
            echo ""
            echo "Modes:"
            echo "  --preview  (Default) Validate and print parsed tasks without creating GitHub issues."
            echo "  --execute  Create GitHub issues in bulk using 'gh issue create'."
            exit 0
            ;;
        --preview)
            MODE="--preview"
            ;;
        --execute)
            MODE="--execute"
            ;;
        *)
            if [[ -z "$PLAN_FILE" ]]; then
                PLAN_FILE="$arg"
            fi
            ;;
    esac
done

# If no specific plan file was passed, auto-discover in .onsynk/gitsynk/plans/*.text
if [[ -z "$PLAN_FILE" ]]; then
    PLANS_DIR=".onsynk/gitsynk/plans"
    if [[ -d "$PLANS_DIR" ]]; then
        # Find latest modified .text file in .onsynk/gitsynk/plans/
        LATEST_PLAN=$(find "$PLANS_DIR" -maxdepth 1 -name "*.text" -o -name "*.txt" 2>/dev/null | head -n 1)
        if [[ -n "$LATEST_PLAN" ]]; then
            PLAN_FILE="$LATEST_PLAN"
        fi
    fi
fi

# Fallback check for root files if still empty
if [[ -z "$PLAN_FILE" ]]; then
    if [[ -f "plan.text" ]]; then
        PLAN_FILE="plan.text"
    elif [[ -f "plan.txt" ]]; then
        PLAN_FILE="plan.txt"
    else
        PLAN_FILE=".onsynk/gitsynk/plans/plan.text"
    fi
fi

if [[ ! -f "$PLAN_FILE" ]]; then
    echo "Error: Plan file '$PLAN_FILE' not found." >&2
    echo "Tip: Run 'bash scripts/create_plan.sh [name]' to create a new plan in .onsynk/gitsynk/plans/*.text" >&2
    exit 1
fi

echo -e "\033[1;36m============================================================\033[0m"
echo -e "\033[1;34mGitSynk Plan Parser\033[0m: Reading $PLAN_FILE"
echo -e "Mode: \033[1;33m$MODE\033[0m"
echo -e "\033[1;36m============================================================\033[0m"

# Parse structured tasks from plan file
TASK_COUNT=0
CURRENT_TITLE=""
CURRENT_TYPE="enhancement"
CURRENT_PRIORITY="🌱 Regular"
CURRENT_SCOPE=""
CURRENT_PILLAR=""
CURRENT_TARGET=""
CURRENT_BODY=""
IN_TASK=false

process_task() {
    if [[ -z "$CURRENT_TITLE" ]]; then
        return
    fi
    TASK_COUNT=$((TASK_COUNT + 1))
    
    echo -e "\n\033[1;32m[Task #$TASK_COUNT]\033[0m $CURRENT_TITLE"
    echo -e "  Type:      \033[1;37m$CURRENT_TYPE\033[0m"
    echo -e "  Priority:  \033[1;37m$CURRENT_PRIORITY\033[0m"
    if [[ -n "$CURRENT_SCOPE" ]]; then echo -e "  Scope:     \033[1;37m$CURRENT_SCOPE\033[0m"; fi
    if [[ -n "$CURRENT_PILLAR" ]]; then echo -e "  Pillar:    \033[1;37m$CURRENT_PILLAR\033[0m"; fi
    if [[ -n "$CURRENT_TARGET" ]]; then echo -e "  Target:    \033[1;37m$CURRENT_TARGET\033[0m"; fi
    
    if [[ "$MODE" == "--execute" ]]; then
        FULL_BODY="## GitSynk Task Summary
- **Pillar**: ${CURRENT_PILLAR:-Unspecified}
- **Scope**: ${CURRENT_SCOPE:-General}
- **Target**: \`${CURRENT_TARGET:-Codebase}\`
- **Priority**: ${CURRENT_PRIORITY}
- **Type**: ${CURRENT_TYPE}

---

### Description & Action Plan
${CURRENT_BODY}

---
*Created autonomously via [GitSynk](https://github.com/)*"

        "$SCRIPT_DIR/create_task.sh" \
            --title "$CURRENT_TITLE" \
            --type "$CURRENT_TYPE" \
            --priority "$CURRENT_PRIORITY" \
            --body "$FULL_BODY" || echo "Warning: Failed to create issue for: $CURRENT_TITLE"
    fi
}

while IFS= read -r line || [[ -n "$line" ]]; do
    # Detect start of new task
    if [[ "$line" =~ ^###?[[:space:]]*\[?TASK ]]; then
        if [[ "$IN_TASK" == true ]]; then
            process_task
        fi
        IN_TASK=true
        CURRENT_TITLE=$(echo "$line" | sed -E 's/^###?[[:space:]]*\[?TASK[^]]*\]?:?[[:space:]]*//')
        CURRENT_TYPE="enhancement"
        CURRENT_PRIORITY="🌱 Regular"
        CURRENT_SCOPE=""
        CURRENT_PILLAR=""
        CURRENT_TARGET=""
        CURRENT_BODY=""
        continue
    fi

    if [[ "$IN_TASK" == true ]]; then
        if [[ "$line" =~ ^-[[:space:]]*\*\*Type\*\*:[[:space:]]*(.*) ]]; then
            CURRENT_TYPE="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^-[[:space:]]*\*\*Priority\*\*:[[:space:]]*(.*) ]]; then
            CURRENT_PRIORITY="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^-[[:space:]]*\*\*Scope\*\*:[[:space:]]*(.*) ]]; then
            CURRENT_SCOPE="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^-[[:space:]]*\*\*Pillar\*\*:[[:space:]]*(.*) ]]; then
            CURRENT_PILLAR="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^-[[:space:]]*\*\*Target\*\*:[[:space:]]*(.*) ]]; then
            CURRENT_TARGET="${BASH_REMATCH[1]}"
        else
            CURRENT_BODY="${CURRENT_BODY}
${line}"
        fi
    fi
done < "$PLAN_FILE"

# Process final task
if [[ "$IN_TASK" == true ]]; then
    process_task
fi

echo -e "\n\033[1;36m============================================================\033[0m"
echo -e "\033[1;32mTotal tasks processed:\033[0m $TASK_COUNT"
if [[ "$MODE" == "--preview" ]]; then
    echo -e "\033[1;33mTip: Run with '--execute' to create these issues in GitHub.\033[0m"
fi
echo -e "\033[1;36m============================================================\033[0m"
