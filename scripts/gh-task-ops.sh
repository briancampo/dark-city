#!/usr/bin/env bash
# scripts/gh-task-ops.sh
# Dark Factory Task & Workspace Operations Utility
# Automated Issue Lifecycle, Worktree Management, and Quality Gate Enforcement.

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
    local git_common
    git_common=$(git rev-parse --git-common-dir 2>/dev/null || true)
    if [ -n "$git_common" ]; then
        PROJECT_ROOT=$(cd "$git_common/.." && pwd -P)
    else
        PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
    fi
}

get_project_root

# --- Load Configuration ---
# Check .agent/config.env, scripts/config.env, or environment variables
if [ -f "$PROJECT_ROOT/.agent/config.env" ]; then
    # shellcheck disable=SC1091
    source "$PROJECT_ROOT/.agent/config.env"
elif [ -f "$PROJECT_ROOT/scripts/config.env" ]; then
    # shellcheck disable=SC1091
    source "$PROJECT_ROOT/scripts/config.env"
fi

# Detect repository owner and name from git remote or gh
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
DEFAULT_BASE_BRANCH="${DEFAULT_BASE_BRANCH:-main}"

# Discover worktrees directory
get_worktree_base_dir() {
    if [ -n "$WORKTREES_DIR" ]; then
        WORKTREE_BASE="$WORKTREES_DIR"
    elif [ -d "$(dirname "$PROJECT_ROOT")/worktrees/${REPO_NAME:-dark-city}" ]; then
        WORKTREE_BASE="$(dirname "$PROJECT_ROOT")/worktrees/${REPO_NAME:-dark-city}"
    elif [ -d "$(dirname "$PROJECT_ROOT")/worktrees" ]; then
        WORKTREE_BASE="$(dirname "$PROJECT_ROOT")/worktrees/${REPO_NAME:-dark-city}"
    elif [ -d "$(dirname "$PROJECT_ROOT")/worktrees/$(basename "$PROJECT_ROOT")" ]; then
        WORKTREE_BASE="$(dirname "$PROJECT_ROOT")/worktrees/$(basename "$PROJECT_ROOT")"
    else
        WORKTREE_BASE="$PROJECT_ROOT/.worktrees"
    fi
}

get_worktree_base_dir

# --- Helper: Python JSON & Data Utilities ---
py_extract() {
    python3 -c "import sys, json; d=json.load(sys.stdin); print(d$1)"
}

# --- Helper: Branch & Issue Inference ---
infer_branch_info() {
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)

    # 1. Try matching decimal ticket IDs like 1.1.0-slug or feature/1.1.0-slug
    if [[ "$current_branch" =~ ^(feature/)?([0-9]+\.[0-9]+\.[0-9]+)-(.*)$ ]]; then
        INFERRED_ISSUE="${BASH_REMATCH[2]}"
        INFERRED_SLUG="${BASH_REMATCH[3]}"
        INFERRED_BRANCH="$current_branch"
    # 2. Try matching integer issue numbers like 2-slug or feature/2-slug
    elif [[ "$current_branch" =~ ^(feature/)?([0-9]+)-(.*)$ ]]; then
        INFERRED_ISSUE="${BASH_REMATCH[2]}"
        INFERRED_SLUG="${BASH_REMATCH[3]}"
        INFERRED_BRANCH="$current_branch"
    # 3. Fallback: check directory name
    else
        local dir_name
        dir_name=$(basename "$(pwd -P)")
        if [[ "$dir_name" =~ ^([0-9]+\.[0-9]+\.[0-9]+)-(.*)$ ]]; then
            INFERRED_ISSUE="${BASH_REMATCH[1]}"
            INFERRED_SLUG="${BASH_REMATCH[2]}"
            INFERRED_BRANCH="$current_branch"
        elif [[ "$dir_name" =~ ^([0-9]+)-(.*)$ ]]; then
            INFERRED_ISSUE="${BASH_REMATCH[1]}"
            INFERRED_SLUG="${BASH_REMATCH[2]}"
            INFERRED_BRANCH="$current_branch"
        else
            INFERRED_ISSUE=""
            INFERRED_SLUG="$current_branch"
            INFERRED_BRANCH="$current_branch"
        fi
    fi
}

