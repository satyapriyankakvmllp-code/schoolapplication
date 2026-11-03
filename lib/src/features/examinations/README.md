# Examination Module (Screen 1: Exam Schedules)

This module implements Screen 1 of the Examination feature for the EduPulse School Management System, encompassing **Exam List (1A)**, **Create/Edit Exam (1B)**, and **Exam Details Overview (1C)**, built as a zero-page-switch modal workflow over the Exam List screen.

---

## 1. File Structure & Locations

```
frontend/
├── assets/
│   └── data/
│       ├── global.json                  # Academic years, exam types, users, active user
│       └── examination.json             # Seed data with 5 sample exams and papers
├── lib/
│   ├── main.dart                        # Shell routing & app initialization
│   └── src/
│       ├── commonwidgets/
│       │   └── edupluse_scaffold.dart   # Responsive layout, sidebar & navigation
│       └── features/
│           └── examinations/
│               ├── application/
│               │   ├── examination_access.dart    # Providers & permission matrix
│               │   └── exam_controller.dart       # State notifier, search/filters, summary stats
│               ├── data/
│               │   ├── examination_local_datasource.dart # Dual persistence (File / SharedPreferences)
│               │   └── exam_repository.dart       # Enforces business rules & mutations
│               ├── domain/
│               │   ├── exam_schedule_model.dart   # ExamSchedule with dynamic status & linked counts
│               │   ├── exam_paper_model.dart      # ExamPaper model for count & boundary checks
│               │   ├── exam_type_model.dart       # ExamType definition
│               │   ├── global_setup_model.dart    # GlobalSetup, GlobalUser
│               │   └── examination_actor.dart     # Role-based permissions matrix
│               └── presentation/
│                   ├── exam_list_screen.dart      # Screen 1A (List, filters, summary, table/cards)
│                   ├── exam_form_screen.dart      # Screen 1B (Create/Edit modal dialog with validations)
│                   ├── exam_details_screen.dart   # Screen 1C (Modal dialog with overview & disabled tabs)
│                   └── widgets/
│                       ├── exam_card_item.dart    # Mobile / Student card view
│                       ├── exam_filter_bar.dart   # Search, Year, Type, Status filters
│                       ├── exam_status_badge.dart # Colored status badges
│                       ├── exam_summary_cards.dart# Total, Upcoming, Ongoing, Completed metrics
│                       ├── cancel_exam_dialog.dart# Required-reason cancellation dialog
│                       └── delete_exam_dialog.dart# Typed confirmation dialog with linked data counts
└── test/
    └── features/
        └── examinations/
            └── examination_module_test.dart       # 21 automated unit & business rule tests
```

---

## 2. How JSON Persistence Works (Dynamic, No Hardcoded Mock Data)

The application utilizes dynamic JSON persistence:
1. **Asset Bundle as Seed Data**:
   - `assets/data/examination.json` and `assets/data/global.json` are packaged with the app as initial seed data.
2. **First Launch Seeding**:
   - **Native (Windows, macOS, Linux, iOS, Android)**: On first run, files are copied from assets into the local documents directory via `path_provider` (`getApplicationDocumentsDirectory()`). Subsequent operations read and write **only** to `${documentsDir}/examination.json` and `${documentsDir}/global.json`.
   - **Flutter Web**: On web platforms where direct local filesystem access is restricted, `SharedPreferences` acts as the persistent store. On first launch, the seed JSON from assets is loaded into `SharedPreferences`.
3. **Dynamic UI Refresh**:
   - Every mutation (`createExam`, `updateExam`, `cancelExam`, `deleteExam`) commits directly to the local JSON copy and immediately notifies the Riverpod `AsyncNotifierProvider` (`examListControllerProvider`), causing all summary cards, tables, badges, and detail views to refresh reactively.

---

## 3. How to Reset Demo Data

