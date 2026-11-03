# EduPulse Examination Module (Screens 1 to 8)

Comprehensive documentation for the Examination feature of EduPulse School Management System, encompassing **Exam Schedules (Screen 1)**, **Exam Timetable (Screen 2)**, **Hall Tickets (Screen 3)**, **Exam Attendance (Screen 4)**, **Marks Entry (Screen 5)**, **Marks Review & Approval (Screen 6)**, **Results (Screen 7)**, **Report Cards (Screen 8)**, and **Syllabus / Exam Pattern / Question Papers**.

---

## 1. Architecture & Master Data Integration

### Zero-Duplicate Master Data Architecture
As mandated, the Examination module **never** creates or stores duplicate copies of master data:
- **Classes & Sections**: Loaded dynamically from `assets/data/classes.json`.
- **Subjects**: Loaded dynamically from `assets/data/classes.json` and `academic_setup.json`.
- **Rooms / Classrooms**: Loaded dynamically from `assets/data/classes.json` (classrooms list) and augmented with 5 dedicated exam hall rooms in `assets/data/examination.json`.
- **Teachers / Invigilators**: Loaded dynamically from `assets/data/staff_global.json` and `users.json`.
- **Students**: Loaded directly from `assets/data/students_and_parents.json` filtered strictly by Class & Section.

Helper queries in `ExamReferenceData` (`lib/src/features/examinations/domain/exam_reference_model.dart`):
- `sectionsForClass(classId)`: Cascades available sections.
- `subjectsForClass(classId)`: Cascades subjects allocated to the selected class.
- `defaultTeacherFor(classId, sectionId, subjectId)`: Defaults the invigilator / subject teacher to the allocated faculty.

---

## 2. Rename: Exam Paper → Exam Timetable

- **Renamed Across Codebase**:
  - Model: `ExamTimetableEntry` in `lib/src/features/examinations/domain/exam_timetable_model.dart`.
  - Backwards-compatibility alias: `typedef ExamPaper = ExamTimetableEntry` in `lib/src/features/examinations/domain/exam_paper_model.dart`.
  - Repository: `ExamTimetableRepository` (aliased as `ExamPaperRepository`).
  - Storage migration: Supports both legacy `exam_papers` and modern `exam_timetables` keys in local JSON persistence.
  - UI Labels & Routes: "Exam Timetable (N entries)", "+ Add Exam Timetable Entry", "Save Exam Timetable Entry".
- **Fields**:
  - `id` (PK)
  - `exam_schedule_id` (FK to ExamSchedule)
  - `class_section_id` (FK)
  - `subject_id` (FK)
  - `exam_date` (Date string YYYY-MM-DD)
  - `start_time`, `end_time` (24-hour time HH:mm)
  - `duration_minutes` (Auto-calculated duration, e.g., "3h 0m", "1h 30m")
  - `max_marks` (Number > 0)
  - `passing_marks` (0 <= passing_marks <= max_marks)
  - `invigilator_id` (FK to Teacher, optional)
  - `room_id` (FK to Room, optional)
  - `status` (`SCHEDULED`, `COMPLETED`, `CANCELLED`)

---

## 3. Top Navigation Inside Exam Details

When viewing an exam, the screen header provides a quick section switcher dropdown:
1. **1. Exam List**: Navigates back or focuses on the general schedule list overview.
2. **2. Exam Timetable**: Directly switches to the active exam's timetable tab.

---

## 4. Business Rules Enforced

| Rule # | Description | Enforced In |
|---|---|---|
| **Rule 1** | `exam_date` must fall between the exam's `start_date` and `end_date`. | Repository & Form Dialog |
| **Rule 2** | `end_time` must be after `start_time`. | Repository & Form Dialog |
| **Rule 3** | `passing_marks` cannot exceed `max_marks` (and `max_marks` > 0). | Repository & Form Dialog |
| **Rule 4** | A class section cannot have two timetable entries that overlap in time on the same date. | Repository & Form Dialog |
| **Rule 5** | An invigilator cannot be assigned to two timetable entries that overlap in time across any exam. | Repository & Form Dialog |
| **Rule 6** | A room cannot be used by two different classes at overlapping times. | Repository & Form Dialog |
| **Rule 7** | Subjects offered are limited to allocated subjects for the selected class; invigilator defaults to subject teacher. | Reference Data & UI |
| **Rule 8** | Timetable entries can only be added, edited, or deleted while exam is `PLANNED` or `ONGOING`. Locked if `COMPLETED` or `CANCELLED`. | Repository & UI |
| **Rule 9** | Cancelling an exam cancels all its timetable entries. | Repository Cascade |
| **Rule 10** | Changing an exam's dates is blocked if any timetable entry falls outside the proposed new date boundaries. | Repository Validation |
| **Rule 11** | Adding or removing a timetable entry updates the exam's `paper_count` immediately. | Repository & Riverpod Controller |

