# GitSynk Plan Format Specification (`plan.txt`)

The `plan.txt` file defines the structured output generated during **Track 1: Universal Technical Audit & Planning**. It serves as both a human-readable engineering roadmap and a machine-parseable source of truth for the bulk GitHub issue creation engine (`scripts/parse_plan.sh`).

---

## 1. File Structure

Each task block is delineated by a `### [TASK-XX]` heading, followed by metadata key-value bullet points and an actionable markdown description.

```markdown
### [TASK-01] Brief Imperative Title of Task
- **Type**: bug | enhancement
- **Priority**: 🚨 High-Top | ⚡ Medium | 🌱 Regular
- **Scope**: component/domain-name
- **Pillar**: Critical Bugs & Runtime Safety | Performance Bottlenecks | Security & Concurrency | Architecture & Code Quality
- **Target**: path/to/file.ext or directory/path
- **Description**: Detailed explanation of the detected problem, vulnerability, or debt.
- **Proposed Solution**: Concrete steps and technical approach to resolve the item.
- **Acceptance Criteria**:
  - [ ] Specific condition 1 that must pass
  - [ ] Specific condition 2 that must pass
```

---

## 2. Field Definitions

| Field | Allowed Values / Format | Description |
| :--- | :--- | :--- |
| **Heading** | `### [TASK-XX] <Title>` | Unique task ID index and concise summary of the issue. |
| **Type** | `bug`, `enhancement` | GitHub issue type label mapping. |
| **Priority** | `🚨 High-Top`, `⚡ Medium`, `🌱 Regular` | Priority level badge. Affects issue labels and execution ordering. |
| **Scope** | E.g. `auth`, `api`, `db`, `checkout` | Subsystem or domain boundary affected. |
| **Pillar** | One of the 4 GitSynk audit pillars | Categorization pillar used in audit reporting. |
| **Target** | Relative file or directory path | Exact target path identified during audit. |
| **Description** | Freeform markdown text | Root cause analysis and impact description. |
| **Proposed Solution** | Freeform markdown text | Architectural or implementation steps required. |
| **Acceptance Criteria** | Markdown checklist | Testable definitions of done. |

---

## 3. The 4 Audit Pillars

1. **Critical Bugs & Runtime Safety**:
   - Null pointer dereferences, unhandled nil/None, unhandled edge cases, panic/crash vectors, missing error propagation, type coercion defects, memory leaks.
2. **Performance Bottlenecks**:
   - $N+1$ queries, missing database indices, blocking synchronous I/O in async runtimes, redundant re-renders, uncontrolled memory allocations, sub-optimal algorithmic complexity ($O(N^2) \to O(N)$).
3. **Security & Concurrency**:
   - Injection flaws (SQL, XSS, Command, Template), authentication/authorization bypasses, hardcoded secrets/tokens, insecure deserialization, race conditions, unsynchronized shared mutable state, deadlock risks.
4. **Architecture & Code Quality**:
   - SOLID principle violations, leaking domain boundaries, tight coupling, code duplication (DRY), missing unit/regression test coverage, high cyclomatic complexity, dead code.

---

## 4. Full Example `plan.txt`

```markdown
# GitSynk Technical Audit & Implementation Plan

### [TASK-01] Eliminate SQL Injection in User Lookup Query
- **Type**: bug
- **Priority**: 🚨 High-Top
- **Scope**: auth/repository
- **Pillar**: Security & Concurrency
- **Target**: src/Repositories/UserRepository.php
- **Description**: Raw user input from query parameters is concatenated directly into the PDO query string in `findByName()`, exposing the database to arbitrary SQL execution.
- **Proposed Solution**: Refactor `findByName` to use prepared statements with explicit parameter binding (`:username`).
- **Acceptance Criteria**:
  - [ ] All dynamic string interpolations removed from `findByName`.
  - [ ] Unit/Integration test added verifying inputs containing SQL injection syntax are safely escaped.

---

### [TASK-02] Fix N+1 Query in Order Invoice Generation
- **Type**: bug
- **Priority**: ⚡ Medium
- **Scope**: billing/invoicing
- **Pillar**: Performance Bottlenecks
- **Target**: src/Services/InvoiceService.php
- **Description**: Invoicing iterates over order line items and issues a separate database query for each item's tax classification, resulting in 50+ queries per bulk order.
- **Proposed Solution**: Eager-load tax classifications with the order payload or perform a single batched `WHERE IN` lookup.
- **Acceptance Criteria**:
  - [ ] Number of SQL queries per invoice batch reduced to a constant $O(1)$ query count.
  - [ ] Performance benchmark verifies <50ms execution on 1,000 items.

---

### [TASK-03] Introduce Domain Events for Payment Reconciliation
- **Type**: enhancement
- **Priority**: 🌱 Regular
- **Scope**: payments/events
- **Pillar**: Architecture & Code Quality
- **Target**: src/Domain/Payment/
- **Description**: Payment service directly mutates ledger and sends emails synchronously, violating single responsibility and making asynchronous queueing difficult.
- **Proposed Solution**: Emit a `PaymentReconciledEvent` and delegate ledger entries and notifications to asynchronous listeners.
- **Acceptance Criteria**:
  - [ ] `PaymentReconciledEvent` created and dispatched.
  - [ ] Email and accounting decoupled into independent event subscribers.
```
