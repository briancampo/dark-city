#!/usr/bin/env bash
# scripts/gh-issue-ops.sh
# Dark Factory GitHub Issue, Hierarchy, and Project Operations Utility
# Comprehensive tool for Epic/Story/Task creation, Brief scaffolding, Sub-issue linking, and Project metadata management.

set -e
trap 'echo -e "\n🚨 Error occurred on line $LINENO. Agent/User: Please review the output above to diagnose the issue." >&2' ERR

# --- Color Formatting ---
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Root Discovery ---
get_project_root() {
    PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
}

get_project_root

# --- Load Configuration ---
if [ -f "$PROJECT_ROOT/.agent/config.env" ]; then
    # shellcheck disable=SC1091
    source "$PROJECT_ROOT/.agent/config.env"
elif [ -f "$PROJECT_ROOT/scripts/config.env" ]; then
    # shellcheck disable=SC1091
    source "$PROJECT_ROOT/scripts/config.env"
fi

detect_repo_info() {
    if [ -z "$REPO_NAME_WITH_OWNER" ]; then
        REPO_NAME_WITH_OWNER=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)
        if [ -z "$REPO_NAME_WITH_OWNER" ]; then
            local remote_url
            remote_url=$(git config --get remote.origin.url 2>/dev/null || true)
            if [[ "$remote_url" =~ [:pop:]([^\/:]+\/[^\/\.]+)(\.git)?$ ]]; then
                REPO_NAME_WITH_OWNER="${BASH_REMATCH[1]}"
            else
                REPO_NAME_WITH_OWNER="Mindstar-Studio/dark-city"
            fi
        fi
    fi
    REPO_OWNER="${REPO_NAME_WITH_OWNER%/*}"
    REPO_NAME="${REPO_NAME_WITH_OWNER#*/}"
}

detect_repo_info

# Project and workflow defaults
GH_PROJECT_OWNER="${GH_PROJECT_OWNER:-$REPO_OWNER}"
GH_PROJECT_NUMBER="${GH_PROJECT_NUMBER:-2}"
GH_PROJECT_ID="${GH_PROJECT_ID:-}"

# Discover worktrees directory
get_worktree_base_dir() {
    local common_root=""
    local git_common
    git_common=$(git rev-parse --git-common-dir 2>/dev/null || true)
    if [ -n "$git_common" ]; then
        common_root=$(cd "$git_common/.." && pwd -P)
    else
        common_root="$PROJECT_ROOT"
    fi

    if [ -n "$WORKTREES_DIR" ]; then
        WORKTREE_BASE="$WORKTREES_DIR"
    elif [ -d "$(dirname "$common_root")/worktrees/${REPO_NAME:-dark-city}" ]; then
        WORKTREE_BASE="$(dirname "$common_root")/worktrees/${REPO_NAME:-dark-city}"
    elif [ -d "$(dirname "$common_root")/worktrees" ]; then
        WORKTREE_BASE="$(dirname "$common_root")/worktrees/${REPO_NAME:-dark-city}"
    elif [ -d "$(dirname "$PROJECT_ROOT")/worktrees/${REPO_NAME:-dark-city}" ]; then
        WORKTREE_BASE="$(dirname "$PROJECT_ROOT")/worktrees/${REPO_NAME:-dark-city}"
    else
        WORKTREE_BASE="$PROJECT_ROOT/.worktrees"
    fi
}

get_worktree_base_dir

# --- Helper: Resolve Project Metadata Fields Dynamically ---
resolve_project_fields() {
    PROJECT_FIELDS_JSON=$(gh project field-list "$GH_PROJECT_NUMBER" --owner "$GH_PROJECT_OWNER" --format json 2>/dev/null || true)
    if [ -z "$PROJECT_FIELDS_JSON" ] || [ "$PROJECT_FIELDS_JSON" = "null" ]; then
        HAS_PROJECT_CONFIG=false
        return 0
    fi
    HAS_PROJECT_CONFIG=true

    # Extract Project ID if not set
    if [ -z "$GH_PROJECT_ID" ]; then
        GH_PROJECT_ID=$(gh project view "$GH_PROJECT_NUMBER" --owner "$GH_PROJECT_OWNER" --format json --jq .id 2>/dev/null || true)
    fi
}

