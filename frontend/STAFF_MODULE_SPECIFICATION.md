# EduPulse School Management System — Staff Management Module Specification

**Document Version:** 1.0.0  
**Status:** Approved for Implementation  
**Module Identifier:** `features/staff`  
**Primary Interface:** School Administrator Console & Front-Desk Directory  

---

## 1. Executive Summary & Objective

The **Staff Management Module** transitions the platform from a static *"Teachers"* placeholder to a comprehensive, enterprise-grade institutional Human Resource & Faculty Management system. It provides an all-inclusive directory covering **Teaching**, **Administrative**, and **Operational Support** staff members under a unified administrative workflow.

### Key Capabilities
- **Unified Personnel Management**: Manages full profiles for educators, administrators (accountants, receptionists, librarians), and support staff.
- **Dynamic Context-Aware Onboarding**: Automatically reveals academic fields (Subject Specialization, Class-Subject Pairings, Primary Class Teacher assignments) only when a staff member belongs to the **Teaching** category.
- **Sensitive Compensation Security**: Protects salary and banking details with visibility masking and administrative role gating.
- **Integrated System Login Provisioning**: Allows administrators to optionally generate institutional login credentials and assign system access roles during onboarding.
- **Dual-View Enterprise Directory**: Provides both high-density enterprise tabular listing and visual profile card grids with multi-facet filtering (Category, Department, Status, Search).
- **Physical ID Badge Generation**: Generates 2-sided institutional NFC/Barcode staff identification cards with thermal print dispatch.

---

## 2. Comprehensive 15-Field Data Dictionary

The module captures and validates exactly 15 foundational attributes across demographic, institutional, academic, financial, and access layers:

| # | Field Name | Data Type | Mandatory | UI Input Control | Visibility & Conditional Behavior |
| :--- | :--- | :--- | :---: | :--- | :--- |
| **1** | **Staff ID** | `String` | Yes | Auto-generated Read-only Field | Format: `STF-2026-XXXX`. Previews automatically; immutable after creation. |
| **2** | **Full Name** | `String` | Yes | Text Input (First + Last Name) | e.g., *"Dr. Rajeshwari Swaminathan"*. Validated for non-empty text. |
| **3** | **Profile Photo** | `String?` | No | Image File Picker / Avatar Selector | Supports JPEG, PNG (max 5MB). Defaults to stylized category-colored monogram avatar. |
| **4** | **Staff Category** | `StaffCategory` (Enum) | Yes | Dropdown / Segmented Selector | Options: `Teaching`, `Administrative`, `Support`. Governs dynamic visibility of Fields #8 and #12. |
| **5** | **Designation / Job Title** | `String` | Yes | Dropdown + Autocomplete Field | e.g., *"Senior PGT Mathematics"*, *"Front-Desk Officer"*, *"HOD Science"*, *"Chief Accountant"*. |
| **6** | **Department** | `String` | Yes | Dropdown Field | e.g., *Mathematics*, *Physics*, *Humanities*, *Administration*, *Accounts*, *Library*, *Transport*. |
| **7** | **Qualification** | `String` | Yes | Text Input | Highest academic/professional degree (e.g., *"M.Sc. Physics, B.Ed, Ph.D."*). |
| **8** | **Specialization** | `String?` | Conditional | Text Input / Tag Input | **Teaching Only**: Specialization domain (e.g., *"Calculus, Mechanics & Quantum Physics"*). Hidden for Admin/Support. |
| **9** | **Contact Information** | `Composite` | Yes | Grouped Inputs | **Phone**: `+91 XXXXX XXXXX`, **Email**: official/personal email, **Current Address** and **Permanent Address**. |
| **10**| **Date of Joining** | `DateTime` | Yes | Date Picker with Calendar Modal | Historical or future joining date (defaults to current institutional session date). |
| **11**| **Employment Type** | `EmploymentType` (Enum) | Yes | Dropdown Selector | Options: `Full-Time Permanent`, `Probationary`, `Contractual`, `Visiting / Part-Time`. |
| **12**| **Assigned Classes & Subjects** | `List<ClassSubjectAssignment>` | Conditional | Interactive Pairing Matrix | **Teaching Only**: Multiple pairings (e.g., `Class 10-A + Mathematics`, `Class 9-B + Science`) + toggle for *Primary Class Teacher*. |
| **13**| **Salary Details** | `StaffCompensationModel` | Yes | Password-masked Section Card | **Admin/HR Only**: Basic Monthly Salary, Pay Frequency, Bank Name, Account Number, IFSC Code, and PAN Card Number. |
| **14**| **Login Account & Role** | `StaffLoginAccountModel?` | No | Toggle Switch + Nested Sub-form | When enabled: Institutional Login Email, Temporary Password, and Assigned System Role (`teacher`, `frontDesk`, `admin`). |
| **15**| **Status** | `StaffStatus` (Enum) | Yes | Badge Status Selector | Options: `Active`, `On Leave`, `Inactive / Relieved`. Directly controls active directory queries. |