A built-in **"Reset demo data"** button is provided:
- Located directly in the top sub-bar of the Examinations screen next to the Role Switcher.
- Clicking **"Reset demo data"** displays a confirmation dialog.
- Upon confirmation, `LocalExamRepository.resetDemoData()` re-reads the original seed `assets/data/examination.json` and overwrites the local copy, resetting all exams, paper counts, and statuses back to their original demonstration state.

---

## 4. How to Switch Roles (Debug Role Switcher)

A **Switch Role** dropdown is located in the top sub-header of the Examinations screen:
- **Available Roles from `global.json`**:
  - `u1`: **Admin (ADMIN)** — Full management access (create, edit in any status, cancel if planned/ongoing, delete in any status).
  - `u2`: **Principal (PRINCIPAL)** — Full management access identical to Admin.
  - `u3`: **Teacher (TEACHER)** — Read-only access to exam list and exam details.
  - `u4`: **Class Incharge (CLASS_INCHARGE)** — Read-only access to exam list and details.
  - `u5`: **Student (STUDENT)** — Read-only simple card layout; automatically hides `PLANNED` exams that have zero question papers.
  - `u6`: **Parent (PARENT)** — Read-only simple card layout; automatically hides `PLANNED` exams with zero question papers.
- Selecting any role from the dropdown immediately switches the active user and re-evaluates both UI action visibility and repository permission checks.

---

## 5. Business Rules Enforced

1. **New Exams**: Always created with `PLANNED` status.
2. **Computed Dynamic Status**:
   - `PLANNED` becomes `ONGOING` when today reaches `start_date`.
   - `ONGOING` becomes `COMPLETED` when today passes `end_date`.
   - `CANCELLED` never changes automatically.
3. **Manual Cancellation (Rule 3)**:
   - Allowed ONLY when status is `PLANNED` or `ONGOING`.
   - Requires a cancellation reason in a modal dialog.
   - Sets status to `CANCELLED` and preserves existing papers.
4. **Editing in Any Status (Rule 4)**:
   - `ADMIN` and `PRINCIPAL` can Edit an exam in **ANY status** (`PLANNED`, `ONGOING`, `COMPLETED`, `CANCELLED`) at any time.
   - All fields (exam name, type, academic year, start date, end date, description) are editable regardless of status.
   - Status remains automatic by date unless previously manually cancelled.
   - Other roles remain strictly read-only.
5. **Date Validations**:
   - `end_date` must be on or after `start_date`.
   - `start_date` cannot be in the past when creating a new exam.
6. **Unique Exam Name**: Duplicate `exam_name` in the same `academic_year` is rejected.
7. **Date Overlap Warning**: Non-blocking warning banner shown if dates overlap another exam of the same `exam_type`.
8. **Deletion in Any Status & Cascade (Rule 8)**:
   - `ADMIN` and `PRINCIPAL` can Delete an exam in **ANY status**.
   - If the exam has linked data (papers, hall tickets, attendance, marks, report cards), the modal dialog displays the exact counts (*"This exam has 2 papers. Deleting will remove all of them. This cannot be undone."*) and requires typing the exact exam name to confirm deletion.
   - If the exam has 0 linked records, direct confirmation is enabled.
   - Deleting cascades and removes the exam and all linked records across all tables simultaneously.
9. **Paper Date Boundaries**: Date changes are blocked if existing question papers fall outside the new date range.

---

## 6. UI Architecture: Zero-Page-Switch Modal Workflow

- **Create / Edit Exam**: Opens as a modal dialog over the list (`ExamFormScreen.showAsDialog`).
- **Exam Details Overview**: Opens as a large dialog (`ExamDetailsScreen.showAsDialog`) with tabs (`Overview`, and disabled `Exam Papers`, `Hall Tickets`, `Marks`, `Results`). Header card has direct Edit, Cancel, and Delete buttons.
- **Cancel Confirmation**: Opens as a modal dialog (`CancelExamDialog.show`).
- **Delete Confirmation**: Opens as a modal dialog (`DeleteExamDialog.show`) with linked records count and typed exam name confirmation.
- The user never leaves the Exam List page; closing or saving in any dialog immediately refreshes the exam table, cards, and summary stats.