# --- Helper: Resolve Item ID for an Issue on Project Board ---
ensure_project_item() {
    local issue_num="$1"
    local issue_url="$2"

    resolve_project_fields
    if [ "$HAS_PROJECT_CONFIG" != true ]; then
        PROJECT_ITEM_ID=""
        return 0
    fi

    local item_list
    item_list=$(gh project item-list "$GH_PROJECT_NUMBER" --owner "$GH_PROJECT_OWNER" --format json -L 1000 2>/dev/null || true)
    
    PROJECT_ITEM_ID=$(echo "$item_list" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    items = d.get("items", [])
    it = next((i for i in items if isinstance(i, dict) and i.get("content", {}).get("number") == int("'"$issue_num"'")), None)
    if it: print(it.get("id", ""))
except Exception: pass
')

    # If not on project board, add it
    if [ -z "$PROJECT_ITEM_ID" ] && [ -n "$issue_url" ]; then
        echo -e "${BLUE}Adding issue #$issue_num to Project #$GH_PROJECT_NUMBER (${GH_PROJECT_OWNER})...${NC}"
        local add_resp
        add_resp=$(gh project item-add "$GH_PROJECT_NUMBER" --owner "$GH_PROJECT_OWNER" --url "$issue_url" --format json 2>/dev/null || true)
        PROJECT_ITEM_ID=$(echo "$add_resp" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get("id", ""))
except Exception: pass
')
    fi
}

# --- Helper: Apply Project Item Metadata Dynamically ---
set_project_metadata() {
    local item_id="$1"
    local status="${2:-}"
    local priority="${3:-}"
    local size="${4:-}"
    local estimate="${5:-}"
    local iteration_name_or_id="${6:-}"

    if [ -z "$item_id" ] || [ "$HAS_PROJECT_CONFIG" != true ] || [ -z "$GH_PROJECT_ID" ]; then
        return 0
    fi

    # 1. Set Status
    if [ -n "$status" ] && [ "$status" != "null" ]; then
        local status_field_id status_opt_id
        read -r status_field_id status_opt_id <<< "$(echo "$PROJECT_FIELDS_JSON" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    fields = d.get("fields", [])
    f = next((x for x in fields if x.get("name") == "Status"), None)
    if f:
        fid = f.get("id", "")
        opts = f.get("options", [])
        opt = next((o for o in opts if o.get("name", "").lower() == "'"$status"'".lower()), None)
        oid = opt.get("id", "") if opt else ""
        print(f"{fid} {oid}")
except Exception: pass
')"
        if [ -n "$status_field_id" ] && [ -n "$status_opt_id" ]; then
            echo "Setting Status to '$status'..."
            gh project item-edit --id "$item_id" --project-id "$GH_PROJECT_ID" --field-id "$status_field_id" --single-select-option-id "$status_opt_id" >/dev/null 2>&1 || true
        fi
    fi

    # 2. Set Priority
    if [ -n "$priority" ] && [ "$priority" != "null" ]; then
        local priority_field_id priority_opt_id
        read -r priority_field_id priority_opt_id <<< "$(echo "$PROJECT_FIELDS_JSON" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    fields = d.get("fields", [])
    f = next((x for x in fields if x.get("name") == "Priority"), None)
    if f:
        fid = f.get("id", "")
        opts = f.get("options", [])
        opt = next((o for o in opts if o.get("name", "").lower() == "'"$priority"'".lower()), None)
        oid = opt.get("id", "") if opt else ""
        print(f"{fid} {oid}")
except Exception: pass
')"
        if [ -n "$priority_field_id" ] && [ -n "$priority_opt_id" ]; then
            echo "Setting Priority to '$priority'..."
            gh project item-edit --id "$item_id" --project-id "$GH_PROJECT_ID" --field-id "$priority_field_id" --single-select-option-id "$priority_opt_id" >/dev/null 2>&1 || true
        fi
    fi

    # 3. Set Size
    if [ -n "$size" ] && [ "$size" != "null" ]; then
        local size_field_id size_opt_id
        read -r size_field_id size_opt_id <<< "$(echo "$PROJECT_FIELDS_JSON" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    fields = d.get("fields", [])
    f = next((x for x in fields if x.get("name") == "Size"), None)
    if f:
        fid = f.get("id", "")
        opts = f.get("options", [])
        opt = next((o for o in opts if o.get("name", "").lower() == "'"$size"'".lower()), None)
        oid = opt.get("id", "") if opt else ""
        print(f"{fid} {oid}")
except Exception: pass
')"
        if [ -n "$size_field_id" ] && [ -n "$size_opt_id" ]; then
            echo "Setting Size to '$size'..."
            gh project item-edit --id "$item_id" --project-id "$GH_PROJECT_ID" --field-id "$size_field_id" --single-select-option-id "$size_opt_id" >/dev/null 2>&1 || true
        fi
    fi

    # 4. Set Estimate
    if [ -n "$estimate" ] && [ "$estimate" != "null" ]; then
        local est_field_id
        est_field_id=$(echo "$PROJECT_FIELDS_JSON" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    fields = d.get("fields", [])
    f = next((x for x in fields if x.get("name") == "Estimate"), None)
    if f: print(f.get("id", ""))
except Exception: pass
')
        if [ -n "$est_field_id" ]; then
            echo "Setting Estimate to $estimate..."
            gh project item-edit --id "$item_id" --project-id "$GH_PROJECT_ID" --field-id "$est_field_id" --number "$estimate" >/dev/null 2>&1 || true
        fi
    fi

    # 5. Set Iteration
    if [ -n "$iteration_name_or_id" ] && [ "$iteration_name_or_id" != "null" ]; then
        local iter_field_id iter_opt_id
        read -r iter_field_id iter_opt_id <<< "$(echo "$PROJECT_FIELDS_JSON" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    fields = d.get("fields", [])
    f = next((x for x in fields if x.get("name") == "Iteration"), None)
    if f:
        fid = f.get("id", "")
        iters = f.get("configuration", {}).get("iterations", [])
        # Match by id or title
        it = next((i for i in iters if i.get("id") == "'"$iteration_name_or_id"'" or i.get("title", "").lower() == "'"$iteration_name_or_id"'".lower()), None)
        iid = it.get("id", "") if it else "'"$iteration_name_or_id"'"
        print(f"{fid} {iid}")
except Exception: pass
')"
        if [ -n "$iter_field_id" ] && [ -n "$iter_opt_id" ]; then
            echo "Setting Iteration to '$iteration_name_or_id'..."
            gh project item-edit --id "$item_id" --project-id "$GH_PROJECT_ID" --field-id "$iter_field_id" --iteration-id "$iter_opt_id" >/dev/null 2>&1 || true
        fi
    fi
}

# --- Helper: Sub-Issue Linking via GitHub REST API ---
link_sub_issue() {
    local parent_num="$1"
    local child_num="$2"

    if [ -z "$parent_num" ] || [ -z "$child_num" ]; then
        echo -e "${RED}Error: Parent issue and child issue numbers are required.${NC}" >&2
        echo "Usage: $0 link <parent_num> <child_num>" >&2
        return 1
    fi

    echo -e "${BLUE}Linking issue #$child_num as sub-issue of #$parent_num in $REPO_NAME_WITH_OWNER...${NC}"
    
    # Fetch child issue database ID
    local child_db_id
    child_db_id=$(gh api "repos/$REPO_NAME_WITH_OWNER/issues/$child_num" --jq '.id' 2>/dev/null || true)
    if [ -z "$child_db_id" ] || [ "$child_db_id" = "null" ]; then
        echo -e "${RED}Error: Could not retrieve GitHub Database ID for issue #$child_num.${NC}" >&2
        return 1
    fi

    if gh api --method POST "/repos/$REPO_NAME_WITH_OWNER/issues/$parent_num/sub_issues" -f sub_issue_id="$child_db_id" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Successfully linked #$child_num under parent #$parent_num.${NC}"
    else
        echo -e "${YELLOW}Warning: Sub-issue API returned a non-zero status. The sub-issue may already be linked or repository does not have sub-issues enabled.${NC}"
    fi
}

# --- Helper: Parse Story Details from Backlog Markdown ---
parse_backlog_story() {
    local target_id="$1"
    local backlog_file="$PROJECT_ROOT/docs/backlog.md"

    if [ ! -f "$backlog_file" ]; then
        echo -e "${RED}Error: Backlog file not found at $backlog_file.${NC}" >&2
        return 1
    fi

    STORY_DATA_JSON=$(python3 -c '
import sys, re, json

target = "'"$target_id"'".strip("[]# ")
backlog_path = "'"$backlog_file"'"

with open(backlog_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

current_epic_id = ""
current_epic_title = ""
found = None

for line in lines:
    epic_match = re.match(r"^###\s+Epic\s+([0-9]+\.[0-9]+)\s+—\s+(.*)", line.strip())
    if epic_match:
        current_epic_id = epic_match.group(1).strip()
        current_epic_title = epic_match.group(2).strip()
        continue

    if "|" in line:
        parts = [p.strip() for p in line.split("|") if p.strip()]
        if len(parts) >= 6:
            row_id = parts[0].strip("` ")
            if row_id == target:
                found = {
                    "id": row_id,
                    "title": parts[1].strip("` "),
                    "goal": parts[2].strip("` "),
                    "acceptance": parts[3].strip("` "),
                    "blueprint": parts[4].strip("` "),
                    "est": parts[5].strip("` "),
                    "owner": parts[6].strip("` ") if len(parts) > 6 else "System Architect",
                    "depends": parts[7].strip("` ") if len(parts) > 7 else "-",
                    "epic_id": current_epic_id,
                    "epic_title": current_epic_title
                }
                break

if not found:
    import subprocess
    try:
        res = subprocess.run(["gh", "issue", "view", target, "--json", "number,title,body,labels,assignees"], capture_output=True, text=True)
        if res.returncode == 0 and res.stdout:
            gh_data = json.loads(res.stdout)
            assignees = [a.get("login", "") for a in gh_data.get("assignees", [])]
            owner_role = "Steward"
            if assignees:
                owner_role = assignees[0]
            found = {
                "id": str(gh_data.get("number", target)),
                "title": gh_data.get("title", f"Issue #{target}"),
                "goal": gh_data.get("body", "").split("\n")[0] if gh_data.get("body") else "",
                "acceptance": "Verify all acceptance criteria in issue body.",
                "blueprint": "N/A",
                "est": "1",
                "owner": owner_role,
                "depends": "-",
                "epic_id": "N/A",
                "epic_title": "General Task / Process Improvement"
            }
    except Exception:
        pass

if found:
    print(json.dumps(found))
else:
    sys.exit(1)
' 2>/dev/null || true)

    if [ -z "$STORY_DATA_JSON" ]; then
        echo -e "${RED}Error: Story ID or Issue '$target_id' not found in $backlog_file or GitHub.${NC}" >&2
        return 1
    fi
}

# --- Command: Scaffold Mission Brief / Issue Body File ---
scaffold_brief() {
    local story_id="$1"
    local custom_out="$2"

    if [ -z "$story_id" ]; then
        echo -e "${RED}Error: Story ID is required (e.g. $0 scaffold-brief 1.1.2).${NC}" >&2
        return 1
    fi

    parse_backlog_story "$story_id"
    get_worktree_base_dir

    local out_file="$custom_out"
    if [ -z "$out_file" ]; then
        mkdir -p "$PROJECT_ROOT/working/briefs"
        out_file="$PROJECT_ROOT/working/briefs/${story_id}-brief.md"
    fi

    python3 - "$STORY_DATA_JSON" "$WORKTREE_BASE" "$GH_PROJECT_OWNER" "$GH_PROJECT_NUMBER" "$out_file" << 'EOF'
import sys, json, re

data = json.loads(sys.argv[1])
wt_base = sys.argv[2]
proj_owner = sys.argv[3]
proj_num = sys.argv[4]
out_file = sys.argv[5]

sid = data["id"]
title = data["title"]
goal = data["goal"]
acc = data["acceptance"]
bp = data["blueprint"]
est = data["est"]
owner = data["owner"]
depends = data.get("depends", "-")
epic_id = data["epic_id"]
epic_title = data["epic_title"]

slug_text = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")
branch = f"{sid}-{slug_text}"
wt_path = f"{wt_base}/{branch}/"

out_content = f"""# Dark Factory Mission Brief: Ticket [{sid}]

> [!IMPORTANT]
> **MISSION BRIEF SCAFFOLDING NOTICE:**
> This document was automatically scaffolded as an initial baseline. Before dispatching to the implementing developer agent, the **Steward** (process, scope, dependencies) and **Tech Lead** (architecture, design patterns, testing standards) MUST review and enrich this brief with contextually aware, technically comprehensive guidance.

**Dispatched Role:** {owner}
**Technical Reviewer / Lead:** Tech Lead
**Process Reviewer / Gate:** Steward
**Sprint / Epic:** Epic {epic_id} — {epic_title}
**Assigned Ticket:** `[{sid}] {title}`
**GitHub Task Issue:** [Pending creation]
**GitHub Project:** [DC Board (Project #{proj_num})](https://github.com/orgs/{proj_owner}/projects/{proj_num})
**Assigned Worktree Path:** `{wt_path}`
**Assigned Git Branch:** `{branch}`

---

## 1. Context & Current Baseline

The Dark Factory team is executing **Epic {epic_id} ({epic_title})**:
- **Workspace Architecture:** Cargo workspace with member crates and xtask.
- **Dual-Gate Governance:** The Dual-Gate PR process is in effect ([Team Charter §7](../../docs/project-charter.md#7-definition-of-done-pr-dual-gate)).
- **Worktree Isolation:** You must execute all work exclusively inside `{wt_path}`.

### Relevant Blueprint & Design Foundations
- **World Blueprint Reference:** {bp}
- **Relevant Architecture Decisions (ADRs):** [Search `/decisions/` for active records applicable to this ticket]
- **Target Crates & Directories:** [e.g. `crates/dark_city_core/`, `crates/dark_city_server/`, etc.]

---

## 2. Dispatched Scope & Acceptance Criteria

### Ticket [{sid}] {title}
- **Role:** {owner}
- **Dependencies:** {depends}
- **Estimate / Complexity:** {est} points
- **Goal:**
  > {goal}
- **Gherkin Acceptance Criteria:**
  - {acc}

---

## 3. Technical Implementation Guidance & Design Invariants

<!-- 
TECH LEAD & STEWARD ENRICHMENT SECTION:
Flesh out concrete implementation notes, patterns to follow, and pitfalls to avoid before dispatching.
-->

### Architecture & Design Pattern Alignment
- **Domain Layering & Ownership:** Adhere strictly to crate boundaries ([Team Charter §3.1](../../docs/project-charter.md#3-team-structure)). Avoid leaking internal state or introducing cross-boundary coupling without an RFC.
- **Config-over-Constants:** Do not hardcode magic numbers, spatial dimensions, or prompt parameters. Read from configuration structures or scenario seeds.
- **No Speculative Generality:** Build only what is required to fulfill the acceptance criteria.

### Concurrency & Thread Safety Constraints
- **Bevy Main Schedule Safety:** Never execute blocking I/O, synchronous DB queries, or synchronous HTTP inference calls on the main Bevy schedule.
- **Async Offloading:** Use `AsyncComputeTaskPool` or dedicated background channels for async tasks crossing into ECS systems.
- **Multi-Tenant Scoping:** Ensure all database queries, event emissions, and spatial queries are partitioned by `world_id` ([Decision 0003](../../decisions/0003-multi-tenant-world-instances.md)).

### Error Handling & Invariants
- Use explicit domain `Result<T, DomainError>` types; avoid naked `unwrap()` or `expect()` in production paths.
- Preserve consistent error variants in `dark_city_core`.

---

## 4. Test Strategy & Quality Verification

<!-- 
TECH LEAD ENRICHMENT SECTION:
Outline required test coverage, failure modes to test, and non-vacuous assertion expectations.
-->

- **Test Integrity Standard:** Tests must provide genuine regression protection. Vacuous assertions (e.g. merely checking `is_ok()` without verifying resulting state mutations) are unacceptable.
- **Required Coverage:**
  - [ ] Unit tests covering core logic, state transitions, and calculation functions.
  - [ ] Negative tests covering invalid inputs, energy exhaustion, location denial, or boundary errors.
  - [ ] Integration tests verifying DB/WebSocket/ECS interactions where applicable.
- **Pre-PR Verification Commands:**
  ```bash
  cargo fmt --check
  cargo clippy --all-targets -- -D warnings
  cargo nextest run
  cargo xtask check
  ```

---

## 5. Session Completion Requirements

When implementation is complete:
1. **Work Log Entry:** Append a high-level summary of work and key discoveries to `logs/work-log.md`.
2. **Review Brief:** Scaffold and enrich `working/briefs/{sid}-review.md` using `scripts/gh-task-ops.sh scaffold-review {sid}`.
3. **Open Pull Request:** Run `scripts/gh-task-ops.sh pr-create` to trigger machine gates and open the PR for Dual-Gate review.

---

## 6. Copy-Paste Session Bootstrap Prompt

```markdown
/start-session
You are the {owner} for the Dark Factory team, building Dark City.

Assigned Ticket: [{sid}] {title}
session-brief: @[working/briefs/{sid}-brief.md]
worktree-path: {wt_path}
git-branch: {branch}

Read AGENTS.md and your role file in .agent/roles/ if not already in context.

MANDATORY WORKSPACE RULE: Verify that your working directory is exactly {wt_path}. Execute all code edits, builds, tests, and file operations strictly within this worktree.

Pull the ticket title, goal, and acceptance criteria from docs/backlog.md and your GitHub issue.

Run Session Start Workflow (.agent/workflows/start-session.md) in full, starting at step 1. Stop at step 7 and report back to the Tech Lead (technical) or Steward (scope) if you hit a genuine ambiguity — don't guess past it.
```
"""

with open(out_file, "w", encoding="utf-8") as f:
    f.write(out_content)

print(f"Scaffolded mission brief at: {out_file}")
EOF
    echo -e "${GREEN}✅ Mission brief scaffolded successfully!${NC}"
    echo -e "Steward and Tech Lead: Please review and enrich ${CYAN}$out_file${NC} before creating the GitHub issue."
}

# --- Command: Scaffold Review Brief ---
scaffold_review_brief() {
    local story_id="$1"
    local custom_out="$2"

    if [ -z "$story_id" ]; then
        infer_branch_info
        story_id="${INFERRED_ISSUE}"
    fi

    if [ -z "$story_id" ]; then
        echo -e "${RED}Error: Story ID is required (e.g. $0 scaffold-review 1.1.2).${NC}" >&2
        return 1
    fi

    parse_backlog_story "$story_id"
    get_worktree_base_dir

    local out_file="$custom_out"
    if [ -z "$out_file" ]; then
        mkdir -p "$PROJECT_ROOT/working/briefs"
        out_file="$PROJECT_ROOT/working/briefs/${story_id}-review.md"
    fi

    python3 - "$STORY_DATA_JSON" "$WORKTREE_BASE" "$GH_PROJECT_OWNER" "$GH_PROJECT_NUMBER" "$out_file" << 'EOF'
import sys, json, re

data = json.loads(sys.argv[1])
wt_base = sys.argv[2]
proj_owner = sys.argv[3]
proj_num = sys.argv[4]
out_file = sys.argv[5]

sid = data["id"]
title = data["title"]
owner = data["owner"]
epic_id = data["epic_id"]
epic_title = data["epic_title"]

slug_text = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")
branch = f"{sid}-{slug_text}"

out_content = f"""# Dark Factory Review Brief: Ticket [{sid}]

**Author / Implementer:** {owner}
**Assigned Reviewer:** Tech Lead (/review-pr)
**Process Gate:** Steward
**Sprint / Epic:** Epic {epic_id} — {epic_title}
**Ticket:** `[{sid}] {title}`
**Pull Request:** [PR #Pending / Link]
**Worktree / Branch:** `{branch}`

---

## 1. Summary of Changes
<!-- Concise summary of what was built and why -->
- **Primary Deliverables:**
  - ...
- **Key Files Modified/Added:**
  - `crates/...`

---

## 2. Architectural Invariants & Key Decisions
<!-- Note any architectural choices, pattern applications, or ADR references -->
- **Decisions Followed:**
- **Invariants Maintained:**

---

## 3. Implementer Self-Identified Risk Areas & Edge Cases
<!-- What was tricky? Where should the reviewer look extra carefully? -->
- **Concurrency / Threading:**
- **Boundary / Error Paths:**
- **Potential Fragilities:**

---

## 4. Test Coverage & Verification Evidence
- **New Tests Added:**
  - `...`
- **Quality Gates Run:**
  - [x] `cargo fmt --check` clean
  - [x] `cargo clippy --all-targets -- -D warnings` clean
  - [x] `cargo nextest run` clean
  - [x] `cargo xtask check` clean

---

## 5. Independent Review Guidance (For Tech Lead / Reviewer)
> [!TIP]
> **Reviewer Mandate:** Do not simply verify that the author's code does what the author intended. Conduct an independent, senior-perspective critical evaluation per the `/review-pr` workflow and `review-checklist.md`:
> 1. Look for unhandled edge cases, concurrency hazards, and race conditions.
> 2. Scrutinize test assertions for real regression value (no vacuous checks).
> 3. Verify no speculative generality or hardcoded constants.
> 4. Ensure public doc comments explain *why* types and methods exist.
"""

with open(out_file, "w", encoding="utf-8") as f:
    f.write(out_content)

print(f"Scaffolded review brief at: {out_file}")
EOF
    echo -e "${GREEN}✅ Review brief scaffolded successfully!${NC}"
    echo -e "Please fill in implementation details in ${CYAN}$out_file${NC} before requesting PR review."
}

# --- Command: Create Issue ---
create_issue() {
    local title=""
    local body=""
    local body_file=""
    local labels="task"
    local status="Backlog"
    local priority=""
    local size="S"
    local estimate=""
    local iteration=""
    local parent_num=""

    # Parse named flags or fallback to positional args
    if [[ "$1" =~ ^-- ]]; then
        while [ "$#" -gt 0 ]; do
            case "$1" in
                --title) title="$2"; shift 2 ;;
                --body) body="$2"; shift 2 ;;
                --body-file) body_file="$2"; shift 2 ;;
                --label|--labels) labels="$2"; shift 2 ;;
                --status) status="$2"; shift 2 ;;
                --priority) priority="$2"; shift 2 ;;
                --size) size="$2"; shift 2 ;;
                --estimate) estimate="$2"; shift 2 ;;
                --iteration|--iter) iteration="$2"; shift 2 ;;
                --parent) parent_num="$2"; shift 2 ;;
                *) echo -e "${RED}Unknown option: $1${NC}" >&2; exit 1 ;;
            esac
        done
    else
        # Legacy positional parser
        title="$1"; shift || true
        local body_arg="${1:-}"; shift || true
        if [ "$body_arg" = "--body-file" ]; then
            body_file="$1"; shift || true
        else
            body="$body_arg"
        fi
        labels="${1:-task}"; shift || true
        status="${1:-Backlog}"; shift || true
        priority="${1:-}"; shift || true
        size="${1:-S}"; shift || true
        estimate="${1:-}"; shift || true
        iteration="${1:-}"; shift || true
        parent_num="${1:-}"; shift || true
    fi

    if [ -z "$title" ]; then
        echo -e "${RED}Error: --title is required.${NC}" >&2
        return 1
    fi

    if [ -n "$body_file" ]; then
        if [ ! -f "$body_file" ]; then
            echo -e "${RED}Error: Body file '$body_file' not found.${NC}" >&2
            return 1
        fi
        body=$(cat "$body_file")
    fi

    echo -e "${BLUE}Creating issue in $REPO_NAME_WITH_OWNER: '$title'...${NC}"
    local issue_url
    issue_url=$(gh issue create -R "$REPO_NAME_WITH_OWNER" --title "$title" --body "$body" --label "$labels")
    local issue_num
    issue_num=$(echo "$issue_url" | grep -oE '[0-9]+$')

    echo -e "${GREEN}✓ Created issue #$issue_num: $issue_url${NC}"

    # Link to parent issue if specified
    if [ -n "$parent_num" ] && [ "$parent_num" != "null" ]; then
        link_sub_issue "$parent_num" "$issue_num"
    fi

    # Project Board Item and Metadata
    ensure_project_item "$issue_num" "$issue_url"
    if [ -n "$PROJECT_ITEM_ID" ]; then
        set_project_metadata "$PROJECT_ITEM_ID" "$status" "$priority" "$size" "$estimate" "$iteration"
        echo -e "${GREEN}✓ Project metadata configured on Project #$GH_PROJECT_NUMBER.${NC}"
    fi

    echo -e "\n${BOLD}${GREEN}🎉 Issue #$issue_num successfully created and dispatched!${NC}"
    echo -e "   URL: ${CYAN}$issue_url${NC}"
}

