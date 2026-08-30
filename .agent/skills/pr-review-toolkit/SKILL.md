---
name: pr-review-toolkit
description: Perform an independent, senior-perspective Pull Request review for the Dark Factory codebase. Provides the 5-dimension quality checklist and P0-P3 review report template. Trigger on "pr-review-toolkit", "PR review checklist", "review pull request", "conduct code review", or "independent review".
---

# Dark Factory Skill: PR Review Toolkit (`pr-review-toolkit`)

Use this skill when conducting an independent, critical Pull Request review.

## Reviewer Stance & Mindset

As the **Tech Lead** (or designated senior reviewer), your primary responsibility is to find what the implementer missed. Do not anchor your review to the author's summary or merely verify happy paths. Evaluate the code through the **5 Dimensions of Quality**:

1. **Architectural Alignment & Contract Integrity**
2. **Correctness, Failure Modes & Edge Cases**
3. **Concurrency, Thread Safety & Runtime Performance**
4. **Test Value, Rigor & Integrity** (ensuring meaningful regression protection)
5. **Code Hygiene & Documentation**

---

## Review Resources & Progressive Disclosure

- **Comprehensive Checklist:** See [review-checklist.md](resources/review-checklist.md) for the exhaustive step-by-step checklist.
- **Review Output Template:** See [review-template.md](resources/review-template.md) for formatting the formal review report with prioritized severity tiers (**Blocker P0**, **Major P1**, **Minor P2**, **Suggestion P3**).

---

## Execution Workflow

1. Retrieve the **Mission Brief** (`working/briefs/<id>-brief.md`) and **Review Brief** (`working/briefs/<id>-review.md`).
2. Run machine checks:
   ```bash
   scripts/gh-task-ops.sh check
   ```
3. Validate against your checklist [review-checklist.md](resources/review-checklist.md).
4. Generate the findings report using [review-template.md](resources/review-template.md).
5. State your verdict (`APPROVE` or `REQUEST CHANGES`) and guide the author or Steward on next steps.