---

## 5. Screen Highlights & Functional Flows

### Screen 2: Exam Timetable
- **Grouping**: Grouped by date (e.g. `Mon, 02 Nov 2026`).
- **Cards**: Show Subject, Class & Section, Start/End time, auto-calculated duration, Room, Invigilator, Max/Passing marks, and Status badge.
- **Form Dialog**: Outlined input fields with visible borders, cascading class dropdown (resets section & subject), live duration badge, top error alert box.

### Screen 3: Hall Tickets
- **Cascading Filter**: Exam → Class → Section → Loads students automatically from `students_and_parents.json`.
- **Generation**: Single, Selected, or All students. Duplicate generation is prevented; students without timetable entries are skipped with notification.
- **Preview Dialog**: School header, student details (name, roll, admission number, photo), exam name, timetable matrix (date, subject, time, room), seat number, and barcode verification token.
- **Print / Download**: Direct printable formatted card layout with clean styling.

### Screen 4: Exam Attendance
- Marked per timetable entry; captures `PRESENT` / `ABSENT` per student.
- Absent students automatically propagate to Marks Entry as disabled entries with an `ABSENT` badge.

### Screen 5: Marks Entry
- **Flow**: Exam → Class → Section → Subject → Students loaded automatically.
- **Form State Buffering**: Marks are buffered in local state (NOT saved on every keystroke) and only committed when the user taps "Save Draft" or "Submit".
- **Validation**: Marks cannot be negative, cannot exceed max marks; absent students cannot receive marks; Submit is blocked if any present student has missing marks.
- **Unsaved Changes Guard**: Prompts confirmation if navigating away with uncommitted changes.
- **Status Lifecycle**: `Draft → Submitted → Under Review → Approved / Rejected`.

### Screen 6: Marks Review & Approval
- Reviewer sees: Student name & admission, class, section, subject, max marks, marks obtained, entered by teacher, submitted date, reviewer name, reviewed date, and remarks.
- Actions: `Mark Under Review`, `Approve`, `Reject` (reason mandatory in dialog), and `Bulk Approve` for the entire subject and class.
- Rejected marks unlock for the teacher with the rejection reason; approved marks lock permanently.

### Screen 7 & 8: Results & Report Cards
- **Centralized Grade Scale**: Configured in `GradeScaleConfig` (`A+`, `A`, `B`, `C`, `D`, `E`, `F`) with Grade Points (10.0 to 0.0) and performance categories (*Outstanding, Excellent, Very Good, Good, Average, Needs Improvement*).
- **Strict Approval Prerequisite**: Results calculate strictly from **Approved** marks only.
- **View Modes**: Complete examination, Class-wise, Subject-wise, and Individual student search.
- **Student Detail Modal**: Full subject-wise marks breakdown, total, percentage, GPA, rank, performance badge, attendance status, and pass/fail.
- **Publishing**: Admin/Principal can approve draft report cards and publish them to students and parents.

### Syllabus, Exam Pattern & Question Papers
- **Syllabus**: Class → Subject → Chapters with weightage and topic checklists.
- **Exam Pattern**: Sections (Section A, B, C) with question types, counts, and per-question marks. Automatically validates that section totals sum to the paper's `max_marks`.
- **Question Paper**: Section-wise question builder linked to approved patterns.

---

## 6. UI & Styling Guidelines
- **Theme Color**: EduPulse Green (`0xFF109F83`).
- **Snackbars**: Floating, compact notifications via `flowSnack` (max width 340, 2.5s duration, small typography).
- **Form Fields**: Outlined bordered boxes via `flowDecoration`.

---

## 7. Role Access Control

| Feature / Action | Admin & Principal | Class In-charge | Subject Teacher | Student & Parent |
|---|---|---|---|---|
| Create / Edit Exam | Full Access | Read-Only | Read-Only | Read-Only |
| Add / Edit / Delete Timetable Entry | Full Access | Read-Only | Read-Only | Read-Only (Own Class only) |
| Generate / Print Hall Tickets | Full Access | Full Access (Own Class) | Read-Only | View / Download Own Ticket |
| Marks Entry | Full Access | Full Access (Own Class) | Entry for Own Subjects | Hidden |
| Marks Review / Approval / Reject | Full Access | Full Access (Own Class) | Read-Only | Hidden |
| Calculate Results & Publish Report Cards | Full Access | Read-Only | Read-Only | View Published Results |