# --- Command: Create Story from Backlog / Brief ---
create_story() {
    local story_id="$1"; shift || true
    local parent_num=""
    local use_brief=false
    local custom_brief=""

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --parent) parent_num="$2"; shift 2 ;;
            --from-brief) use_brief=true; shift 1 ;;
            --brief-file) custom_brief="$2"; use_brief=true; shift 2 ;;
            *) shift 1 ;;
        esac
    done

    if [ -z "$story_id" ]; then
        echo -e "${RED}Error: Story ID is required (e.g. $0 create-story 1.1.2).${NC}" >&2
        return 1
    fi

    parse_backlog_story "$story_id"
    get_worktree_base_dir

    local story_json="$STORY_DATA_JSON"
    local title est owner epic_id
    title=$(echo "$story_json" | python3 -c 'import sys, json; print(json.load(sys.stdin)["title"])')
    est=$(echo "$story_json" | python3 -c 'import sys, json; print(json.load(sys.stdin)["est"])')
    owner=$(echo "$story_json" | python3 -c 'import sys, json; print(json.load(sys.stdin)["owner"])')
    epic_id=$(echo "$story_json" | python3 -c 'import sys, json; print(json.load(sys.stdin)["epic_id"])')

    local full_title="[$story_id] $title"

    # Map owner to role label
    local role_label
    role_label=$(echo "$owner" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g')
    local labels="task,infrastructure,$role_label"

    # Map Estimate to Size
    local size="S"
    if [ "$est" -le 2 ] 2>/dev/null; then size="XS"
    elif [ "$est" -le 3 ] 2>/dev/null; then size="S"
    elif [ "$est" -le 5 ] 2>/dev/null; then size="M"
    elif [ "$est" -le 8 ] 2>/dev/null; then size="L"
    else size="XL"; fi

    # Check for existing brief file
    local brief_path="$custom_brief"
    if [ -z "$brief_path" ] && [ -f "$PROJECT_ROOT/working/briefs/${story_id}-brief.md" ]; then
        brief_path="$PROJECT_ROOT/working/briefs/${story_id}-brief.md"
    fi

    local issue_body=""
    if [ -n "$brief_path" ] && [ -f "$brief_path" ]; then
        echo -e "${BLUE}Using brief file: $brief_path${NC}"
        issue_body=$(cat "$brief_path")
    else
        # Generate standard structured body
        issue_body=$(python3 - "$story_json" "$WORKTREE_BASE" "$GH_PROJECT_OWNER" "$GH_PROJECT_NUMBER" << 'EOF'
import sys, json, re

data = json.loads(sys.argv[1])
wt_base = sys.argv[2]
proj_owner = sys.argv[3]
proj_num = sys.argv[4]

sid = data["id"]
title = data["title"]
goal = data["goal"]
acc = data["acceptance"]
bp = data["blueprint"]
owner = data["owner"]

slug_text = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")
branch = f"{sid}-{slug_text}"
wt_path = f"{wt_base}/{branch}/"

body = f"""### Role & Goal
**Role:** {owner}
**Goal:** {goal}

### Blueprint Reference
- World Blueprint {bp}

### Gherkin Acceptance Criteria
- {acc}

### Worktree & Execution Details
- **Worktree Path:** `{wt_path}`
- **Branch:** `{branch}`
- **Project:** [DC Board (Project #{proj_num})](https://github.com/orgs/{proj_owner}/projects/{proj_num})
"""
print(body)
EOF
)
    fi

    # Auto-discover parent epic issue if not explicitly provided
    if [ -z "$parent_num" ] && [ -n "$epic_id" ]; then
        local found_epic
        found_epic=$(gh issue list -R "$REPO_NAME_WITH_OWNER" --label "epic" --state open --json number,title --jq ".[] | select(.title | contains(\"[$epic_id]\")) | .number" 2>/dev/null | head -n 1 || true)
        if [ -n "$found_epic" ]; then
            echo -e "${CYAN}Discovered parent Epic issue #$found_epic for Epic $epic_id.${NC}"
            parent_num="$found_epic"
        fi
    fi

    create_issue \
        --title "$full_title" \
        --body "$issue_body" \
        --label "$labels" \
        --status "Backlog" \
        --size "$size" \
        --estimate "$est" \
        --parent "$parent_num"
}

