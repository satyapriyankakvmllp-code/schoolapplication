# Agent Memory & Behavioral Guidelines

## 1. Critical Thinking & Requirements Invariants (User Mandate)
- **Do Not Blindly Agree**: Never respond with passive agreement or immediate "Yes". Always critically evaluate requirements, technical feasibility, and architectural consistency.
- **Deep Requirement Probing**: Clarify ambiguity, dependencies, and entity relationships before proposing solutions or writing implementation code.
- **Constructive Consultation**: Offer superior alternatives, identify trade-offs, and suggest enhancements where relevant.
- **Step-by-Step Questioning**: Use interactive questions (`ask_question`) one at a time to resolve decisions collaboratively.

## 2. Staff Management Module Architecture (`src/features/staff`)
Refer to [STAFF_MODULE_SPECIFICATION.md](file:///c:/Users/rinku/OneDrive/Desktop/KVM/schoolmgnt/frontend/STAFF_MODULE_SPECIFICATION.md) for full details.

- **15 Required Attributes**:
  1. `Staff ID (automatic, STF-2026-XXXX)`
  2. `Full Name`
  3. `Profile Photo (optional upload / avatar)`
  4. `Staff Category (Teaching, Administrative, Support)`
  5. `Designation / Job Title`
  6. `Department`
  7. `Qualification`
  8. `Specialization` *(Teaching category only)*
  9. `Phone Number, Email, Address`
  10. `Date of Joining`
  11. `Employment Type (Permanent, Contractual, Probationary, Part-Time)`
  12. `Assigned Classes & Subjects` *(Teaching category only — Pairing Matrix with Primary Class Teacher toggle)*
  13. `Salary details` *(Admin/HR protected — Basic Monthly, Bank Name, Account No, IFSC, PAN — masked by default)*
  14. `Login Account & Role` *(Optional provisioning of portal credentials and role permissions)*
  15. `Active / Inactive Status`

- **Navigation & Screens**:
  - Replace static `Teachers` with expandable `Staff` sidebar group in `EdupluseScaffold`:
    - `Staff Directory` (`staffList`): Dual view (Table & Card Grid), KPI cards, facet filtering.
    - `Add New Staff` (`addNewStaff`): 4-step wizard with dynamic teaching fields.
    - `Departments & Roles` (`staffDepartments`): Headcount matrix and HOD roster.
  - Staff 360° Profile view with live dual-sided ID badge preview and print dispatch.

- **State & Persistence**:
  - Initial Indian school faculty seed in `assets/data/staff/staff.json`.
  - Session persistence via `SharedPreferences` (`edupulse_saved_staff_records`) through Riverpod AsyncNotifiers.

## 3. UI & Responsive Constraints
- Strictly responsive for phone screens (390x844 physical viewport) with zero render overflow exceptions (`RenderFlex`).
- Maintain uniform styling tokens: `Color(0xFF109F83)`, `Color(0xFF0F172A)`, `Color(0xFF1E293B)`, `Color(0xFF8B5CF6)`.
