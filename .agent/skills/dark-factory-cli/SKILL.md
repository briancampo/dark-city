---
name: dark-factory-cli
description: Use when managing GitHub project boards, dispatching issues, scaffolding mission briefs, creating task branches and worktrees, running quality gates, opening PRs, or finishing tasks. Trigger on "manage tasks", "create issue", "start ticket", "scaffold brief", "check quality gates", "create pr", "finish ticket", "link sub-issue", "how do I use gh-task-ops", "how do I use gh-issue-ops", or "run project operations".
---

# Dark Factory CLI Operations Guide

The Dark Factory automation suite provides two complementary command-line scripts to streamline development, worktree management, quality gate enforcement, and GitHub Project tracking.

- **Repository:** `Mindstar-Studio/dark-city`
- **Project Board:** [DC Board (Project #2)](https://github.com/orgs/Mindstar-Studio/projects/2)
- **Configuration:** `.agent/config.env`

---

## 1. Choosing the Right Tool

| Tool                          | Primary Purpose                          | When to Use                                                                                                                                  |
| :---------------------------- | :--------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------- |
| **`scripts/gh-task-ops.sh`**  | **Active Task & Worktree Lifecycle**     | When developing code on a ticket: assigning issues, setting up worktrees, running DoD checks, opening PRs, and squash-merging.               |
| **`scripts/gh-issue-ops.sh`** | **Backlog & Issue Hierarchy Management** | When administering the project: scaffolding mission briefs, creating epics/stories/tasks, linking sub-issues, and updating project metadata. |

---

## 2. Developer & Agent Execution Workflow (`gh-task-ops.sh`)

### A. Discover Assigned Work

```bash
scripts/gh-task-ops.sh list                # List open backlog issues
scripts/gh-task-ops.sh info 1.1.0          # View description & criteria for ticket [1.1.0] (or issue #2)
```

### B. Start Work & Setup Isolated Worktree

```bash
scripts/gh-task-ops.sh assign 1.1.0        # Assigns issue, creates branch, prepares worktree
cd /home/brian/dev/ai/worktrees/dark-city/1.1.0-containerized-backend-deployment/
```

### C. Verify Quality Gates (Definition of Done)

```bash
scripts/gh-task-ops.sh check               # Runs fmt, clippy (-D warnings), nextest, and xtask
```

### D. Create Pull Request

```bash
scripts/gh-task-ops.sh pr-create           # Validates DoD checks, pushes branch, and opens PR
scripts/gh-task-ops.sh pr-status           # Inspect PR checks and review status
```

### E. Finalize & Merge Task

```bash
scripts/gh-task-ops.sh finish              # Squash-merges PR, closes issue, tears down worktree, syncs main
```

---

## 3. Backlog & Hierarchy Workflow (`gh-issue-ops.sh`)

### A. Hierarchy Structure

```
Epic ([1.1] Foundational Infrastructure)
 └── Story ([1.1.0] Containerized backend deployment)
      └── Task (Sub-task: Dockerfile & Healthcheck)
```

### B. Scaffold a Mission Brief from Backlog

```bash
scripts/gh-issue-ops.sh scaffold-brief 1.1.2
```

_Generates `working/briefs/1.1.2-brief.md` containing Blueprint links, Gherkin criteria, worktree path, and `/session-start` bootstrap prompt._
This document is the basic starting point and should be enhanced with story and task specific information to guide the next agent.  

### C. Create Story & Link to Parent Epic

```bash
# Create directly from scaffolded brief:
scripts/gh-issue-ops.sh create-story 1.1.2 --parent 3 --from-brief

# Or create a custom sub-task with metadata:
scripts/gh-issue-ops.sh create \
  --title "[Task] Dockerfile multi-stage build" \
  --body-file working/tasks/dockerfile-task.md \
  --parent 2 \
  --label "infrastructure,task,system-architect" \
  --status "Backlog" \
  --size "S" \
  --estimate 2
```

### D. Hierarchy & Sub-Issue Inspection

```bash
scripts/gh-issue-ops.sh epics              # List open Epics
scripts/gh-issue-ops.sh sub-issues 3       # View sub-issues and progress under Epic #3
scripts/gh-issue-ops.sh link 3 2           # Link issue #2 as sub-issue of Epic #3
```

### E. Project Board Metadata Management

```bash
scripts/gh-issue-ops.sh fields             # Inspect Project #2 custom fields and single-select options
scripts/gh-issue-ops.sh iterations         # List active sprint / iteration IDs
scripts/gh-issue-ops.sh update 2 --status "In progress" --size S --estimate 3
```

---

## 4. Key Rules for Developer Agents

1. **Strict Worktree Boundary:** Never edit files or commit outside your assigned worktree path.
2. **Quality Gate Requirement:** Always run `scripts/gh-task-ops.sh check` before opening a PR.
3. **Dual-Gate PR Process:** All PRs require Steward and Tech Lead review sign-offs per Charter §7.
4. **Clean Handoffs:** Use `scripts/gh-task-ops.sh pr-create` to automatically populate the Definition of Done checklist and handoff template.