# --- Command: Update Existing Issue Metadata ---
update_issue_metadata() {
    local issue_num=""
    local status=""
    local priority=""
    local size=""
    local estimate=""
    local iteration=""
    local parent_num=""

    if [[ "$1" =~ ^-- ]]; then
        echo -e "${RED}Error: Issue number is required as first argument.${NC}" >&2
        return 1
    fi
    issue_num="$1"; shift || true

    if [[ "$1" =~ ^-- ]]; then
        while [ "$#" -gt 0 ]; do
            case "$1" in
                --status) status="$2"; shift 2 ;;
                --priority) priority="$2"; shift 2 ;;
                --size) size="$2"; shift 2 ;;
                --estimate) estimate="$2"; shift 2 ;;
                --iteration|--iter) iteration="$2"; shift 2 ;;
                --parent) parent_num="$2"; shift 2 ;;
                *) echo -e "${RED}Unknown option: $1${NC}" >&2; exit 1 ;;
            esac
        done
    else
        status="${1:-}"; shift || true
        priority="${1:-}"; shift || true
        size="${1:-}"; shift || true
        estimate="${1:-}"; shift || true
        iteration="${1:-}"; shift || true
        parent_num="${1:-}"; shift || true
    fi

    echo -e "${BLUE}Updating metadata for issue #$issue_num...${NC}"

    if [ -n "$parent_num" ] && [ "$parent_num" != "null" ]; then
        link_sub_issue "$parent_num" "$issue_num"
    fi

    ensure_project_item "$issue_num" ""
    if [ -n "$PROJECT_ITEM_ID" ]; then
        set_project_metadata "$PROJECT_ITEM_ID" "$status" "$priority" "$size" "$estimate" "$iteration"
        echo -e "${GREEN}✅ Successfully updated issue #$issue_num on Project Board.${NC}"
    else
        echo -e "${YELLOW}Warning: Issue #$issue_num not found on project board. Skipping project board field updates.${NC}"
    fi
}

