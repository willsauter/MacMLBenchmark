<!--
Sync Impact Report
==================
Version Change: [INITIAL] → 1.0.0
Change Type: Initial constitution ratification
Modified Principles: N/A (initial version)
Added Sections:
  - Complete Feature Delivery
  - Incremental User Story Implementation
  - Testing Discipline
  - Code Quality
  - Documentation Standards
  - Feature Workflow
  - Quality Gates
  - Governance
Removed Sections: N/A (initial version)
Templates Requiring Updates:
  ✅ plan-template.md - Constitution Check section aligns with principles
  ✅ spec-template.md - User story prioritization matches Complete Feature Delivery principle
  ✅ tasks-template.md - Phase organization enforces incremental completion
Follow-up TODOs: None
-->

# MacMLBenchmark Constitution

## Core Principles

### I. Complete Feature Delivery (NON-NEGOTIABLE)

**Every feature MUST be fully functional and tested before moving to the next feature.**

This is the cornerstone principle of this project. Each feature represents a complete, working increment of value. A feature is only "complete" when:
- All functional requirements are implemented
- All acceptance scenarios pass
- Integration with existing features is verified
- Documentation is updated
- No known blocking issues remain

**Rationale**: Partial implementations create technical debt, introduce integration risks, and deliver no user value. By ensuring complete delivery, we maintain a perpetually deployable codebase and build compound reliability—each new feature stands on a solid foundation.

### II. Incremental User Story Implementation

**Within each feature, user stories MUST be implemented in priority order (P1 → P2 → P3), with each story independently testable.**

User stories are prioritized slices of functionality. Each story must:
- Be independently verifiable (can test without other stories being complete)
- Deliver standalone value (P1 alone should constitute an MVP)
- Be completable before starting the next priority level

**Rationale**: Prioritized user stories enable early validation, reduce scope risk, and ensure the most critical functionality is always working. This approach supports iterative delivery and allows for scope adjustment without abandoning in-progress work.

### III. Testing Discipline

**Test strategies MUST be explicit and aligned with user acceptance scenarios.**

Testing requirements must be clearly specified per feature:
- If tests are requested: Write tests FIRST, ensure they FAIL, then implement (red-green-refactor)
- If tests are not requested: Document manual validation steps that correspond to acceptance scenarios
- Integration tests are required when user stories interact or depend on shared infrastructure
- All tests must map back to acceptance scenarios in the specification

**Rationale**: Explicit testing requirements prevent ambiguity and wasted effort. Test-first development (when specified) ensures implementation correctness. When tests aren't required, documented validation steps maintain quality without over-engineering.

### IV. Code Quality

**Code MUST be simple, maintainable, and justified.**

All code must adhere to:
- YAGNI (You Aren't Gonna Need It): Only implement what the current feature requires
- Single Responsibility: Each module/class/function has one clear purpose
- Clarity over cleverness: Readable code is more valuable than compact code
- Complexity justification: Any pattern or abstraction beyond straightforward implementation must be documented in the Complexity Tracking section of the plan with rationale

**Rationale**: Simple code reduces cognitive load, speeds up future changes, and minimizes bugs. Unjustified complexity is technical debt by another name.

### V. Documentation Standards

**Every feature MUST include specification, plan, and implementation documentation.**

Required documentation per feature (in `/specs/[###-feature-name]/`):
- `spec.md`: User stories, requirements, acceptance scenarios, success criteria
- `plan.md`: Technical approach, structure decisions, constitution check, complexity justification
- `tasks.md`: Dependency-ordered task list organized by user story
- `quickstart.md` (if applicable): How to run/test the feature
- Design artifacts (`research.md`, `data-model.md`, `contracts/`) as needed

**Rationale**: Documentation captures intent, enables knowledge transfer, and serves as a contract between requirements and implementation. The specification-plan-tasks flow ensures thinking before coding and provides checkpoints for validation.

## Feature Workflow

### Development Flow (MANDATORY)

Features MUST progress through these stages:

1. **Specification** (`/speckit.specify`):
   - Capture user stories with priorities (P1, P2, P3, ...)
   - Define acceptance scenarios for each story
   - Document functional requirements
   - Establish success criteria

2. **Planning** (`/speckit.plan`):
   - Research technical approach (Phase 0)
   - Design data models and contracts (Phase 1)
   - Run Constitution Check
   - Justify any complexity

3. **Task Generation** (`/speckit.tasks`):
   - Break down into dependency-ordered tasks
   - Organize by user story (Setup → Foundational → US1 → US2 → US3 → Polish)
   - Mark parallel opportunities

4. **Implementation** (`/speckit.implement`):
   - Execute tasks in order
   - Complete each user story FULLY before moving to next priority
   - Validate at checkpoints
   - Update documentation as you go

5. **Feature Completion**:
   - All user stories for the feature are complete and tested
   - Documentation is current
   - Constitution Check passes
   - Feature is ready for integration/deployment

**No shortcuts**: Skipping stages or partial completion violates Principle I (Complete Feature Delivery).

### Workflow Enforcement

- Constitution Check MUST pass before Phase 0 research and be re-checked after Phase 1 design
- Foundational phase MUST be complete before ANY user story implementation begins
- User stories MUST be completed in priority order (finish P1 before starting P2)
- Each user story checkpoint MUST be validated before proceeding to the next story
- Feature MUST be marked complete only after all planned user stories pass acceptance scenarios

## Quality Gates

### Gate 1: Specification Approval
- User stories are prioritized and independently testable
- Acceptance scenarios are specific and measurable
- Functional requirements are clear (or marked NEEDS CLARIFICATION)
- Success criteria are defined

### Gate 2: Plan Constitution Check
- All principles verified (Complete Feature Delivery, Incremental Implementation, Testing Discipline, Code Quality, Documentation)
- Any complexity justified in Complexity Tracking table
- Project structure decided and documented
- Dependencies identified

### Gate 3: User Story Completion
- All tasks for the user story are complete
- Acceptance scenarios pass
- Tests pass (if tests were specified) OR manual validation documented
- Integration with existing features verified
- User story can be demonstrated independently

### Gate 4: Feature Completion
- All user stories complete (all priority levels implemented)
- Documentation updated (spec, plan, tasks, quickstart if applicable)
- No blocking issues
- Feature ready for deployment

## Governance

### Authority

This constitution supersedes all other development practices and preferences. When in doubt, refer to the principles above.

### Amendments

Constitution changes require:
1. Documented rationale for the change
2. Version bump following semantic versioning:
   - **MAJOR**: Backward incompatible principle changes or removals
   - **MINOR**: New principles or materially expanded guidance
   - **PATCH**: Clarifications, wording fixes, non-semantic refinements
3. Update to dependent templates (plan-template.md, spec-template.md, tasks-template.md)
4. Sync Impact Report documenting changes and affected files

### Compliance

- All PRs and code reviews must verify compliance with these principles
- The Constitution Check section in plan.md is the primary compliance verification point
- Violations must be either fixed or explicitly justified in the Complexity Tracking table
- The `/speckit.analyze` command should be used to verify cross-artifact consistency

### Template Synchronization

When the constitution changes, the following templates MUST be reviewed and updated if necessary:
- `.specify/templates/plan-template.md` (Constitution Check section)
- `.specify/templates/spec-template.md` (Requirements and user story structure)
- `.specify/templates/tasks-template.md` (Phase organization and checkpoint enforcement)
- `.specify/templates/checklist-template.md` (Quality verification items)

**Version**: 1.0.0 | **Ratified**: 2025-10-16 | **Last Amended**: 2025-10-16
