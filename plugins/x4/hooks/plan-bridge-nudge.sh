#!/bin/bash
# Fires after ExitPlanMode — reminds the user to route the plan into x4.
# Only nudges if the project has x4 tracker setup (docs/planning/ exists).

if [ -d "docs/planning" ] || [ -f "docs/STATUS.md" ]; then
  echo "Plan mode exited. Run /x4:plan-bridge to convert this plan into a PRD."
fi