# --- Command: List Project Fields ---
list_fields() {
    resolve_project_fields
    echo -e "${BOLD}${CYAN}=== Project #$GH_PROJECT_NUMBER Fields (${GH_PROJECT_OWNER}) ===${NC}"
    echo "$PROJECT_FIELDS_JSON" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    fields = d.get("fields", [])
    for f in fields:
        name = f.get("name", "")
        ftype = f.get("type", "")
        fid = f.get("id", "")
        print("\033[1m• {}\033[0m ({}) [ID: {}]".format(name, ftype, fid))
        for o in f.get("options", []):
            print("    - {}: {}".format(o.get("name", ""), o.get("id", "")))
        for i in f.get("configuration", {}).get("iterations", []):
            print("    - Iteration: {} ({})".format(i.get("title", ""), i.get("id", "")))
except Exception as e:
    print("Error parsing fields:", e)
'
}

# --- Command: List Iterations ---
list_iterations() {
    resolve_project_fields
    echo -e "${BOLD}${CYAN}=== Project #$GH_PROJECT_NUMBER Iterations ===${NC}"
    echo "$PROJECT_FIELDS_JSON" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    fields = d.get("fields", [])
    f = next((x for x in fields if x.get("name") == "Iteration"), None)
    if f:
        iters = f.get("configuration", {}).get("iterations", [])
        for i in iters:
            print("• \033[1m{}\033[0m: ID={} (Start: {}, Duration: {}d)".format(i.get("title", ""), i.get("id", ""), i.get("startDate", ""), i.get("duration", "")))
    else:
        print("Iteration field not configured on project.")
except Exception as e:
    print("Error:", e)
'
}