---

## 8. Verification & Test Suite

All 35 unit tests pass cleanly:
```bash
flutter test test/features/examinations/
```
- **`examination_module_test.dart` (21 tests)**: Dynamic computed status, creation/edit rules in all statuses, cancellation with reason, deletion with cascade, parent/student visibility filters, overlap warnings.
- **`exam_timetable_rules_test.dart` (14 tests)**: Rules 1 to 6 (date ranges, end time after start, max/passing marks, class clashes, invigilator clashes, room clashes) and Rule 10 (blocking date changes if entries fall outside).

---

## 9. Role-Based Presentation Architecture (Classes Module Pattern)

Following the proven architecture from `lib/src/features/classes/presentation/`, the Examination module does not combine all functionalities into one generic presentation screen. Instead, it provides dedicated, separated presentation screens per role:

```
lib/src/features/examinations/presentation/
├── examinations_hub_screen.dart        # Main router & breadcrumb hub; switches screen by active role
├── admin/
│   └── admin_examinations_screen.dart   # Full administrative console (Schedules, CRUD, approvals, publishing)
├── teacher/
│   └── teacher_examinations_screen.dart # Faculty workspace (Invigilation duties, marks entry, question papers, attendance)
├── student/
│   └── student_examinations_screen.dart # Student self-service hub (Class timetable, digital hall ticket, published results, syllabus)
├── parent/
│   └── parent_examinations_screen.dart  # Parent portal with multi-child context switcher (Timetables, hall tickets, report cards, exam guidelines)
├── tabs/                               # Shared operational workflow tabs
└── widgets/                            # Reusable presentation widgets & dialogs
```

### Role Screen Specifications:
1. **Admin Console (`AdminExaminationsScreen`)**:
   - Metric summary cards (Total Exams, Scheduled Papers, Pending Approvals, Published Cards).
   - Filter bar (search, academic year, exam type, status).
   - Create and Edit exam dialogs across all statuses with full validation.
   - Cancel exam dialog requiring explicit reason and setting status to `CANCELLED`.
   - Delete exam dialog with cascading cleanup.
   - Comprehensive multi-tab operations (Timetable management, Batch Hall Tickets, Marks Approval/Rejection, Result Compilation, Syllabus & Pattern setup).

2. **Teacher Workspace (`TeacherExaminationsScreen`)**:
   - Sub-tab 1: **Invigilation & Duties** – Filterable by assigned exams, showing room numbers and timings.
   - Sub-tab 2: **Marks Entry** – Class, section, and subject selection with local buffered draft state, unsaved changes alert, and validation against max marks.
   - Sub-tab 3: **Question Paper** – Upload and structure section-wise question papers.
   - Sub-tab 4: **Attendance Marking** – Daily present/absent/malpractice marking per timetable entry.

3. **Student Hub (`StudentExaminationsScreen`)**:
   - Sub-tab 1: **Timetable** – Filtered strictly to enrolled class and section.
   - Sub-tab 2: **Hall Ticket** – Digital hall ticket with printable preview, barcode token, seat number, and instructions.
   - Sub-tab 3: **Results** – Real-time view of published report cards with grades, GPA, class rank, and faculty remarks.
   - Sub-tab 4: **Syllabus** – Subject chapter weightage and exam topics.

4. **Parent Portal (`ParentExaminationsScreen`)**:
   - **Child Context Switcher**: Seamlessly toggles between linked children (e.g., Aarav Sharma, Diya Patel).
   - Sub-tab 1: **Child's Timetable** – Specific schedule for the selected child.
   - Sub-tab 2: **Hall Ticket** – Child's hall ticket preview and download.
   - Sub-tab 3: **Report Card** – Official evaluation report with performance badges, GPA, rank, and teacher observations.
   - Sub-tab 4: **Exam Rules** – Institutional exam rules, reporting timings, and parent guidelines.

---

## 10. Unified JSON Storage & Global Master Data Reuse

All examination data is unified and stored in:
- `assets/data/examination/examination.json` (and synchronized with fallback paths `assets/data/examination.json` and `assets/data/examinations/examinations.json`).
- Shared master records (Classes, Sections, Subjects, Teachers, Classrooms, and Students) are read dynamically from `assets/data/global_school_database.json`.
- Zero duplicate master data is created or persisted.

