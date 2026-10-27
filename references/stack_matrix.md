# GitSynk Universal Tech Stack & Verification Matrix

GitSynk dynamically interrogates the workspace to identify the runtime language, framework, package manager, code quality tools, and test suites.

---

## Supported Ecosystems

| Language / Stack | Configuration Fingerprint | Package Manager | Linters / Style Formatters | Test Runners & Suites |
| :--- | :--- | :--- | :--- | :--- |
| **PHP / Laravel** | `composer.json` | `composer` | `vendor/bin/pint --test`<br>`vendor/bin/phpstan analyse`<br>`vendor/bin/psalm`<br>`vendor/bin/phpcs` | `vendor/bin/pest`<br>`vendor/bin/phpunit`<br>`composer test` |
| **Node.js / TypeScript** | `package.json`<br>`tsconfig.json` | `pnpm` (`pnpm-lock.yaml`)<br>`yarn` (`yarn.lock`)<br>`bun` (`bun.lockb`)<br>`npm` (`package-lock.json`) | `npx eslint .`<br>`npx tsc --noEmit`<br>`npx prettier --check .` | `npm test`<br>`pnpm test`<br>`yarn test`<br>`bun test`<br>`npx jest`<br>`npx vitest run` |
| **Python** | `pyproject.toml`<br>`setup.py`<br>`requirements.txt`<br>`Pipfile` | `poetry`, `pip`, `pipenv`, `uv` | `ruff check .`<br>`flake8`<br>`black --check .`<br>`mypy .` | `pytest`<br>`python -m unittest discover` |
| **Rust** | `Cargo.toml` | `cargo` | `cargo clippy --all-targets -- -D warnings`<br>`cargo fmt -- --check` | `cargo test --all-targets` |
| **Go** | `go.mod` | `go` | `golangci-lint run`<br>`go vet ./...`<br>`gofmt -l .` | `go test -v -race ./...` |
| **Flutter / Dart** | `pubspec.yaml` | `flutter`, `dart` | `flutter analyze`<br>`dart analyze`<br>`dart format --output=none --set-exit-if-changed .` | `flutter test`<br>`dart test` |
| **Java / Kotlin** | `pom.xml`<br>`build.gradle`<br>`build.gradle.kts` | `mvn`, `gradle` | `mvn compile -DskipTests`<br>`./gradlew check` | `mvn test`<br>`./gradlew test` |
| **C# / .NET** | `*.sln`, `*.csproj` | `dotnet`, `nuget` | `dotnet format --verify-no-changes` | `dotnet test` |
| **Ruby** | `Gemfile` | `bundle` | `bundle exec rubocop` | `bundle exec rspec`<br>`bundle exec rake test` |

---

## Detection Precedence

When multiple configuration files are detected (e.g. monorepos or polyglot repositories), GitSynk follows these resolution rules:

1. **Target Subdirectory First**: If auditing or executing within a specific subdirectory (e.g., `client/` or `backend/`), detection runs within that scope first before falling back to repository root.
2. **Explicit Scripts Override**: In `package.json` or `composer.json`, standard script entries (`"test"`, `"lint"`, `"format"`) take priority over raw binary invocations.
3. **Lockfile Affinity**: The presence of lockfiles (`pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`, `poetry.lock`) dictates the package manager used to execute commands, ensuring deterministic dependency resolution.