# --- Command: List Epics ---
list_epics() {
    echo -e "${BOLD}${CYAN}=== Dark City Epics ($REPO_NAME_WITH_OWNER) ===${NC}"
    gh issue list -R "$REPO_NAME_WITH_OWNER" --label "epic" --state open --json number,title,labels | python3 -c '
import sys, json
try:
    issues = json.load(sys.stdin)
    if not issues:
        print("No open Epics found.")
        sys.exit(0)
    for it in issues:
        num = "#" + str(it.get("number", ""))
        title = it.get("title", "")
        print("\033[1m{:<6}\033[0m {}".format(num, title))
except Exception as e:
    print("Error:", e)
'
}

# --- Command: List Sub-Issues ---
list_sub_issues() {
    local parent_num="$1"
    if [ -z "$parent_num" ]; then
        echo -e "${RED}Error: Parent issue number is required (e.g. $0 sub-issues 3).${NC}" >&2
        return 1
    fi

    echo -e "${BOLD}${CYAN}=== Sub-Issues for #$parent_num ($REPO_NAME_WITH_OWNER) ===${NC}"
    gh issue view "$parent_num" -R "$REPO_NAME_WITH_OWNER" --json number,title,subIssuesSummary | python3 -c '
import sys, json
try:
    data = json.load(sys.stdin)
    summary = data.get("subIssuesSummary", {})
    total = summary.get("total", 0)
    completed = summary.get("completed", 0)
    pct = summary.get("percentCompleted", 0)
    print("Parent: #{} - {}".format(data.get("number", ""), data.get("title", "")))
    print("Progress: {}/{} ({}%)\n".format(completed, total, pct))
except Exception as e:
    print("Error retrieving sub-issues summary:", e)
'
    gh api "repos/$REPO_NAME_WITH_OWNER/issues/$parent_num/sub_issues" --jq '.[] | "- #" + (.number|tostring) + " [" + .state + "] " + .title' 2>/dev/null || true
}

