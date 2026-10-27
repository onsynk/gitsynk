#!/usr/bin/env bash
# ==============================================================================
# detect_quality_tools.sh
# Universal Language-Agnostic Quality & Verification Detection Engine
# Part of GitSynk Autonomous Engineering Workflow
# ==============================================================================

set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

DETECTED_STACK=""
LINT_CMD=""
TEST_CMD=""
FORMAT_CMD=""
TYPECHECK_CMD=""

log_info() {
    echo -e "\033[1;34m[gitsynk:detect]\033[0m $1"
}

log_success() {
    echo -e "\033[1;32m[gitsynk:detect]\033[0m $1"
}

log_warn() {
    echo -e "\033[1;33m[gitsynk:detect]\033[0m $1"
}

# ------------------------------------------------------------------------------
# 1. PHP / Composer Ecosystem
# ------------------------------------------------------------------------------
detect_php() {
    if [[ -f "composer.json" ]]; then
        DETECTED_STACK="PHP"
        
        # Test detection
        if [[ -x "vendor/bin/pest" ]] || grep -q '"pestphp/pest"' composer.json 2>/dev/null; then
            TEST_CMD="vendor/bin/pest"
        elif [[ -x "vendor/bin/phpunit" ]] || grep -q '"phpunit/phpunit"' composer.json 2>/dev/null; then
            TEST_CMD="vendor/bin/phpunit"
        elif grep -q '"test"' composer.json 2>/dev/null; then
            TEST_CMD="composer test"
        fi

        # Linter / Code Style detection
        if [[ -x "vendor/bin/pint" ]] || grep -q '"laravel/pint"' composer.json 2>/dev/null; then
            LINT_CMD="vendor/bin/pint --test"
            FORMAT_CMD="vendor/bin/pint"
        elif [[ -x "vendor/bin/phpstan" ]] || grep -q '"phpstan/phpstan"' composer.json 2>/dev/null; then
            TYPECHECK_CMD="vendor/bin/phpstan analyse"
        elif [[ -x "vendor/bin/psalm" ]]; then
            TYPECHECK_CMD="vendor/bin/psalm"
        elif [[ -x "vendor/bin/phpcs" ]]; then
            LINT_CMD="vendor/bin/phpcs"
        fi
        return 0
    fi
    return 1
}

# ------------------------------------------------------------------------------
# 2. Node.js / TypeScript / JavaScript Ecosystem
# ------------------------------------------------------------------------------
detect_node() {
    if [[ -f "package.json" ]]; then
        DETECTED_STACK="Node.js/JavaScript"
        local PKG_MANAGER="npm"
        if [[ -f "pnpm-lock.yaml" ]]; then
            PKG_MANAGER="pnpm"
        elif [[ -f "yarn.lock" ]]; then
            PKG_MANAGER="yarn"
        elif [[ -f "bun.lockb" ]] || [[ -f "bun.lock" ]]; then
            PKG_MANAGER="bun"
        fi

        if [[ -f "tsconfig.json" ]]; then
            DETECTED_STACK="Node.js/TypeScript"
            TYPECHECK_CMD="npx tsc --noEmit"
        fi

        # Check scripts in package.json
        if grep -q '"lint"' package.json 2>/dev/null; then
            LINT_CMD="$PKG_MANAGER run lint"
        elif [[ -f ".eslintrc" ]] || [[ -f ".eslintrc.js" ]] || [[ -f ".eslintrc.json" ]] || [[ -f "eslint.config.js" ]] || [[ -f "eslint.config.mjs" ]]; then
            LINT_CMD="npx eslint ."
        fi

        if grep -q '"test"' package.json 2>/dev/null; then
            TEST_CMD="$PKG_MANAGER test"
        fi

        if grep -q '"format:check"' package.json 2>/dev/null; then
            FORMAT_CMD="$PKG_MANAGER run format:check"
        elif [[ -f ".prettierrc" ]] || [[ -f "prettier.config.js" ]]; then
            FORMAT_CMD="npx prettier --check ."
        fi
        return 0
    fi
    return 1
}

# ------------------------------------------------------------------------------
# 3. Python Ecosystem
# ------------------------------------------------------------------------------
detect_python() {
    if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]] || [[ -f "Pipfile" ]]; then
        DETECTED_STACK="Python"

        # Linter detection (ruff > flake8 > black)
        if command -v ruff &>/dev/null; then
            LINT_CMD="ruff check ."
            FORMAT_CMD="ruff format --check ."
        elif command -v flake8 &>/dev/null; then
            LINT_CMD="flake8"
        fi

        if command -v mypy &>/dev/null; then
            TYPECHECK_CMD="mypy ."
        fi

        # Test detection (pytest > unittest)
        if command -v pytest &>/dev/null; then
            TEST_CMD="pytest"
        else
            TEST_CMD="python -m unittest discover"
        fi
        return 0
    fi
    return 1
}

# ------------------------------------------------------------------------------
# 4. Rust Ecosystem
# ------------------------------------------------------------------------------
detect_rust() {
    if [[ -f "Cargo.toml" ]]; then
        DETECTED_STACK="Rust"
        LINT_CMD="cargo clippy --all-targets --all-features -- -D warnings"
        FORMAT_CMD="cargo fmt -- --check"
        TEST_CMD="cargo test --all-targets"
        return 0
    fi
    return 1
}