---

## 3. User Roles & Permission Matrix

```
┌───────────────────────────────────────┬──────────────┬──────────────┬─────────────────────────┐
│ Functionality                         │ Admin / HR   │ Teacher      │ Front-Desk Officer      │
├───────────────────────────────────────┼──────────────┼──────────────┼─────────────────────────┤
│ Access Staff Management Module        │ Full Access  │ Limited View │ Directory Lookup Only   │
│ Onboard New Staff (Wizard)            │ Yes          │ No           │ No                      │
│ Modify Personnel Records              │ Yes          │ Self-profile*│ No                      │
│ View Financial / Salary / Bank Details│ Full (Masked)│ Self Only*   │ No Access (Redacted)    │
│ Class & Subject Timetable Assignments │ Manage All   │ View Own     │ View Class Teachers     │
│ Print Institutional ID Badges         │ Yes          │ View Own     │ Yes (Badge Studio)      │
│ Deactivate / Relieve Staff Member     │ Yes          │ No           │ No                      │
└───────────────────────────────────────┴──────────────┴──────────────┴─────────────────────────┘
* Self-profile capabilities available when signed in via personal portal account.
```

---

## 4. UI Architecture & Navigation Flows

### 4.1 Admin Sidebar Integration (`EdupluseScaffold`)
Replaces the flat *"Teachers"* item with an expandable module matching the established *"Students"* architecture:

```
├── Dashboard
├── Students (Expandable)
│   ├── Student Pipeline
│   ├── Student List
│   ├── Student Details
│   └── Add New Student
├── Staff (Expandable)  <── NEW UNIFIED MODULE
│   ├── Staff Directory (staffList)
│   ├── Add New Staff (addNewStaff)
│   └── Departments & Roles (staffDepartments)
├── Guardian
├── Classes
├── Examinations
└── Fees Collection
```

### 4.2 Screen Specifications

#### Screen 1: Staff Directory & Roster (`StaffListScreen`)
- **Top Metric KPI Cards**:
  1. *Total Staff Count* (e.g., 48)
  2. *Teaching Faculty* (e.g., 34)
  3. *Administrative Staff* (e.g., 8)
  4. *Staff On Leave Today* (e.g., 3)
- **Search & Multi-Facet Filters**:
  - Live query input filtering across Name, Staff ID, and Phone Number.
  - Category Pills: `All Staff`, `Teaching`, `Administrative`, `Support`.
  - Department Dropdown Filter.
  - Employment Status Filter: `All`, `Active`, `On Leave`, `Inactive`.
- **Dual Display Modes**:
  - **Table View**: Enterprise data table with columns for Photo + Name, Staff ID, Category & Department, Contact, Assigned Classes, Status Badge, and Action Menu.
  - **Card Grid View**: Responsive 2-to-4 column grid featuring visual employee cards with monogram/photo avatars, category chips, quick contact launchers, and ID badge triggers.
- **Row & Card Actions**:
  - *View 360° Profile*: Navigates to full dossier screen.
  - *Edit Information*: Loads record into the wizard in edit mode.
  - *Print ID Badge*: Opens ID Badge Canvas for instant thermal badge generation.
  - *Toggle Status*: Quickly switches between Active, On Leave, and Inactive.

#### Screen 2: 4-Step Onboarding Wizard (`AddStaffFormScreen`)
- **Step 1: Personal & Demographic Coordinates**:
  - Auto-generated Staff ID preview (`STF-2026-XXXX`).
  - First Name, Last Name, Gender, Date of Birth, Blood Group, Profile Photo.
  - Mobile Number, Official Email, Residential Address, Permanent Address.
- **Step 2: Employment & Institutional Placement**:
  - Staff Category (`Teaching`, `Administrative`, `Support`).
  - Department Selection & Designation Title.
  - Qualification & Educational Degrees.
  - Date of Joining & Employment Type (`Permanent`, `Contractual`, `Probationary`).
- **Step 3: Academic Assignments & Specialization (Conditional)**:
  - *When Category == Teaching*:
    - Subject Specialization input.
    - Class-Subject Pairing Matrix (Select Grade + Section + Subject, click "Add Pairing").
    - Toggle for "Designate as Primary Class Teacher" for a specific class section.
  - *When Category != Teaching*:
    - Automatically displays an informational banner explaining academic pairings are waived for administrative personnel and proceeds to step 4.
- **Step 4: Compensation, Documents & System Login**:
  - Basic Monthly Salary & Pay Frequency.
  - Bank Account Details (Bank Name, Account Number, IFSC Code, PAN Card).
  - Provision System Login Toggle (optional institutional login email + temporary password + role permission selector).

