# School Management System (EduPulse) — Implementation & Architecture Guide

## 1. Project Overview & Technology Stack
EduPulse is a modern, responsive School Management System (SMS) built with **Flutter (Web, Desktop, Mobile)** and **Riverpod** state management. It provides end-to-end administration for admissions intake, student pipelines, student records, profile management, and role-based academic workflows.

- **Framework**: Flutter 3.x (Web, Windows, Mobile responsive)
- **State Management**: Flutter Riverpod (`AsyncNotifierProvider`, `StateProvider`, `FutureProvider.family`)
- **Design System**: Custom clean ERP/SaaS aesthetic, dark mode & light mode toggle, glassmorphic accents, and fully responsive layouts adapting from 360px phones up to 4K desktops.

---

## 2. Completed Milestones & Feature Breakdown

### Phase 1: Core Foundation & Data Layer
1. **Domain Models**:
   - `UserModel`: Base identity, credentials, roles (`admin`, `teacher`, `student`, `parent`, `admissions`, `finance`), contact details, and account status.
   - `StudentProfileModel`: Admission numbers, roll numbers, academic year, class & section, house allocation, medium of instruction, and national ID.
   - `ParentProfileModel`: Father, Mother, and Guardian contact linking with single-parent primary contact and authorized fee payer toggles.
   - `AdmissionDocumentModel`: File metadata, verification status, file size, type (`pdf`, `image`), and timestamps.
   - `StudentAdmissionModel`: Composite aggregate bundling user, student profile, parents/guardians, and documents.
   - `AdmissionRequestModel`: Inflow pipeline entity representing prospective student applications with conversion methods to draft admission profiles.

2. **Repository Architecture (`AdmissionsRepository`)**:
   - In-memory reactive caching backed by mock Indian localized datasets (e.g., Aarav Sharma, Ananya Iyer, Reyansh Patel).
   - CRUD capabilities: `getAdmissions()`, `getAdmissionById()`, `saveAdmission()`, `suspendAdmission()`, `getAdmissionRequests()`, and request status updates (`approveRequest`, `rejectRequest`).
   - Clean state guarantee: Returns `null` when an ID is unselected, preventing forced dummy fallbacks on page refresh.

3. **Riverpod State Controllers (`admissions_controller.dart`)**:
   - `admissionsListProvider`: Async notifier managing live admission records.
   - `selectedStudentIdProvider`: Active student pointer (defaults to `null` on startup/refresh).
   - `studentDetailsProvider`: Family provider watching single-student details reactively.
   - `searchResultsProvider` & `studentSearchQueryProvider`: Real-time debounced search across names, admission IDs, classes, and roll numbers.
   - `admissionRequestsListProvider`: Application intake pipeline state notifier.
   - `prefilledAdmissionDraftProvider`: Transient bridge transferring approved pipeline applications directly into the registration intake form.

---

### Phase 2: Shell Layout & Responsive Navigation (`edupluse_scaffold.dart`)
1. **Collapsible Sidebar**:
   - Expanded on laptop/desktop viewports (>= 900px) with icons and labels.
   - Collapsible to compact icon-only mode with tooltips.
   - Integrated as a slide-out drawer on tablet and mobile viewports (< 900px).
2. **Global Header**:
   - Institution branding (`EduPulse`).
   - Global quick-search input with modal student lookup.
   - Real-time Light / Dark theme toggling.
   - Notification and locale badges.
3. **Navigation Groups**:
   - **Students** (Accordion dropdown with sub-items):
     - `Student Pipeline` (Intake matrix)
     - `Add New Student` (New registration)
     - `Edit Student` (Profile updates)
     - `Student Details` (360° student record view)
     - `Student List` (Filterable directory table)
   - **Teachers**, **Guardian**, **Classes**, **Examinations**, **Fees Collection**, **Attendance**, **Leaves**, **Certificate**, **Library**, **Accounts**.

---

### Phase 3: Student Pipeline / Admissions Intake (`student_categories_screen.dart`)
1. **Metrics & Matrix Overview**:
   - KPI counters for total admissions, approved intakes, in-review records, and rejected applications.
2. **Filterable Application Pipeline**:
   - Category filtering: All Requests, Pending, Review, Approved, and Rejected.
   - Responsive cards with applicant photo, name, assigned grade, parent contact, and submission timestamps.
3. **Interactive Actions**:
   - View details modal showing academic history, previous school records, and submitted certificates.
   - Single-click **"Approve & Fill Admission"**: Automatically generates an official admission number preview (`ADM-2026-XXXX`), seeds `prefilledAdmissionDraftProvider`, and routes directly to the student registration form.
4. **Mobile Responsiveness**:
   - Handled layout constraints so card rows stack smoothly on phone screens without overflow errors.

---

### Phase 4: Student Details Screen (`student_details_screen.dart`)
1. **Clean Initial / Refresh State**:
   - On initial launch or page refresh, renders a responsive **Empty State View** ("No Student Selected") instead of hardcoding a test student.
   - Directory dropdown: `"Choose student from directory..."`.
   - Quick-Select Action Chips for recent students.
   - Top action button: `"All Admissions (N)"` opening a searchable modal directory.
