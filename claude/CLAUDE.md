# Personal Context — Justin Menestrina

## Role
Senior engineer on the **Pikachu (Preference Management)** team at Transcend.

## Repos
- Primary: `transcend-io/main`
- CLI tools: `transcend-io/cli`

## Linear
- Team: Pikachu (Preference Management)
- Current area: Consent userId migration, preference management pipeline, step functions

## How I work

**Code reviews**
- Label issues: `[BLOCKER]` / `[SUGGESTION]` / `[NITPICK]`
- Blockers must be resolved before merge. Suggestions are optional but worth discussing. Nitpicks are style/clarity only.
- Always check: does this match existing patterns in the codebase?

**PRs**
- Draft first, mark ready when CI is green and self-reviewed
- Always link the Linear issue
- Description sections: `## What`, `## How`, `## Testing`, `## Notes`

**Implementation**
- Plan before coding. State the approach and files to change, wait for confirmation, then implement.
- No empty catch blocks. No silent error swallowing.
- No `as Type` casting on uncertain types — narrow properly.

**Domain model direction (preference management)**
- Moving away from primitive obsession: no manual `split(' ')` for userId parsing, no `category#type` string concatenation, no token-count uniqueness inference
- Prefer value objects: `ConsentUserId`, `LinkedIdentifier`, `PurposeConsent`
- Prefer repository pattern over direct DynamoDB manipulation in business logic
- Storage shapes (DynamoDB codecs) are not domain types

## Codebase context

**Consent preferences**
- Stored in DynamoDB via `ConsentPreferencesByCategoryManager`
- `userId` = `encryptedIdentifier + ' ' + partition` (compound key — parsing this string is a code smell; we're migrating away from it)
- `ConsentPreferencesByCategoryDocument` is a storage shape, not a domain model
- Step functions handle background migration/cleanup jobs (prefer over high-memory lambdas for long-running work)
- Sombra = consent ingress service (the edge layer that handles API requests before hitting PM service)

**DSR/Workflow pipeline**
- `Request` = top-level record for the entire pipeline
- `PurposeRequest` = child record specific to consent workflow requests
- `ProfileDataPoint` = atomic unit of work for an integration
- Enrichers determine what identifiers get resolved; they run before data silos process

## Workflow loops
See `Life/workflow-loops.md` in the personal vault for full definitions. The active loops are:
- **Triage**: thread → scope → create-issue → start
- **Build**: scope → implement (cursor) → self-review → draft-pr
- **Review**: review → confirm → approve/request-changes
- **Unblock**: fix-ci → fix-comments → merge
- **Decision**: think → rfc → share → reply

## Key people
- **Girish (JonnavithulaGirish)**: consent mapping rule orchestration, PM service migration
- **Michael Farrell (michaelfarrell76)**: CLI tools, workflow mutations, various features
- **Mitchell Chan (mitchellkchan)**: frontend preference management, feature flags