# ------------------------------------------------------------------------------
# 5. Go Ecosystem
# ------------------------------------------------------------------------------
detect_go() {
    if [[ -f "go.mod" ]]; then
        DETECTED_STACK="Go"
        if command -v golangci-lint &>/dev/null; then
            LINT_CMD="golangci-lint run"
        else
            LINT_CMD="go vet ./..."
        fi
        TEST_CMD="go test -v -race ./..."
        FORMAT_CMD="gofmt -l ."
        return 0
    fi
    return 1
}

# ------------------------------------------------------------------------------
# 6. Flutter & Dart Ecosystem
# ------------------------------------------------------------------------------
detect_flutter() {
    if [[ -f "pubspec.yaml" ]]; then
        if grep -q "flutter:" pubspec.yaml 2>/dev/null; then
            DETECTED_STACK="Flutter"
            LINT_CMD="flutter analyze"
            TEST_CMD="flutter test"
        else
            DETECTED_STACK="Dart"
            LINT_CMD="dart analyze"
            TEST_CMD="dart test"
        fi
        FORMAT_CMD="dart format --output=none --set-exit-if-changed ."
        return 0
    fi
    return 1
}

# ------------------------------------------------------------------------------
# 7. Java / Kotlin Ecosystem
# ------------------------------------------------------------------------------
detect_java() {
    if [[ -f "pom.xml" ]]; then
        DETECTED_STACK="Java (Maven)"
        TEST_CMD="mvn test"
        LINT_CMD="mvn compile -DskipTests"
        return 0
    elif [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
        DETECTED_STACK="Java/Kotlin (Gradle)"
        local GRADLE="./gradlew"
        if [[ ! -x "$GRADLE" ]] && [[ ! -f "$GRADLE" ]]; then
            GRADLE="gradle"
        fi
        TEST_CMD="$GRADLE test"
        LINT_CMD="$GRADLE check"
        return 0
    fi
    return 1
}

# ------------------------------------------------------------------------------
# 8. C# / .NET Ecosystem
# ------------------------------------------------------------------------------
detect_dotnet() {
    local SLN_COUNT
    SLN_COUNT=$(find . -maxdepth 2 -name "*.sln" -o -name "*.csproj" 2>/dev/null | wc -l)
    if [[ "$SLN_COUNT" -gt 0 ]]; then
        DETECTED_STACK=".NET / C#"
        TEST_CMD="dotnet test"
        LINT_CMD="dotnet format --verify-no-changes"
        return 0
    fi
    return 1
}

# ------------------------------------------------------------------------------
# 9. Ruby Ecosystem
# ------------------------------------------------------------------------------
detect_ruby() {
    if [[ -f "Gemfile" ]]; then
        DETECTED_STACK="Ruby"
        if grep -q "rubocop" Gemfile 2>/dev/null; then
            LINT_CMD="bundle exec rubocop"
        fi
        if grep -q "rspec" Gemfile 2>/dev/null; then
            TEST_CMD="bundle exec rspec"
        else
            TEST_CMD="bundle exec rake test"
        fi
        return 0
    fi
    return 1
}

# Run detection in priority order
detect_rust || detect_go || detect_flutter || detect_php || detect_node || detect_python || detect_java || detect_dotnet || detect_ruby || true

# Execution modes
MODE="${2:---detect}"

case "$MODE" in
    --detect)
        echo "{"
        echo "  \"stack\": \"${DETECTED_STACK:-Unknown}\","
        echo "  \"test_command\": \"${TEST_CMD}\","
        echo "  \"lint_command\": \"${LINT_CMD}\","
        echo "  \"format_command\": \"${FORMAT_CMD}\","
        echo "  \"typecheck_command\": \"${TYPECHECK_CMD}\""
        echo "}"
        ;;
    --lint)
        if [[ -n "$LINT_CMD" ]]; then
            log_info "Running detected linter: $LINT_CMD"
            eval "$LINT_CMD"
        fi
        if [[ -n "$TYPECHECK_CMD" ]]; then
            log_info "Running detected typechecker: $TYPECHECK_CMD"
            eval "$TYPECHECK_CMD"
        fi
        if [[ -z "$LINT_CMD" ]] && [[ -z "$TYPECHECK_CMD" ]]; then
            log_warn "No linter or typechecker detected for stack: ${DETECTED_STACK:-Unknown}"
        fi
        ;;
    --test)
        if [[ -n "$TEST_CMD" ]]; then
            log_info "Running detected test runner: $TEST_CMD"
            eval "$TEST_CMD"
        else
            log_warn "No test runner detected for stack: ${DETECTED_STACK:-Unknown}"
        fi
        ;;
    --all)
        if [[ -n "$LINT_CMD" ]]; then
            log_info "Running linter: $LINT_CMD"
            eval "$LINT_CMD"
        fi
        if [[ -n "$TYPECHECK_CMD" ]]; then
            log_info "Running typechecker: $TYPECHECK_CMD"
            eval "$TYPECHECK_CMD"
        fi
        if [[ -n "$TEST_CMD" ]]; then
            log_info "Running test runner: $TEST_CMD"
            eval "$TEST_CMD"
        fi
        log_success "Quality verification suite completed."
        ;;
    *)
        echo "Usage: $0 [target_dir] [--detect|--lint|--test|--all]"
        exit 1
        ;;
esac