# --- Helper: Resolve Ticket ID to GitHub Issue Number ---
resolve_issue_number() {
    local input="$1"
    # Strip leading '#' or brackets if provided (e.g. #2 or [1.1.0])
    local clean_input
    clean_input=$(echo "$input" | sed -E 's/^[#\[]//; s/\]$//')

    # If it's pure integer, it's already an issue number
    if [[ "$clean_input" =~ ^[0-9]+$ ]]; then
        RESOLVED_ISSUE_NUMBER="$clean_input"
        return 0
    fi

    # Otherwise search by title / ticket tag in GitHub issues
    local found_issue
    found_issue=$(gh issue list -R "$REPO_NAME_WITH_OWNER" --state all --search "$clean_input" --json number,title --jq ".[0].number" 2>/dev/null || true)
    
    if [ -n "$found_issue" ] && [ "$found_issue" != "null" ]; then
        RESOLVED_ISSUE_NUMBER="$found_issue"
    else
        echo -e "${YELLOW}Warning: Could not resolve ticket ID '$input' to a GitHub issue number. Using '$input' directly.${NC}" >&2
        RESOLVED_ISSUE_NUMBER="$input"
    fi
}

# --- Helper: Project Board ID Resolution (Safe Fallback) ---
resolve_project_ids() {
    local issue_num="$1"
    HAS_PROJECT_BOARD=false
    STATUS_FIELD_ID=""
    ITEM_ID=""

    if [ -z "$GH_PROJECT_NUMBER" ] || [ -z "$GH_PROJECT_OWNER" ]; then
        return 0
    fi

    # Check if project exists and fetch status field
    local field_list
    field_list=$(gh project field-list "$GH_PROJECT_NUMBER" --owner "$GH_PROJECT_OWNER" --format json 2>/dev/null || true)
    if [ -z "$field_list" ] || [ "$field_list" = "null" ]; then
        return 0
    fi

    STATUS_FIELD_ID=$(echo "$field_list" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    fields = d.get('fields', [])
    f = next((x for x in fields if isinstance(x, dict) and x.get('name') == 'Status'), None)
    if f: print(f.get('id', ''))
except: pass
")

    # Get Item ID for this issue
    local item_list
    item_list=$(gh project item-list "$GH_PROJECT_NUMBER" --owner "$GH_PROJECT_OWNER" --format json --query "$issue_num" -L 1000 2>/dev/null || true)
    if [ -n "$item_list" ]; then
        ITEM_ID=$(echo "$item_list" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d.get('items', [])
    it = next((i for i in items if isinstance(i, dict) and i.get('content', {}).get('number') == int('$issue_num')), None)
    if it: print(it.get('id', ''))
except: pass
")
    fi

    if [ -n "$STATUS_FIELD_ID" ] && [ -n "$ITEM_ID" ]; then
        HAS_PROJECT_BOARD=true
    fi
}

# --- Command: list ---
list_issues() {
    local state="${1:-open}"
    local assignee="${2:-}"

    echo -e "${BOLD}${CYAN}=== Dark City Issues ($REPO_NAME_WITH_OWNER) ===${NC}"
    
    local args=("-R" "$REPO_NAME_WITH_OWNER" "--limit" "50" "--json" "number,title,state,assignees,labels")
    if [ "$state" != "all" ]; then
        args+=("--state" "$state")
    else
        args+=("--state" "all")
    fi

    if [ -n "$assignee" ]; then
        args+=("--assignee" "$assignee")
    fi

    gh issue list "${args[@]}" | python3 -c '
import sys, json
try:
    issues = json.load(sys.stdin)
    if not issues:
        print("No issues found.")
        sys.exit(0)
    print("\033[1m{:<6} {:<8} {:<16} {}\033[0m".format("ID", "State", "Assignees", "Title"))
    print("-" * 80)
    for it in issues:
        num = "#" + str(it.get("number", ""))
        st = it.get("state", "")
        assignees = ", ".join([a.get("login", "") for a in it.get("assignees", [])]) or "-"
        title = it.get("title", "")
        print("{:<6} {:<8} {:<16} {}".format(num, st, assignees, title))
except Exception as e:
    print("Error listing issues:", e)
'
}

# --- Command: info ---
info() {
    local input="${1:-}"
    if [ -z "$input" ]; then
        infer_branch_info
        input="${INFERRED_ISSUE}"
    fi

    if [ -z "$input" ]; then
        echo -e "${RED}Error: Please specify an issue number or ticket ID (e.g. $0 info 2 or $0 info 1.1.0).${NC}" >&2
        exit 1
    fi

    resolve_issue_number "$input"
    local issue_num="$RESOLVED_ISSUE_NUMBER"

    echo -e "${BOLD}${CYAN}### GitHub Issue #$issue_num Details (${REPO_NAME_WITH_OWNER})${NC}"
    gh issue view "$issue_num" -R "$REPO_NAME_WITH_OWNER"

    # Also display project metadata if available
    resolve_project_ids "$issue_num"
    if [ "$HAS_PROJECT_BOARD" = true ]; then
        echo -e "\n${BOLD}${CYAN}### GitHub Project Board Metadata${NC}"
        gh project item-list "$GH_PROJECT_NUMBER" --owner "$GH_PROJECT_OWNER" --format json --query "$issue_num" -L 1000 | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    items = d.get("items", [])
    it = next((i for i in items if isinstance(i, dict) and i.get("content", {}).get("number") == int("'"$issue_num"'")), None)
    if it:
        print("| Field | Value |")
        print("| :--- | :--- |")
        print("| Status | {} |".format(it.get("status", "-")))
        print("| Priority | {} |".format(it.get("priority", "-")))
        print("| Size | {} |".format(it.get("size", "-")))
        print("| Estimate | {} |".format(it.get("estimate", "-")))
        iteration = it.get("iteration", {}).get("title", "-")
        print("| Iteration | {} |".format(iteration))
except Exception:
    pass
'
    fi
}

# --- Command: assign / start ---
assign_issue() {
    local input="$1"
    local custom_slug="$2"

    if [ -z "$input" ]; then
        echo -e "${RED}Error: Issue number or ticket ID is required.${NC}" >&2
        echo "Usage: $0 assign <issue_number_or_ticket_id> [branch_slug]" >&2
        exit 1
    fi

    resolve_issue_number "$input"
    local issue_num="$RESOLVED_ISSUE_NUMBER"

    # Fetch issue title & details
    local issue_json
    issue_json=$(gh issue view "$issue_num" -R "$REPO_NAME_WITH_OWNER" --json number,title,body 2>/dev/null || true)
    if [ -z "$issue_json" ]; then
        echo -e "${RED}Error: Issue #$issue_num not found on GitHub repo $REPO_NAME_WITH_OWNER.${NC}" >&2
        exit 1
    fi

    local issue_title
    issue_title=$(echo "$issue_json" | python3 -c "import sys, json; print(json.load(sys.stdin).get('title', ''))")

    # Generate branch slug if not supplied
    local branch_slug="$custom_slug"
    if [ -z "$branch_slug" ]; then
        # Derive slug from title: e.g. "[1.1.0] Containerized backend deployment" -> "1.1.0-containerized-backend-deployment"
        branch_slug=$(echo "$issue_title" | python3 -c "
import sys, re
title = sys.stdin.read().strip()
# Extract ticket ID if present e.g. [1.1.0]
match = re.search(r'\[([0-9]+\.[0-9]+\.[0-9]+)\]\s*(.*)', title)
if match:
    ticket = match.group(1)
    rest = match.group(2).lower()
    rest = re.sub(r'[^a-z0-9]+', '-', rest).strip('-')
    print(f'{ticket}-{rest}')
else:
    slug = re.sub(r'[^a-z0-9]+', '-', title.lower()).strip('-')
    print(slug[:40])
")
    fi

    # Ensure branch slug is clean
    if [[ ! "$branch_slug" =~ ^[0-9] ]]; then
        branch_slug="${issue_num}-${branch_slug}"
    fi

    local branch_name="$branch_slug"
    get_worktree_base_dir
    mkdir -p "$WORKTREE_BASE"
    local worktree_path="${WORKTREE_BASE}/${branch_slug}"

    # Assign on GitHub
    local user_login
    user_login=$(gh api user --jq '.login' 2>/dev/null || echo "@me")
    echo -e "${BLUE}Assigning issue #$issue_num to @$user_login...${NC}"
    gh issue edit "$issue_num" -R "$REPO_NAME_WITH_OWNER" --add-assignee "$user_login" >/dev/null 2>&1 || true

    get_project_root
    cd "$PROJECT_ROOT"

    echo -e "${BLUE}Preparing git branch '$branch_name'...${NC}"
    if ! git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
        if git rev-parse --verify "origin/$branch_name" >/dev/null 2>&1; then
            echo "Checking out remote branch 'origin/$branch_name'..."
            git branch "$branch_name" "origin/$branch_name"
        else
            echo "Creating branch '$branch_name' from '$DEFAULT_BASE_BRANCH'..."
            git branch "$branch_name" "$DEFAULT_BASE_BRANCH"
        fi
    else
        echo "Branch '$branch_name' already exists."
    fi

    # Create worktree
    if [ ! -d "$worktree_path" ]; then
        echo -e "${BLUE}Adding git worktree at $worktree_path...${NC}"
        git worktree add "$worktree_path" "$branch_name"
    else
        echo "Worktree directory already exists at $worktree_path."
    fi

    # Update status to In Progress on Project Board if available
    set_status "$issue_num" "In Progress" >/dev/null 2>&1 || true

    echo -e "\n${BOLD}${GREEN}✅ Task setup complete!${NC}"
    echo -e "   ${BOLD}Issue:${NC} #$issue_num - $issue_title"
    echo -e "   ${BOLD}Branch:${NC} $branch_name"
    echo -e "   ${BOLD}Worktree:${NC} $worktree_path"
    echo -e "\nTo begin working, switch to the worktree:"
    echo -e "   ${CYAN}cd $worktree_path${NC}"
}

# --- Command: status ---
set_status() {
    local input="$1"
    local status_name="$2"

    if [ -z "$input" ] || [ -z "$status_name" ]; then
        echo "Usage: $0 status <issue_number> <status_name>" >&2
        return 1
    fi

    resolve_issue_number "$input"
    local issue_num="$RESOLVED_ISSUE_NUMBER"

    resolve_project_ids "$issue_num"
    if [ "$HAS_PROJECT_BOARD" != true ]; then
        echo -e "${YELLOW}Notice: GitHub Project board not configured or inaccessible. Skipping project board status update.${NC}"
        return 0
    fi

    # Resolve Option ID for status
    local option_id
    option_id=$(gh project field-list "$GH_PROJECT_NUMBER" --owner "$GH_PROJECT_OWNER" --format json 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    fields = d.get('fields', [])
    f = next((x for x in fields if isinstance(x, dict) and x.get('name') == 'Status'), None)
    if f:
        opts = f.get('options', [])
        target = next((o for o in opts if isinstance(o, dict) and o.get('name', '').lower() == '$status_name'.lower()), None)
        if target: print(target.get('id', ''))
except: pass
")

    if [ -n "$option_id" ] && [ -n "$ITEM_ID" ] && [ -n "$GH_PROJECT_ID" ]; then
        echo -e "${BLUE}Updating project status of #$issue_num to '$status_name'...${NC}"
        gh project item-edit --id "$ITEM_ID" --project-id "$GH_PROJECT_ID" --field-id "$STATUS_FIELD_ID" --single-select-option-id "$option_id" >/dev/null 2>&1 || true
        echo -e "${GREEN}✅ Status updated to '$status_name'.${NC}"
    else
        echo -e "${YELLOW}Project option for '$status_name' could not be resolved.${NC}"
    fi
}

# --- Command: check / verify ---
run_checks() {
    echo -e "${BOLD}${CYAN}=== Running Dark Factory Quality Gates ===${NC}"
    
    # 1. Format check
    echo -e "\n${BOLD}[1/4] Checking code formatting (cargo fmt --check)...${NC}"
    if cargo fmt --all -- --check; then
        echo -e "${GREEN}✓ Formatting clean${NC}"
    else
        echo -e "${RED}✗ Formatting errors detected. Run 'cargo fmt --all' to fix.${NC}"
        return 1
    fi

    # 2. Clippy check
    echo -e "\n${BOLD}[2/4] Running Clippy lints (cargo clippy --workspace --all-targets -- -D warnings)...${NC}"
    if cargo clippy --workspace --all-targets -- -D warnings; then
        echo -e "${GREEN}✓ Clippy clean with zero warnings${NC}"
    else
        echo -e "${RED}✗ Clippy warnings detected.${NC}"
        return 1
    fi

    # 3. Test execution
    echo -e "\n${BOLD}[3/4] Running test suite...${NC}"
    if cargo nextest --version >/dev/null 2>&1; then
        if cargo nextest run --workspace; then
            echo -e "${GREEN}✓ All nextest tests passed${NC}"
        else
            echo -e "${RED}✗ Test suite failures detected.${NC}"
            return 1
        fi
    else
        if cargo test --workspace; then
            echo -e "${GREEN}✓ All cargo tests passed${NC}"
        else
            echo -e "${RED}✗ Test suite failures detected.${NC}"
            return 1
        fi
    fi

    # 4. xtask check (if present)
    if [ -d "xtask" ] || [ -d "$PROJECT_ROOT/xtask" ]; then
        echo -e "\n${BOLD}[4/4] Running xtask check suite (cargo xtask check)...${NC}"
        if cargo xtask check; then
            echo -e "${GREEN}✓ xtask checks passed${NC}"
        else
            echo -e "${RED}✗ xtask checks failed.${NC}"
            return 1
        fi
    else
        echo -e "\n${BOLD}[4/4] xtask not present; skipping.${NC}"
    fi

    echo -e "\n${BOLD}${GREEN}🎯 All Dark Factory Definition of Done checks passed!${NC}"
    return 0
}

# --- Command: pr-status ---
pr_status() {
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "current branch")
    echo -e "${BOLD}${CYAN}=== Pull Request Status ($current_branch) ===${NC}"
    local pr_json
    pr_json=$(gh pr view --json number,title,state,reviewDecision,mergeable,statusCheckRollup,url 2>/dev/null || true)
    if [ -z "$pr_json" ]; then
        echo -e "${YELLOW}No open Pull Request found for branch '$current_branch'.${NC}"
        return 0
    fi
    echo "$pr_json" | python3 -c '
import sys, json
try:
    data = json.load(sys.stdin)
    pr_num = data.get("number", "")
    pr_title = data.get("title", "")
    pr_state = data.get("state", "")
    pr_review = data.get("reviewDecision") or "Pending"
    pr_mergeable = data.get("mergeable", "")
    pr_url = data.get("url", "")
    print("\033[1mPR #{}:\033[0m {}".format(pr_num, pr_title))
    print("State:           {}".format(pr_state))
    print("Review Decision: {}".format(pr_review))
    print("Mergeable:       {}".format(pr_mergeable))
    print("URL:             {}".format(pr_url))
    print("\nChecks:")
    checks = data.get("statusCheckRollup", [])
    if not checks:
        print(" (No CI checks reported)")
    for c in checks:
        name = c.get("name", "check")
        status = c.get("status", "")
        conclusion = c.get("conclusion", "")
        print(" - {}: {} ({})".format(name, status, conclusion))
except Exception:
    print("Could not parse PR status details.")
'
}

# --- Command: pr-create ---
pr_create() {
    local no_verify=false
    if [ "$1" = "--no-verify" ]; then
        no_verify=true
        shift
    fi

    local issue_input="$1"
    local custom_title="$2"
    local custom_body="$3"

    infer_branch_info
    local issue_num=""
    if [ -n "$issue_input" ]; then
        resolve_issue_number "$issue_input"
        issue_num="$RESOLVED_ISSUE_NUMBER"
    elif [ -n "$INFERRED_ISSUE" ]; then
        resolve_issue_number "$INFERRED_ISSUE"
        issue_num="$RESOLVED_ISSUE_NUMBER"
    fi

    # Run checks unless skipped
    if [ "$no_verify" = false ]; then
        echo -e "${BLUE}Running pre-PR verification checks...${NC}"
        if ! run_checks; then
            echo -e "${RED}Quality checks failed. Fix the issues before opening a PR, or pass --no-verify to bypass.${NC}" >&2
            exit 1
        fi
    fi

    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
        echo -e "${RED}Error: Cannot create a PR from '$current_branch'. Please switch to a task branch/worktree.${NC}" >&2
        exit 1
    fi

    echo -e "${BLUE}Pushing current branch '$current_branch' to origin...${NC}"
    git push -u origin HEAD

    # Determine PR Title
    local pr_title="$custom_title"
    if [ -z "$pr_title" ]; then
        if [ -n "$issue_num" ]; then
            local issue_title
            issue_title=$(gh issue view "$issue_num" -R "$REPO_NAME_WITH_OWNER" --json title --jq .title 2>/dev/null || true)
            pr_title="${issue_title:-$current_branch}"
        else
            pr_title="$current_branch"
        fi
    fi

    # Determine PR Body
    local pr_body="$custom_body"
    if [ -z "$pr_body" ]; then
        pr_body="## Summary\nImplementation for task branch \`$current_branch\`."
        if [ -n "$issue_num" ]; then
            pr_body+="\n\nResolves #${issue_num}."
        fi
        pr_body+="\n\n## Dark Factory Dual-Gate Checklist (Charter §7)\n"
        pr_body+="- [x] Tests pass cleanly across workspace\n"
        pr_body+="- [x] \`cargo clippy --all-targets -- -D warnings\` clean\n"
        pr_body+="- [x] \`cargo xtask check\` clean\n"
        pr_body+="- [x] Public interfaces documented explaining *why*\n"
        pr_body+="- [x] No dead code or unexplained TODOs\n"
        pr_body+="\n## Session Handoff Note\n**Status:** Ready for Review\n"
    fi

    echo -e "${BLUE}Creating Pull Request...${NC}"
    local pr_url
    pr_url=$(gh pr create -R "$REPO_NAME_WITH_OWNER" --title "$pr_title" --body "$(echo -e "$pr_body")" --draft=false)
    local pr_num
    pr_num=$(echo "$pr_url" | grep -oE '[0-9]+$')

    echo -e "\n${BOLD}${GREEN}✅ PR #$pr_num created successfully!${NC}"
    echo -e "   URL: ${CYAN}$pr_url${NC}"

    # Move to Review on project board
    if [ -n "$issue_num" ]; then
        set_status "$issue_num" "Review" >/dev/null 2>&1 || true
    fi
}

# --- Command: teardown ---
teardown_issue() {
    local issue_input="$1"
    local branch_slug="$2"

    infer_branch_info
    local issue_num="${issue_input:-$INFERRED_ISSUE}"
    local slug="${branch_slug:-$INFERRED_SLUG}"
    local branch_name="${INFERRED_BRANCH:-$slug}"

    get_project_root
    get_worktree_base_dir

    # Find worktree directory
    local target_worktree=""
    if [ -d "$WORKTREE_BASE/$slug" ]; then
        target_worktree="$WORKTREE_BASE/$slug"
    elif [ -d "$WORKTREE_BASE/$issue_num-$slug" ]; then
        target_worktree="$WORKTREE_BASE/$issue_num-$slug"
    elif [ -d "$PROJECT_ROOT/.worktrees/$slug" ]; then
        target_worktree="$PROJECT_ROOT/.worktrees/$slug"
    elif [ -d "$PROJECT_ROOT/.worktrees/$issue_num-$slug" ]; then
        target_worktree="$PROJECT_ROOT/.worktrees/$issue_num-$slug"
    fi

    echo -e "${BLUE}Switching to project root: $PROJECT_ROOT${NC}"
    cd "$PROJECT_ROOT"

    if [ -n "$target_worktree" ] && [ -d "$target_worktree" ]; then
        echo -e "${BLUE}Removing git worktree at $target_worktree...${NC}"
        git worktree remove "$target_worktree" --force 2>/dev/null || {
            echo "Falling back to manual directory removal..."
            rm -rf "$target_worktree"
        }
    fi
    git worktree prune || true

    # Delete local branch if not currently checked out
    if [ -n "$branch_name" ] && [ "$branch_name" != "main" ] && [ "$branch_name" != "master" ]; then
        local current_branch
        current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
        if [ "$current_branch" != "$branch_name" ]; then
            echo -e "${BLUE}Deleting local branch '$branch_name'...${NC}"
            git branch -D "$branch_name" 2>/dev/null || true
        fi
    fi

    echo -e "${GREEN}✅ Teardown complete. Cleaned up worktree and branch.${NC}"
}

# --- Command: finish / merge ---
finish_issue() {
    local no_verify=false
    if [ "$1" = "--no-verify" ]; then
        no_verify=true
        shift
    fi

    local issue_input="$1"
    local branch_slug="$2"

    infer_branch_info
    local issue_num="${issue_input:-$INFERRED_ISSUE}"
    local slug="${branch_slug:-$INFERRED_SLUG}"
    local branch_name="${INFERRED_BRANCH:-$slug}"

    if [ -n "$issue_num" ]; then
        resolve_issue_number "$issue_num"
        issue_num="$RESOLVED_ISSUE_NUMBER"
    fi

    echo -e "${BOLD}${CYAN}=== Finalizing Task & PR for $branch_name ===${NC}"

    # Commit any uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${BLUE}Staging and committing remaining changes...${NC}"
        git add -A
        git commit -m "Finalize implementation for #${issue_num:-$branch_name}"
    fi

    echo -e "${BLUE}Pushing latest changes to origin...${NC}"
    git push -u origin HEAD

    # Check for linked PR
    local pr_data
    pr_data=$(gh pr view --json number,mergeable,state,url --jq '{number: .number, mergeable: .mergeable, state: .state, url: .url}' 2>/dev/null || true)
    
    if [ -n "$pr_data" ] && [ "$pr_data" != "null" ]; then
        local pr_number
        pr_number=$(echo "$pr_data" | python3 -c "import sys, json; print(json.load(sys.stdin).get('number', ''))")
        local mergeable
        mergeable=$(echo "$pr_data" | python3 -c "import sys, json; print(json.load(sys.stdin).get('mergeable', ''))")

        if [ "$mergeable" = "CONFLICTING" ]; then
            echo -e "${RED}🚨 Error: PR #$pr_number has merge conflicts with base branch. Please resolve conflicts before finishing.${NC}" >&2
            exit 1
        fi

        echo -e "${BLUE}Merging PR #$pr_number (Squash & Merge)...${NC}"
        if gh pr merge "$pr_number" --squash -R "$REPO_NAME_WITH_OWNER"; then
            echo -e "${GREEN}✓ PR #$pr_number merged successfully.${NC}"
        else
            echo -e "${RED}🚨 Error: Failed to merge PR #$pr_number. Check CI status and branch protections.${NC}" >&2
            exit 1
        fi

        if [ -n "$issue_num" ]; then
            set_status "$issue_num" "Done" >/dev/null 2>&1 || true
        fi
    else
        echo -e "${YELLOW}Warning: No open PR found for branch '$branch_name'. Skipping merge step.${NC}"
    fi

    # Teardown worktree and branch
    teardown_issue "$issue_num" "$slug"

    # Sync main
    sync_main
    echo -e "\n${BOLD}${GREEN}🎉 Lifecycle complete! Task finalized and main synced.${NC}"
}

# --- Command: sync ---
sync_main() {
    get_project_root
    cd "$PROJECT_ROOT"
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
    
    if [ "$current_branch" != "$DEFAULT_BASE_BRANCH" ]; then
        echo -e "${BLUE}Switching to '$DEFAULT_BASE_BRANCH'...${NC}"
        git checkout "$DEFAULT_BASE_BRANCH"
    fi

    echo -e "${BLUE}Syncing '$DEFAULT_BASE_BRANCH' with origin/$DEFAULT_BASE_BRANCH...${NC}"
    git fetch origin "$DEFAULT_BASE_BRANCH"
    git pull origin "$DEFAULT_BASE_BRANCH"
    echo -e "${GREEN}✓ '$DEFAULT_BASE_BRANCH' is up to date.${NC}"
}

# --- Main Entrypoint ---
case "$1" in
    list)
        list_issues "$2" "$3"
        ;;
    info|view)
        info "$2"
        ;;
    assign|start)
        assign_issue "$2" "$3"
        ;;
    status)
        set_status "$2" "$3"
        ;;
    check|verify)
        run_checks
        ;;
    pr-create)
        pr_create "$2" "$3" "$4"
        ;;
    pr-status|pr-view)
        pr_status
        ;;
    teardown)
        teardown_issue "$2" "$3"
        ;;
    finish|merge)
        finish_issue "$2" "$3"
        ;;
    sync)
        sync_main
        ;;
    help|--help|-h|*)
        echo -e "${BOLD}${CYAN}Dark Factory Task & Workspace Operations Utility (gh-task-ops.sh)${NC}"
        echo "=========================================================================="
        echo "Usage: $0 <command> [arguments...]"
        echo ""
        echo -e "${BOLD}Task Lifecycle Commands:${NC}"
        echo "  list [state] [assignee]       List issues on GitHub (state: open|closed|all, default: open)"
        echo "  info <issue_or_ticket_id>     Display issue description, acceptance criteria, and project metadata"
        echo "  assign <issue_id> [slug]      Assign issue to @me, create branch, and setup isolated worktree"
        echo "  check                         Run full Dark Factory DoD gates (fmt, clippy, tests, xtask check)"
        echo "  status <issue_id> <status>    Update issue status on GitHub Project board (e.g. 'In Progress', 'Done')"
        echo "  pr-create [options]           Push branch, run DoD checks, and create linked PR with handoff template"
        echo "  pr-status                     Display PR state, review status, and CI check results"
        echo "  finish [issue_id] [slug]      Commit, push, merge PR (squash), mark Done, teardown worktree, sync main"
        echo "  teardown [issue_id] [slug]    Remove worktree and delete local branch without merging"
        echo "  sync                          Switch to main branch at repository root and pull latest changes"
        echo ""
        echo -e "${BOLD}Contextual Inference:${NC}"
        echo "  When executed from inside an active task worktree or branch, 'info', 'pr-create', 'pr-status',"
        echo "  'teardown', and 'finish' automatically detect the issue number and branch slug from the context."
        echo ""
        echo -e "${BOLD}Examples:${NC}"
        echo "  $0 list                                   # View open backlog issues"
        echo "  $0 info 1.1.0                             # View details & criteria for ticket [1.1.0]"
        echo "  $0 assign 2                               # Assigns #2 and creates worktree"
        echo "  $0 check                                  # Runs fmt, clippy, tests, and xtask"
        echo "  $0 pr-create                              # Runs checks and opens PR from worktree"
        echo "  $0 finish                                 # Squash-merges PR, removes worktree, syncs main"
        echo ""
        exit 0
        ;;
esac