#### Screen 3: Staff 360° Profile Dossier (`StaffDetailsScreen`)
- **Hero Banner**:
  - Employee photo, Full Name, Designation, Department tag, Staff ID badge, and live Active Status badge.
  - Action buttons: *Edit Profile*, *Print ID Card*, *Send Message / Email*.
- **Tabbed Dossier Sections**:
  1. **Overview & Biography**: Contact directory, residential address, education, and joining timeline.
  2. **Academic Workload (Teachers)**: Assigned classes, subjects taught, and class teacher responsibilities.
  3. **HR & Compensation (Admin-Gated)**: Masked salary view with reveal toggle, bank account coordinates, and PAN identification.
  4. **Digital ID Badge**: Front and back side high-resolution preview with instant thermal printer dispatch button.

#### Screen 4: Departments & Roles Roster (`StaffDepartmentsScreen`)
- Visual breakdown of faculty and staff headcount across academic and administrative departments.
- Listing of Department Heads (HODs) and designation quotas.

---

## 5. Domain Models & Architecture

```
lib/features/staff/
├── domain/
│   ├── staff_member_model.dart          # Core entity model linking demographic, HR, & academic data
│   ├── class_subject_assignment.dart    # Class-Section-Subject pairing model
│   ├── staff_compensation_model.dart    # Protected financial, bank & tax attributes
│   └── staff_login_account_model.dart   # Portal account provisioning model
├── data/
│   └── staff_repository.dart            # Mock repository with JSON seeding & SharedPreferences persistence
├── application/
│   └── staff_controller.dart            # Riverpod AsyncNotifiers (staffListProvider, activeStaffFilterProvider)
└── presentation/
    ├── admin/
    │   ├── staff_list_screen.dart       # Directory (KPIs, search, table & card grid)
    │   ├── add_staff_form_screen.dart   # 4-step wizard with dynamic teaching fields
    │   ├── staff_details_screen.dart    # 360° profile dossier with protected salary toggle
    │   └── staff_departments_screen.dart# Departmental roster & HOD matrix
    └── widgets/
        ├── staff_card.dart              # Reusable employee card component
        ├── class_pairing_box.dart       # Dynamic class-subject assignment manager
        └── staff_id_badge_view.dart     # Dual-sided staff badge renderer
```

### Data Storage & Pre-seeded Faculty
- **Mock Asset Seed**: `assets/data/staff/staff.json` containing 10+ realistic Indian faculty records across disciplines:
  - *Dr. Rajeshwari Swaminathan* (HOD Mathematics, Class 10-A Class Teacher)
  - *Vikramaditya Sen* (Senior PGT Physics, Class 12 Science)
  - *Ananya Deshmukh* (TGT English & Literature, Class 8-B)
  - *Ramesh Bhat* (TGT Social Science & History, Class 6-B)
  - *Sunita Verma* (Chief Accountant & Fee Manager)
  - *Priya Verma* (Senior Admissions & Front-Desk Officer)
  - *Kalyan Iyer* (Computer Science & AI Lab Instructor)
- **Session Persistence**: Local `SharedPreferences` cache (`edupulse_saved_staff_records`) ensuring all newly added or edited staff members persist across hot reloads and multi-role gateway sign-ins.

---

## 6. Implementation Execution Roadmap (For Tomorrow)

1. **Phase 1: Domain Entities & Data Layer**:
   - Create `ClassSubjectAssignment`, `StaffCompensationModel`, `StaffLoginAccountModel`, and `StaffMemberModel`.
   - Seed `assets/data/staff/staff.json` and declare in `pubspec.yaml`.
   - Implement `StaffRepository` and `MockStaffRepository` with `SharedPreferences` cache.
2. **Phase 2: Riverpod State Management**:
   - Create `staffListProvider`, `staffCountsProvider`, `filteredStaffProvider`, and `selectedStaffIdProvider`.
3. **Phase 3: Navigation Integration**:
   - Update `EdupluseNavPage` enum in `edupluse_scaffold.dart` replacing `teachers` with `staffList`, `addNewStaff`, and `staffDepartments`.
   - Implement expandable sidebar sub-menu matching the Students module.
4. **Phase 4: Presentation Layer**:
   - Build `StaffListScreen` with top KPI metric cards, facet search, and Table/Card views.
   - Build `AddStaffFormScreen` 4-step wizard with category-driven dynamic academic fields.
   - Build `StaffDetailsScreen` with protected salary reveal toggle and live ID badge generator.
   - Build `StaffDepartmentsScreen` departmental matrix.
5. **Phase 5: Verification & Testing**:
   - Write comprehensive widget tests validating staff creation, class-subject assignment, and cross-screen reflection.
   - Verify phone screen responsiveness (390x844) with zero overflow warnings.
