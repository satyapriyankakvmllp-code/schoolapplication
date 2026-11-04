# Admissions Module — Comprehensive Blueprint & Implementation Roadmap

**Document Version:** 1.0.0  
**Date:** October 24, 2026  
**File Location:** `docs/ADMISSION_MODULE.md`  
**System Identity:** EduPulse — Enterprise K-12 Institutional Management Platform  

---

## High-Level Role Architecture

The Admissions Module spans 4 primary operational stakeholders:
1. **Front-Desk Officer (Admissions Console)** *(Active Focus)*
2. **Parent & Guardian Portal** *(Self-Service & Verification)*
3. **School Administrator & Principal** *(Approval Authority & Policy)*
4. **Finance & Accounts Officer** *(Fee Collection & Clearance)*

---

# 1. Front-Desk Officer Workspace

The Front-Desk Officer serves as the primary operational intake gate for all admissions—handling walk-in families, telephonic inquiries, assisted application submissions, document physical-to-digital verification, interview panel scheduling, pre-screening completeness quality checks, student ID badge generation, and admissions funnel telemetry.

Below are the **5 Core Implementation Phases** derived directly from the institution's specification matrix:

---

### Phase 1: Domain Models, State Management & Validation Engine
*Foundation layer establishing strict models, Riverpod state notifiers, duplicate checking, and validation schemas.*

- **1.1 Inquiry State Machine**:
  - Implement full 6-stage lifecycle: `New`, `Contacted`, `Interview Scheduled`, `Application Started`, `Converted`, `Closed`.
  - Add inquiry timeline tracking (call logs, parent callback reminders, timestamped notes).
- **1.2 Duplicate Lead Detection Engine**:
  - Real-time indexing of applicant name, parent mobile number, and email.
  - Generates soft-warning banner when duplicate leads or existing student records are matched.
- **1.3 Ticket Routing State Machine**:
  - Unique Ticket Generator: `ADM-2026-XXXX`.
  - Status progression: `PENDING_REVIEW` → `DOCS_PENDING` → `UNDER_VERIFICATION` → `INTERVIEW_SCHEDULED` → `PRE_SCREEN_PASSED` → `APPROVED` / `REJECTED`.
- **1.4 Interview Assessment & Rubric Entity**:
  - Standardized scoring schema (Academic Aptitude, Behavioral Observation, Language & Communication, Guardian Alignment).
  - Categorical outcomes: `Recommended`, `Conditional`, `Waitlist`, `Not Recommended`.
- **1.5 Application Completeness Gatekeeper Model**:
  - Automated checklist evaluation: Demographic mandatory fields, verified documents count, recorded interview evaluation, and registration fee clearance.

---

### Phase 2: Inquiry Intake & Lead Pipeline Management *(Excel Rows 1 & 2)*
*Frontline lead capture for walk-ins, phone calls, and web inquiries with proactive follow-up tracking.*

- **2.1 New Inquiry Intake Modal & Form (Row 1)**:
  - Fields: Student Legal Name, Requested Class/Grade, Guardian Name, Primary Mobile Number, Email Address, Residential Area, Lead Source (`Walk-In`, `Phone Call`, `Website Lead`, `Parent Referral`), Notes.
  - Live validation: Phone format, required fields, inline duplicate alert.
- **2.2 Visual Pipeline & Lead Kanban Board (Row 2)**:
  - Multi-column pipeline view grouping inquiries by status.
  - Quick action to log a phone interaction or set a follow-up reminder date.
  - Status filter chips, search by parent/student name or grade.
- **2.3 One-Click "Convert to Application" Action**:
  - Migrates all captured lead fields straight into the Assisted Application Form without re-typing.

---

### Phase 3: Assisted Application Wizard & Ticket Dispatch *(Excel Rows 3, 4, 7, 8, 9)*
*4-step wizard allowing front-desk staff to capture complete student and guardian profiles for walk-ins.*

- **3.1 Step 1 — Student Demographics (Row 7)**:
  - First, Middle, and Last Legal Name; Date of Birth with auto-calculated age; Gender; Blood Group; Mother Tongue; Religion & Category.
  - Previous School History: Prior School Name, Affiliation Board (CBSE/ICSE/State), Last Grade Passed, Aggregate Score / Grade, TC Date.
- **3.2 Step 2 — Guardian & Emergency Contacts (Row 8)**:
  - Multi-Guardian Support: Father, Mother, and optional Local Guardian cards.
  - Occupation, Annual Income, Workplace Address, Mobile Number, and Email.
  - Radio/Toggle for **Primary Alert Contact** (receives all school SMS, attendance, and emergency calls).
