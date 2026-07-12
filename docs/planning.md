# PikaCircle plan

! PB Vision integration? Future phase only. It may later auto-determine a user's skill diagram from hosted-session
recordings, but the MVP does not integrate PB Vision into the app yet.

## Non-Hosted Session SOP

- User scans a QR code to join the session. The session is open play and anyone eligible can join without a skill-level
  requirement; the trusted join flow confirms the user automatically when capacity is available and puts the user on the
  waitlist when the session is full.
- User can view the list of participants and their current skill levels from the `skills` table

## Hosted Session SOP

- PikaCircle creates session with all the details, and appoints the host. The session will check for the skill level
  required to join the session, and whether the session is open to all skill levels or not
- When users join the session, they can only join if their current hosted-host/admin-provided skill level matches the
  required skill level for the session (or if the session is open to all skill levels)
- Host can view the list of participants and their current skill levels, and can approve or reject non-QR participants
  if autoApprove is false. QR-code joins are confirmed automatically when capacity is available and waitlisted when
  full.
- Host/admin provides or updates the user's skill level manually for the MVP. Hosts may record sessions and use PB
  Vision outside PikaCircle as an operational aid, but users do not upload recordings to the app and PikaCircle does not
  automatically update skill graphs from PB Vision yet
- After the session, host can view the attendance history and reviews for the session

## Gamification & Reputation

PikaCircle uses a **three-axis player model**. Each axis is independent and must not collapse into another:

1. **Spending Membership** (`bronze` → `silver` → `gold` → `platinum` → `GOAT`) — based on net lifetime paid credits.
   Stored in `users.membership_level_id`. Already implemented.
   See `docs/app workflows/membership-level-credit-workflow.md`.
2. **Skill Level** (`beginner` / `intermediate` / `competitive`) — host/admin assigned ability gate for session joins.
   Stored in `skills.level`. Already implemented.
   See `docs/app workflows/session-workflow.md`.
3. **Player Level / Reputation** (`Open Player` → `Social Player` → `Trusted Player` → `Competitive Player` →
   `Circle Elite`) — derived from Reliability, Sportsmanship, Skill, Activity, and Social Fit scores. Drives access to
   higher-quality games. **Schema provisioned; V1 workflow not yet implemented.**

The authoritative gamification plan, all three axes, phased scope (V1/V2/V3), provisioned tables, workflows, and
implementation checklists are documented in:

> `docs/app workflows/gamification-system-plan.md`

The gamification system spans four pillars. **Profile completion rewards and referral invite bonuses are first-class
gamification mechanics** (Credits / Utility pillar), not standalone features. Schema and seed rules for both are
already provisioned; trusted functions and UI are pending. Child workflow docs:

- `docs/app workflows/gamification-reward-workflow.md` — Credits/Utility reward engine (profile, referral, hosted-session, streak milestones)
- `docs/app workflows/referral-system-workflow.md` — Referral attribution, invite code lifecycle, abuse prevention

Design principle: gamify **access**, not activity. Reward weekly real play. No daily login streaks.

## Not release yet

- Marketplace
- Vacations
- Leagues — future V2/V3 gamification (PCL, Club League, Club Profiles); not MVP
- Datings (Social Events)
- Clubs / PCL / Fantasy PCL — future V2/V3 gamification; not MVP unless separately promoted

### ToDos

- [ ] Implement verify email function using resend provider in messaging
- [ ] Implement Whatsapp phone number verification
- [ ] Implement LinkedIn API integration for job title verification
- [x] Implement Google SSO login
- [ ] Implement Apple SSO login
- [ ] Implement get job title from LinkedIn
- [ ] Implement DUPR
- [ ] Implement PB Vision
- [ ] Implement payment gateway
- [ ] Implement Google Map API for location search and display
- [ ] Implement notification system for session reminders and updates using Firebase Cloud Messaging