# --- Main Flow ---
case "$1" in
    create)
        shift
        create_issue "$@"
        ;;
    scaffold-brief|scaffold-story)
        shift
        scaffold_brief "$@"
        ;;
    scaffold-review|scaffold-review-brief)
        shift
        scaffold_review_brief "$@"
        ;;
    create-story)
        shift
        create_story "$@"
        ;;
    link|sub-issue)
        shift
        link_sub_issue "$1" "$2"
        ;;
    sub-issues|tree)
        shift
        list_sub_issues "$1"
        ;;
    update)
        shift
        update_issue_metadata "$@"
        ;;
    fields)
        list_fields
        ;;
    iterations|list-iterations)
        list_iterations
        ;;
    epics)
        list_epics
        ;;
    help|--help|-h|*)
        echo -e "${BOLD}${CYAN}Dark Factory GitHub Issue & Project Utility (gh-issue-ops.sh)${NC}"
        echo "=========================================================================="
        echo "Usage: $0 <command> [options...]"
        echo ""
        echo -e "${BOLD}Issue & Backlog Commands:${NC}"
        echo "  create [options]              Create issue with labels, parent link, and project metadata"
        echo "                                Flags: --title, --body, --body-file, --parent, --label,"
        echo "                                       --status, --priority, --size, --estimate, --iteration"
        echo "  scaffold-brief <story_id>     Scaffold rich mission brief markdown in working/briefs/<id>-brief.md"
        echo "  scaffold-review [story_id]    Scaffold standardized review brief in working/briefs/<id>-review.md"
        echo "  create-story <story_id>       Auto-create and dispatch story from backlog or existing brief"
        echo "                                Options: --parent <epic_num>, --from-brief"
        echo "  link <parent_num> <child_num> Link child issue to parent issue as a native GitHub sub-issue"
        echo "  sub-issues <parent_num>       List all child sub-issues and completion progress for a parent"
        echo "  update <issue_num> [options]  Update issue metadata (status, priority, size, estimate) on board"
        echo "  fields                        Inspect available Project v2 custom fields and options"
        echo "  iterations                    Display available project sprint/phase iteration IDs"
        echo "  epics                         List all open Epic issues in the repository"
        echo ""
        echo -e "${BOLD}Examples:${NC}"
        echo "  $0 scaffold-brief 1.1.2                    # Generates working/briefs/1.1.2-brief.md"
        echo "  $0 scaffold-review 1.1.2                   # Generates working/briefs/1.1.2-review.md"
        echo "  $0 create-story 1.1.2 --parent 3           # Dispatches story #1.1.2 linked to Epic #3"
        echo "  $0 create --title \"[Task] New tool\" --body-file task.md --parent 2 --size S"
        echo "  $0 link 3 2                                # Links story #2 as sub-issue of Epic #3"
        echo "  $0 sub-issues 3                            # Lists all stories under Epic #3"
        echo "  $0 update 2 --status \"In progress\" --size S"
        echo ""
        exit 0
        ;;
esac