2. **Comprehensive Profile View (When Populated)**:
   - Header with student photo avatar, status badge (`Active`), class, section, roll number, and admission ID.
   - Action buttons: `"Suspend"` and `"Edit Profile"`.
   - Personal information card: gender, date of birth, blood group, academic year, phone, and email.
   - Parent & Guardian section: Father, Mother, and designated primary guardian contact cards.
   - Tabbed secondary panels: `Student Details`, `Attendance`, `Leave`, `Fees`, `Exam`, and `Library`.
3. **Seamless Edit Redirection**:
   - Clicking `"Edit Profile"` navigates directly to `Edit Student` with that student's complete information pre-populated for editing.

---

### Phase 5: Add Student & Edit Student Form (`add_student_form_screen.dart`)
1. **Dual-Mode Screen Architecture**:
   - Handles both **New Intake** (`addNewStudent`) and **Edit Existing Profile** (`editStudent`).
2. **Progressive 4-Step Intake Flow**:
   - **Step 1: Student Demographics & Identification**:
     - Photo uploader with camera placeholder, image upload, and fulfilled status badge.
     - Student ID (read-only with lock indicator).
     - First Name, Last Name, Date of Birth picker, Gender, Blood Group, Phone, and Current Address.
     - Clean form state: Starts completely empty on fresh intake or unselected edit mode.
   - **Step 2: Academic & Class Placement**:
     - Admission number, Admission date picker, Academic year selector.
     - Class, section, roll number, medium of instruction, house/group, and second language.
   - **Step 3: Guardian & Contact Linking**:
     - Primary Guardian: Full name, relationship, phone, email, and residential address.
     - Secondary Guardian: Full name, relationship, phone, email.
     - Radio/checkbox controls for **Primary Contact** and **Authorized Fee Payer** (structured so both parents cannot conflict on single-payer requirements).
   - **Step 4: Document Verification & Declaration**:
     - Birth certificate upload box.
     - Previous academic marksheets / record upload.
     - Government ID selector (Aadhaar / National ID / Passport) with ID number and expiry date picker.
     - Authenticity declaration and legal certification toggles.
3. **Edit Mode Student Selector**:
   - Displays a dedicated selector bar at the top of Edit Student:
     - Directory dropdown allowing switching between enrolled students.
     - Quick-select chips for rapid switching.
     - `"Clear / Blank Form"` action to empty all controllers safely without element leaks.
4. **Form Controls & Date Handlers**:
   - All `TextEditingController` instances manage lifecycle cleanly without memory leaks or deactivated element exceptions.
   - Date pickers support nullable values with placeholder hints (`Select Date of Birth`) and `Expanded` text wrappers to prevent mobile horizontal overflow.

---

### Phase 6: Code Quality, Testing & Verification
1. **Automated Test Suite (`test/widget_test.dart` & `test/student_categories_test.dart`)**:
   - **100% Passing Tests**:
     - Mobile layout rendering at 390×844 (no overflow, drawer interaction, theme switching).
     - Tablet / Desktop layout rendering at 1280×800 (sidebar collapse, expand, navigation).
     - Clean state validation: Verifies Student Details and Edit Student start empty on launch, populate interactively upon selection, navigate to Edit Profile with data, and clear back to empty.
     - Pipeline Kanban matrix filtering and detail modals.
2. **Static Analysis**:
   - `dart analyze lib`: **0 errors and 0 warnings**.
3. **Cross-Device Responsiveness**:
   - Tested across Mobile (360px–480px), Tablet (768px–1024px), and Desktop (1200px+).

---

## 3. Directory & File Reference

| File Path | Description |
| :--- | :--- |
| `lib/main.dart` | Application entrypoint, theme management, and primary routing switch. |
| `lib/core/theme/app_theme.dart` | Light and Dark mode palette definitions, typography, button styles. |
| `lib/core/constants/app_constants.dart` | Global string identifiers, default branding, and dimensions. |
| `lib/features/admissions/data/models/` | Data transfer models (`user`, `student`, `parent`, `document`, `admission_request`). |
| `lib/features/admissions/data/repositories/admissions_repository.dart` | Repository interface and mock implementation with localized mock data. |
| `lib/features/admissions/presentation/controllers/admissions_controller.dart` | Riverpod providers for list management, details, and filtering. |
| `lib/features/admissions/presentation/widgets/edupluse_scaffold.dart` | Main responsive scaffold with sidebar, topbar, and search modal. |
| `lib/features/admissions/presentation/screens/student_categories_screen.dart` | Application intake pipeline & review screen. |
| `lib/features/admissions/presentation/screens/student_details_screen.dart` | 360° student profile screen with empty state & directory modal. |
| `lib/features/admissions/presentation/screens/add_student_form_screen.dart` | 4-step intake registration and profile edit screen. |
| `lib/features/admissions/presentation/screens/student_list_screen.dart` | Searchable directory table of all enrolled students. |
| `test/widget_test.dart` | End-to-end responsive widget test suite. |