- **3.3 Step 3 — Document Attachment Manager (Row 9)**:
  - Upload slots for: Birth Certificate, Transfer Certificate (TC), Previous Year Report Card, Student Passport Photo, Parent ID Proof (Aadhaar/Passport).
  - Live preview thumbnails, file size validation (< 5 MB), and missing mandatory document warnings.
- **3.4 Step 4 — Review, Ticket Generation & Dispatch (Rows 3 & 4)**:
  - Summary review sheet with draft-save capability.
  - Anti-duplicate submission protection.
  - Submits ticket into `PENDING_REVIEW` state, routes notification to Principal/Admin, and displays printable submission receipt with application reference number.

---

### Phase 4: Document Verification Queue, Interview Scheduler & Pre-Screening Gate *(Excel Rows 10, 11, 12, 13)*
*Operational processing desk ensuring file authenticity, panel coordination, and quality enforcement before executive sign-off.*

- **4.1 Document Verification Queue & Viewer (Row 10)**:
  - Dedicated verification table with status filter: `Pending`, `Verified`, `Rejected / Needs Re-upload`.
  - In-app document inspection modal (zoom, rotate, view metadata).
  - Tri-state review actions: `Mark Verified`, `Reject` (with mandatory rejection reason code), `Request Resubmission`.
  - Audit trail logging the reviewing officer ID, date, and review remarks.
- **4.2 Conflict-Free Interview Scheduler (Row 11)**:
  - Interactive calendar & slot booking system.
  - Configures date, time slot, panel members/teachers, and room/venue (`Admissions Room 101`, `Principal Office`, etc.).
  - Schedule collision prevention: Blocks double-booking the same room or panel teacher within identical time blocks.
  - Dispatches automated confirmation badge/notice for guardians.
- **4.3 Interview Assessment & Result Logging (Row 12)**:
  - Standardized outcome entry form for panel interviewers.
  - Rubric ratings (1–5 scale), interviewer feedback, and recommendation status (`Recommended`, `Conditional`, `Waitlist`, `Not Recommended`).
- **4.4 Application Completeness Pre-Screening Gate (Row 13)**:
  - Interactive gatekeeper checklist displaying verification pass/fail status across:
    1. Mandatory Demographic Fields Complete
    2. Required Documents Verified by Staff
    3. Interview Assessment Logged & Passing
    4. Registration Fee Cleared
  - Blocks "Forward to Admin for Approval" button if mandatory items are unverified (unless an authorized administrative override note is recorded).

---

### Phase 5: Student ID Badge Studio & Funnel Analytics *(Excel Rows 20 & 21)*
*Fulfillment, credential issuance, and managerial reporting.*

- **5.1 Student ID Card Generator & Studio (Row 20)**:
  - Live dual-sided badge preview:
    - **Front**: Institution Crest, Student Photo, Full Name, Admission Number, Class & Section, Blood Group, Academic Session.
    - **Back**: Father/Guardian Name, Emergency Phone, Full Address, Barcode / Scannable QR Code.
  - Reprint control with duplicate badge warning.
  - Browser-native print dispatch with standard CR80 ID card layout formatting.
- **5.2 Admissions Funnel Telemetry & Analytics Dashboard (Row 21)**:
  - Executive conversion KPI cards:
    - Total Leads / Inquiries
    - Applications Initiated vs. Submitted
    - Pending Document Verifications
    - Completed Interviews
    - Final Confirmed Admissions & Conversion Ratio
  - Date Range Filtering (`Today`, `This Week`, `This Month`, `Academic Year 2026-27`).
  - Source Breakdown (Walk-in vs. Web Lead vs. Referral).
  - Exportable CSV/PDF summary report for institutional leadership.

---

### Phase 6: Automated Testing & Cross-Platform Verification
- Unit & Riverpod controller test suites for inquiry workflows and validation logic.
- Mobile viewport compliance testing (strict **390 × 844** with zero `RenderFlex` overflow exceptions).
- Cross-role access boundary verification (ensuring Teachers, Students, and Finance roles cannot access Front-Desk verification endpoints).

---

## 2. Parent & Guardian Portal *(Future Reference)*
- Self-service online child admission application form.
- Real-time application status tracker with ticket number.
- Self-upload and replacement for rejected documents.
- Interview slot acknowledgement and digital ID badge pass preview.

---

## 3. School Administrator & Principal Review *(Future Reference)*
- Executive decision inbox with pre-screened admission tickets.
- Class & section capacity allocation.
- Roll number assignment and scholarship concessions.
- Final approval / rejection sign-off.
