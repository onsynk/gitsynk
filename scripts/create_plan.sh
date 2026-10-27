#!/usr/bin/env bash
# ==============================================================================
# create_plan.sh
# Initialize a GitSynk Development Plan file at .onsynk/gitsynk/plans/*.text
# Part of GitSynk Autonomous Engineering Workflow
# ==============================================================================

set -euo pipefail

PLAN_DIR=".onsynk/gitsynk/plans"
mkdir -p "$PLAN_DIR"

PLAN_NAME="${1:-}"
if [[ -z "$PLAN_NAME" ]] || [[ "$PLAN_NAME" == "--default" ]]; then
    PLAN_NAME="plan"
fi

# Strip any leading path or trailing extension user may have passed
PLAN_BASENAME=$(basename "$PLAN_NAME" | sed -E 's/\.(text|txt|md)$//')
PLAN_FILE="${PLAN_DIR}/${PLAN_BASENAME}.text"

if [[ -f "$PLAN_FILE" ]]; then
    echo -e "\033[1;33m[gitsynk:plan]\033[0m Plan file already exists at: $PLAN_FILE"
    echo "$PLAN_FILE"
    exit 0
fi

cat << 'EOF' > "$PLAN_FILE"
# GitSynk Development Plan
# Location: .onsynk/gitsynk/plans/*.text

### [TASK-01] Example Task Title
- **Type**: enhancement
- **Priority**: 🌱 Regular
- **Scope**: core
- **Pillar**: Architecture & Code Quality
- **Target**: src/
- **Description**: Provide a clear problem statement and technical audit finding.
- **Proposed Solution**: Architectural steps to implement or resolve the task.
- **Acceptance Criteria**:
  - [ ] Implementation completed and verified
  - [ ] Quality tools and tests passing
EOF

echo -e "\033[1;32m[gitsynk:plan]\033[0m Created new plan file at: \033[1;34m$PLAN_FILE\033[0m"
echo "$PLAN_FILE"
