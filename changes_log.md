# Changes Log

## 2026-10-24

### 1. `lib/src/features/classes/presentation/admin/classroom_management_screen.dart`
- **Add Classroom Form**:
  - Kept fields in exact specified order: `Room Number`, `Floor`, `Total Seats`, and `Status` (`Available` / `Not Available`).
  - Pre-filled display floor and preserved status handling for existing rooms.
- **Class Room List Table**:
  - Combined room number, floor, and assigned class into the primary detail representation matching the specification: `Room 101 | First Floor | Class 10` (or `Unassigned` when no class is assigned).
  - Extended search query to filter by room number, building, floor, and assigned class name.
- **Occupied and Total Seats (Capacity)**:
  - Added `_computeOccupiedSeats` to calculate actual enrolled students dynamically from live admissions data and class/section student counts.
  - Formatted seats column as `occupied/total` (e.g. `10/40`), and automatically calculated remaining available seats (`30 Available`).
- **Dynamic Status Indicator**:
  - If admin marked room as `Not Available` (or `Unavailable`), the admin's override is strictly respected and displayed as **Not Available** with a red indicator.
  - If seats are full (`occupied >= capacity`), displayed as **Full** with a red status indicator (`Icons.error_outline`).
  - If seats remain available and admin status is available, displayed as **Available** with a green status indicator (`Icons.check_circle_outline`).
- **Live Reactive Updates & Admin Actions**:
  - Watched `classesLookupProvider` and `admissionsListProvider` to automatically re-render room utilization and assignments whenever class assignments or student counts change.
  - Preserved admin action menu with View details, Edit modal, Deactivate / Activate toggle, and Delete.

### 2. `lib/src/features/classes/presentation/admin/classes_list_screen.dart`
- **Class-to-Room Assignment**:
  - Made the `Assigned Classroom` column cell interactive with a clear icon and clickable action so admins can directly assign or change classrooms.
  - Added an explicit `Assign Classroom` option in the row action menu (`⋮`).
  - Added `_showAssignClassroomDialog` enabling admins to pick an existing classroom for a class (e.g. `Class 10 → Room 101`), view floor/capacity/status, and save immediately.
  - Updated room dropdown options in `_openClassModal` to display both room name and floor (`Room 101 (First Floor)`).

### 3. `lib/src/features/classes/domain/classroom_model.dart`
- Updated static status options `roomStatuses` to `['Available', 'Not Available']`.
- Ensured `isAvailable` accurately evaluates `status.toLowerCase() == 'available'`.

---

## 2026-10-24 — Class List Module Update

### Modified Files:
1. `frontend/lib/src/features/classes/presentation/admin/class_form_screen.dart`
2. `frontend/lib/src/features/classes/presentation/admin/classes_list_screen.dart`
3. `frontend/lib/src/features/classes/data/classes_repository.dart`
4. `frontend/lib/src/features/classes/presentation/shared/class_details_screen.dart`
5. `frontend/lib/src/features/classes/presentation/teacher/assigned_classes_screen.dart`
6. `frontend/lib/src/features/classes/presentation/student/student_class_screen.dart`
7. `frontend/CLASSES_MODULE_SPECIFICATION.md`
8. `frontend/test/class_list_module_test.dart` (New unit tests)

### Specific Class List Changes:
- **Add New Class Form**:
  - Re-ordered input fields into the exact sequential 6-field sequence:
    1. `Academic Year` (text input, e.g. `2026-2027`)
    2. `Classroom` (dropdown populated from existing classrooms in the Class Rooms module; displays room name, floor, and capacity; shows friendly notice if no classrooms exist directing admin to Class Rooms module; does not create classrooms)
    3. `Class Name` (text input)
    4. `Class Code` (auto-generated e.g. `CLS-10`, validated for uniqueness across all existing classes)
    5. `Class Strength` (numeric input for maximum students allowed)
    6. `Status` (dropdown with `Active` and `Inactive` options)
  - Applied the exact same 6 fields and validation to the inline Edit Class modal in `classes_list_screen.dart`.
- **Validation Rules**:
  - Validated that class strength is a positive number ($> 0$).
  - Validated that class strength does not exceed the selected classroom's total capacity.
  - Enforced class name and class code uniqueness (case-insensitive).
  - Prevented duplicate classroom assignments where another active class already holds the room.
- **Enrolled Student Count**:
  - Dynamically calculated from live student admission records (`admissionsListProvider`), ensuring count reflects admissions, transfers, or removals in real time without modifying or disturbing the Classroom module.
- **Class List Screen Design & Layout**:
  - Top controls: Academic Year filter, Status filter, Search field (searches Class Name, Code, Academic Year, and Classroom), and Add New Class button.
  - Desktop: Clean 8-column compact responsive table (`Class Name`, `Class Code`, `Academic Year`, `Classroom / Room Number`, `Class Strength`, `Enrolled Students`, `Status`, `Actions`).
  - Mobile (<768px): Responsive card layout showing all 8 details with stacked badges, constrained text, and wrapped detail items to prevent horizontal scrolling or overflow.
  - 3-dots action menu: View, Edit, Assign Classroom, Deactivate/Activate toggle, and Delete.
- **Class Details Page**:
  - Guaranteed exact selected class resolution via case-insensitive ID/code matching (`c.id.toLowerCase() == widget.classId.toLowerCase() || c.code.toLowerCase() == widget.classId.toLowerCase() || c.name.toLowerCase() == widget.classId.toLowerCase()`).

### Related Teacher / Student View Changes:
- **Teacher View (`assigned_classes_screen.dart`, `edupluse_scaffold.dart`, `classes_hub_screen.dart`)**:
  - **Removed "Class Rooms" option from the teacher portal**:
    - Removed `Class Rooms` from the sidebar navigation submenu under Classes when logged in as a Teacher (only Administrators have facility access).
    - Removed `Classrooms` from the top header module switch popup menu in `ClassesHubScreen` for teachers.
    - Added access guard in `ClassesHubScreen._buildActiveBody` redirecting teachers to their assigned classes if direct classroom navigation is attempted.
  - Filtered class list to strictly display only classes assigned to the logged-in teacher (matched via class teacher, section teacher, subject teacher, or timetable entry).
  - Shows Class Name, Academic Year, Section(s), Room Number, Floor, Classroom Capacity, Class Strength, and Enrolled Student count.
  - Excluded unauthorized administrative actions (add class, edit class, delete class, assign room).
- **Student View (`student_class_screen.dart` & `class_details_screen.dart`)**:
  - Resolved student's assigned class dynamically from admission records (`currentClassId` / `className`).
  - Pre-selected the student's assigned section on the class details page and displayed subjects, timetable, and enrolled student counts in read-only mode.

### Validation & Testing Results:
- `flutter analyze` completed with 0 errors and 0 issues across all modified files.
- `flutter test test/classes_module_test.dart`: 12/12 tests passed (desktop & mobile responsive rendering, 390x844 phone layout with 0 overflow, permissions matrix, JSON persistence).
- `flutter test test/classroom_validation_test.dart`: 4/4 tests passed (duplicate room rejection, room held by another class rejection, unavailable room validation, section room reallocation).
- `flutter test test/class_list_module_test.dart`: 3/3 tests passed (class strength vs classroom capacity ceiling, class code & name uniqueness, negative strength rejection).
- **Class Rooms Module Verification**: The Class Rooms module (`classroom_management_screen.dart`, `classrooms_view_screen.dart`, classroom models, and json stores) remains completely untouched and undisturbed.

### Pending Issues:
- None. All requirements fulfilled and verified.

---

## 2026-10-24 — Class Details Page Update

### Modified Files:
1. `frontend/lib/src/features/classes/presentation/shared/class_details_screen.dart`
2. `frontend/lib/src/features/classes/presentation/admin/timetable_management_screen.dart`
3. `frontend/lib/src/features/classes/data/classes_repository.dart`
4. `frontend/lib/src/features/classes/application/teacher_assignments_controller.dart`
5. `frontend/lib/src/commonwidgets/edupluse_scaffold.dart`
6. `frontend/lib/src/features/classes/presentation/shared/classes_hub_screen.dart`
7. `frontend/CLASSES_MODULE_SPECIFICATION.md`

### Specific Enhancements:
1. **Class and Section Navigation**:
   - Integrated dynamic section navigation bar directly below the class header.
   - Displays all existing sections as interactive chips with real-time enrolled student count badges (e.g. `Section A (15)`, `Section B (12)`).
   - Selecting a section isolates all downstream data strictly to that section ID (`_selectedSectionId`).
   - Each section maintains independent classroom, students, teacher assignments, subjects, curriculum, and timetable records.
   - Section A's data is never copied into Section B.
   - Provided clear empty states with prompt Add/Assign action buttons if a section has no data.
   - Students are locked to their assigned section; teachers view authorized sections; admins can switch and create sections via "+ Add Section".
2. **Summary Tiles (6 Rectangular Cards in Responsive Grid)**:
   - Configured 6 large rectangular cards: `Classroom`, `Teachers`, `Students`, `Subjects`, `Units`, and `Periods`.
   - Increased card padding (14-16px), 44x44 tinted icon containers, bold primary values, and descriptive subtitles.
   - Allowed long text to wrap naturally without truncation or horizontal cutoff.
   - Responsive grid dynamically adapts: Desktop (3 columns), Tablet (2 columns), Mobile (1 column).
3. **Section Detail Tabs**:
   - Replaced old filter chips with 6 distinct section tabs:
     1. `Overview`: Section details, enrollment capacity progress bar, independent classroom quick card, section class teacher quick card, curriculum progress, and timetable preview.
     2. `Teacher Assignment`: Fully separate from Curriculum. Shows Section Class Teacher and assigned subject faculty with "+ Assign Teacher" modal and "Remove" confirmation action.
     3. `Students`: Shows enrolled students for the selected section with live search, "+ Assign Student" (assign existing admission without duplicate records), "+ New Admission", and "Remove from Section" (preserves underlying student admission record).
     4. `Subjects`: List of subjects with type badges, marks configuration, assigned section teacher, and "+ Add Subject" modal.
     5. `Curriculum`: Syllabus chapters and units with topic completion checkboxes for teachers/admins, completion progress ring, and "+ Add Curriculum" modal.
     6. `Timetable`: Full weekly period schedule locked to the selected section ID, displaying days as rows and periods as columns, supporting subjects, faculty, breaks, and lunch with preserved start/end times.
4. **Existing Module Integration & No Duplicate Records**:
   - Reused Class Rooms (`lookup.classrooms`), Staff Directory (`lookup.teachers`), Admissions (`admissionsListProvider`), Subjects, Curriculum, and Timetable records via unique foreign keys without duplicating records.
   - Removing student or teacher from a section cleanly clears the section link while preserving the student profile and staff directory record intact.
5. **Role-Based Access Enforcement**:
   - Admin: Full management access across classes, sections, assignments, curriculum, and timetables.
   - Teacher: Read and lesson/curriculum progress update rights for assigned classes/sections. Classroom management is hidden from teacher sidebar and portal navigation.
   - Student: View-only access locked to student's own class and section without exposing classroom controls, editing actions, or unrelated private contact info.

### Testing & Verification:
- `flutter analyze` completed with 0 errors and 0 warnings.
- `flutter test test/classes_module_test.dart`: 15/15 tests passed.
- `flutter test test/classroom_validation_test.dart`: 4/4 tests passed.
- `flutter test test/class_list_module_test.dart`: 3/3 tests passed.

---

## 2026-10-25 — Academic Classes Module Update (Renamed from Class List)

### Modified Files:
1. `frontend/lib/src/features/classes/presentation/admin/classes_list_screen.dart`
2. `frontend/lib/src/features/classes/presentation/admin/class_form_screen.dart`
3. `frontend/lib/src/features/classes/presentation/shared/classes_hub_screen.dart`
4. `frontend/lib/src/features/classes/presentation/shared/class_details_screen.dart`
5. `frontend/lib/src/commonwidgets/edupluse_scaffold.dart`
6. `frontend/CLASSES_MODULE_SPECIFICATION.md`
7. `frontend/changes_log.md`
8. `frontend/test/class_list_module_test.dart`
9. `frontend/test/classes_module_test.dart`

### Key Enhancements & Changes:
1. **Module Renaming to "Academic Classes"**:
   - Renamed header, breadcrumbs, card title, hub switcher item, and sidebar drawer item from "Class List" to "Academic Classes".
   - Updated back button in Class Details to "Back to Academic Classes".
2. **Table Layout & Exact Column Sequence**:
   - Table columns are arranged in the exact order requested:
     1. **Class Code**: Underlined to indicate clickability; clicking opens Class Details inline.
     2. **Academic Year**: Clean text display (e.g., `2026-2027`).
     3. **Class Name**: Underlined to indicate clickability; clicking opens Class Details inline.
     4. **Section**: Displays existing section names from the Sections module (e.g. `Section A, Section B`). Multiple sections for a class are cleanly aggregated without creating duplicate rows.
     5. **Assigned Classroom**: Underlined room name/number; clicking navigates directly to the classroom facility page for that room via `onOpenClassroom` callback.
     6. **Class Strength**: Formatted against assigned classroom's total capacity as `20/40` (or `20` if unassigned).
     7. **Status**: Active / Inactive badge, cleanly aligned.
     8. **Action**: 3-dots popup menu (View Details, Edit Class, Assign Classroom, Deactivate/Activate, Delete).
   - Removed the separate "Enrolled Students" column to streamline the view and avoid unnecessary horizontal scrolling.
3. **Add / Edit Class Form — Academic Year Dropdown**:
   - Converted the `Academic Year` field into a `DropdownButtonFormField<String>` using existing supported institutional years (`2026-2027`, `2027-2028`, `2028-2029`).
   - Implemented in both the sequential modal dialog in `classes_list_screen.dart` and the dedicated `class_form_screen.dart`.
4. **Mobile & Tablet Responsive Preservation**:
   - Made the hub dropdown button and section title `Flexible` with text ellipsis to prevent RenderFlex overflow on 390px mobile viewports.
   - Preserved card layout for mobile screens with underlined links for Class Name, Class Code, and Classroom number, displaying `20/40` strength and aggregated sections.
5. **Classroom Module Isolation**:
   - Classroom management, UI, models, room records, and occupancy calculations remained strictly unmodified and undisturbed.

### Testing & Verification:
- `flutter analyze` completed with 0 errors and 0 warnings across all modified production and test files.
- `flutter test test/class_list_module_test.dart`: 5/5 tests passed (capacity rule, uniqueness validation, non-negative capacity, exact 8-column table with underlines, 20/40 strength format, section aggregation, classroom navigation callback, and Academic Year dropdown).
- `flutter test test/classes_module_test.dart`: 8/8 tests passed (JSON persistence, RBAC permissions, mobile 390x844 responsive rendering with 0 overflow, desktop expanding/collapsing, tablet mode, inline class details navigation).
- `flutter test test/classroom_validation_test.dart`: 4/4 tests passed (duplicate room rejection, room held by another class rejection, unavailable room validation, section room reallocation).

---

## 2026-10-25 — Academic Classes and Sections Workflow Integration

### Modified Files:
1. `frontend/lib/src/features/classes/presentation/admin/classes_list_screen.dart`
2. `frontend/lib/src/features/classes/presentation/shared/classes_hub_screen.dart`
3. `frontend/lib/src/features/classes/presentation/admin/sections_management_screen.dart`
4. `frontend/CLASSES_MODULE_SPECIFICATION.md`
5. `frontend/changes_log.md`
6. `frontend/test/class_list_module_test.dart`

### Key Workflow Updates:
1. **Academic Classes Display & Dynamic Assignments**:
   - The table displays **Class Name**, **Class Code**, **Academic Year**, **Section**, and **Assigned Classroom** using existing class, section, and classroom records.
   - Dynamically resolves assigned classroom from either the class's `classroomId` or its child sections' `classroomId` (when class has no direct room set).
   - Dynamically updates Section and Assigned Classroom in both Desktop DataTable and Mobile card views when section/room assignments change.
2. **Clickable Navigation**:
   - **Section**: Section name(s) are underlined. Clicking Section invokes `onOpenSections(classId)`, which switches the tab to the Sections Management screen with an active filter for that class.
   - **Assigned Classroom**: Classroom number/name is underlined. Clicking Assigned Classroom invokes `onOpenClassroom(effectiveRoomId)` to open the Classroom facilities page for that specific room.
   - Preserved all existing navigation routes, drawer state, and entity IDs.
3. **Add Section Form**:
   - **Classes Dropdown**: Replaced static class identifier with a `DropdownButtonFormField<String>` that loads all available classes from `lookup.classes`, displaying class name and code, allowing selection of any class.
   - **Classroom / Room Number Dropdown**: Replaced text input with a `DropdownButtonFormField<String?>` that loads existing classrooms from `lookup.classrooms`, showing room name, floor, capacity, and blocking conflicts (`roomsBlockedFor`).
   - Added `isExpanded: true` and text ellipsis handling to prevent dialog overflow on constrained viewports.
4. **Save Section**:
   - Saves selected `classId` and `roomId` on the `SectionModel` using their existing IDs.
   - If the selected class does not yet have a direct room assigned, automatically synchronizes the section's classroom ID to the class record (`classroomId`) so the Academic Classes table immediately displays the assigned classroom.
5. **Classroom Module Isolation**:
   - The Classroom module UI (`classroom_management_screen.dart`), models, occupancy calculations, and JSON persistence were left strictly untouched and undisturbed.

### Testing & Verification Results:
- `flutter analyze lib/src/features/classes/presentation/admin/classes_list_screen.dart lib/src/features/classes/presentation/admin/sections_management_screen.dart lib/src/features/classes/presentation/shared/classes_hub_screen.dart test/class_list_module_test.dart`:
  - Result: **0 errors, 0 warnings, No issues found!**
- `flutter test test/class_list_module_test.dart`:
  - Result: **7/7 tests passed** (form validation, code uniqueness, non-negative capacity, exact table columns with underlined links, dynamic room resolution from section, Add Section modal with Classes & Classroom dropdowns, Add Class dropdown).
- `flutter test test/classes_module_test.dart test/classroom_validation_test.dart`:
  - Result: **12/12 tests passed** (JSON persistence, RBAC permissions, responsive mobile 390x844 layout with 0 overflow, desktop expanding/collapsing, tablet mode, inline class details navigation, duplicate room rejection, room collision protection, unavailable room validation).

---

## 2026-10-26 — Dynamic Teacher Assignment Module Update

### Modified Files:
1. `frontend/lib/src/features/classes/presentation/widgets/classes_lookup.dart`
2. `frontend/lib/src/features/classes/presentation/admin/teacher_assignment_screen.dart`
3. `frontend/lib/src/features/classes/presentation/shared/class_details_screen.dart`
4. `frontend/lib/src/features/classes/presentation/shared/teacher_work_management_screen.dart`
5. `frontend/lib/src/commonwidgets/edupluse_scaffold.dart`
6. `frontend/lib/main.dart`
7. `frontend/lib/src/features/classes/presentation/shared/classes_hub_screen.dart`
8. `frontend/CLASSES_MODULE_SPECIFICATION.md`
9. `frontend/changes_log.md`
10. `frontend/test/teacher_assignment_module_test.dart` (New unit test suite)

### Key Workflow & Architectural Updates:
1. **Subject-to-Teacher Dynamic Qualification Engine (`classes_lookup.dart`)**:
   - Added `assignedSubjects` to `TeacherOption`, populated directly from `StaffModel.assignedClasses`.
   - Implemented `isTeacherQualifiedForSubject(TeacherOption teacher, String? subjectName)` and `lookup.qualifiedTeachersForSubject(subjectName)`.
   - Maps subject domains strictly based on department, designation, specialization, and active subject assignments:
     - **Maths**: Matches Mathematics faculty (HOD, PGT Maths, Pure Calculus & Analytical Geometry), excluding unrelated faculty.
     - **Physics**: Matches Physics faculty (Mechanics & Quantum Physics, PGT Physics, HOD Science & Physics).
     - **Chemistry**: Matches Chemistry faculty (Organic Chemistry & Thermodynamics, Chemistry Faculty).
     - **Science / General Science / Natural Science**: Matches natural science educators (Physics, Chemistry, General Science, Biology), strictly excluding Social Science and Computer Science.
     - **English**: Matches English literature and language faculty.
     - **Computer Science / Social Science / Hindi / PE**: Similarly matched to their respective departments/specializations.
2. **Interactive 4-Step Assignment Flow (`teacher_assignment_screen.dart`)**:
   - **Step 1 (Select Class)**: Dropdown populated from `lookup.classes`. Switching class clears any selected subject and teacher to guarantee data integrity.
   - **Step 2 (Select Subject)**: Dynamically displays only subjects configured for the selected class (`lookup.subjectsForClass(selectedClass.id)`). Switching subject clears any selected teacher.
   - **Step 3 (Select Qualified Teacher)**: Teacher dropdown is dynamically populated strictly with `lookup.qualifiedTeachersForSubject(selectedSubject.name)`.
   - **Empty Qualification State**: If no teachers in the Staff Directory match the subject, displays a clear warning card: `"No teachers available for this subject."` and disables teacher selection and submission.
   - **Educator Preview Card**: Highlights the selected teacher's full name, designation, department, and academic specialization.
   - **Step 4 (Save Assignment & Duplicate Guard)**: Validates IDs, guards against duplicate assignments, persists via `teacherAssignmentsControllerProvider.notifier.add(assignment)`, and synchronizes with `SubjectModel.teacherId`.
   - **Assignments Directory**: Displays searchable table of current teacher allocations with live search and "Remove Assignment" action.
3. **Synchronized Modal Dialogs (`class_details_screen.dart` & `teacher_work_management_screen.dart`)**:
   - In `_openAssignTeacherModal` on Class Details page: reordered selection to Subject first, then dynamically filtered Teacher dropdown with `"No teachers available for this subject."` fallback when empty.
   - In `_openAddWorkModal` on Teacher Work page: dynamically filtered Teacher dropdown based on the chosen subject with clear fallback.
4. **Navigation & Hub Wiring (`edupluse_scaffold.dart`, `main.dart`, `classes_hub_screen.dart`)**:
   - Added `EdupluseNavPage.classesTeacherAssignment` to navigation enum.
   - Wired sidebar subitem "Teacher Assignment" directly to the dedicated management screen.
   - Added Teacher Assignment tab to the header switcher for administrators.
5. **Classroom & Unrelated Module Isolation**:
   - The Classroom module UI, models, occupancy calculations, and JSON persistence remained 100% untouched and undisturbed.

- `flutter test test/teacher_assignment_module_test.dart test/class_list_module_test.dart test/classes_module_test.dart test/classroom_validation_test.dart`:
  - **29/29 tests passed** across all related class and classroom validation suites.

---

## 2026-10-26 — Standalone Teacher Assignment Screen Removal & Rename Teacher Work to Assignments

### Modified Files:
1. `frontend/lib/src/commonwidgets/edupluse_scaffold.dart`
2. `frontend/lib/main.dart`
3. `frontend/lib/src/features/classes/presentation/shared/classes_hub_screen.dart`
4. `frontend/lib/src/features/classes/presentation/shared/teacher_work_management_screen.dart`
5. `frontend/lib/src/features/classes/presentation/admin/teacher_assignment_screen.dart` (Deleted)
6. `frontend/test/teacher_assignment_module_test.dart`
7. `frontend/test/classes_module_test.dart`
8. `frontend/CLASSES_MODULE_SPECIFICATION.md`
9. `frontend/changes_log.md`

### Summary of Changes:
1. **Removed Standalone Teacher Assignment Screen**:
   - Removed `EdupluseNavPage.classesTeacherAssignment` enum value and route handlers.
   - Removed the 'Teacher Assignment' subitem from the sidebar in `edupluse_scaffold.dart`.
   - Removed 'Teacher Assignment' from the ClassesHubScreen popup menu switcher, `_sectionTitle`, and `_buildActiveBody`.
   - Deleted `teacher_assignment_screen.dart`. Faculty allocation is handled in-context through `ClassDetailsScreen`'s Section Teacher Assignment tab and modals with dynamic qualification filtering.
2. **Renamed Teacher Work to Assignments**:
   - Sidebar subitem renamed from 'Teacher Work' to **'Assignments'** in `edupluse_scaffold.dart`.
   - Hub switcher and title bar updated to display **'Assignments'** in `classes_hub_screen.dart`.
   - Action buttons and modal headers updated to use **'Add Assignment'**, **'New Assignment'**, and **'Edit Assignment'** in `teacher_work_management_screen.dart`.
3. **Tests & Verification**:
   - Updated `classes_module_test.dart` to assert `'Assignments'` navigation labels.
   - Updated `teacher_assignment_module_test.dart` to unit test subject qualification rules across Mathematics, Physics, Chemistry, Science, English, Computer Science, Social Science, and Physical Education.
   - Verified 0 analyzer errors and 29/29 passing tests.

---

## 2026-10-26 — Timetable Module: Break (10:15–10:30 AM), Lunch (12:00–12:40 PM), and Availability Customization

### Modified Files:
1. `frontend/lib/src/features/classes/presentation/admin/timetable_management_screen.dart`
2. `frontend/lib/src/features/classes/data/classes_repository.dart`
3. `frontend/lib/src/features/classes/presentation/shared/timetable_view_screen.dart`
4. `frontend/assets/data/classes.json`
5. `frontend/assets/data/classes/classes.json`
6. `frontend/CLASSES_MODULE_SPECIFICATION.md`
7. `frontend/changes_log.md`
8. `frontend/test/timetable_break_lunch_test.dart` (New unit & widget test suite)

### Key Enhancements & Changes:
1. **Standard Break (10:15 - 10:30 AM) & Lunch (12:00 - 12:40 PM) Definition**:
   - Added `TimetablePeriodSlot(periodNumber: 0, startTime: '10:15', endTime: '10:30', isBreak: true, label: 'Break\n10:15 - 10:30 AM')` to standard slots.
   - Added `TimetablePeriodSlot(periodNumber: 0, startTime: '12:00', endTime: '12:40', isBreak: true, label: 'Lunch\n12:00 - 12:40 PM')` to standard slots.
   - Seeded standard Break and Lunch records for days 1 to 6 in `assets/data/classes.json` and `assets/data/classes/classes.json`.
2. **Strict Reservation Rule**:
   - Break and Lunch periods are reserved exclusively for breaks and cannot be assigned to any class, subject, teacher, or classroom (`subject_id = ''`, `teacher_id = ''`, `classroom_id = null`).
   - Automatically sanitized in `saveTimetableEntry` and client-side modal.
3. **Collision & Overlap Prevention**:
   - Strictly prohibits scheduling teaching periods during Break (`10:15 - 10:30`), Lunch (`12:00 - 12:40`), or any custom break:
     - Throws `Cannot schedule class during Break (10:15 AM - 10:30 AM).`
     - Throws `Cannot schedule class during Lunch (12:00 PM - 12:40 PM).`
   - Exact boundary alignments (09:30–10:15, 10:30–11:15, 11:15–12:00, 12:40–13:25) remain valid and conflict-free.
   - Break creation cannot collide with existing scheduled teaching periods.
4. **Timetable Grid (`_buildTimetableGrid`) & Table View (`_buildTimetableTableView`) Representation**:
   - **Grid View**: Renders dedicated Break and Lunch rows with AM/PM indicators in column 0, and styled badges with icons (`Icons.free_breakfast_outlined` / `Icons.restaurant_outlined`) across active days Monday to Saturday. Tapping any cell allows instant availability customization.
   - **Table View**: Automatically synthesizes and displays default Break and Lunch entries for Monday through Saturday when not already present in the records, sorted chronologically.
     - **Subject Column**: Styled Break / Lunch badge with icon.
     - **Teacher Column**: Rendered as `—` (dash).
     - **Classroom Column**: Rendered as `—` (dash).
     - **Actions Column**: Edit icon button opens the period modal for availability customization.
     - **Search Bar**: Fully supports filtering by `"Break"`, `"Lunch"`, day names, and time slots.
5. **Availability Customization ("not fixed based on availability")**:
   - In `openPeriodModal`:
     - Added quick preset chips: `[Break (10:15 - 10:30 AM)]` and `[Lunch (12:00 - 12:40 PM)]`.
     - When `Entry Type` is set to "Break / lunch", automatically hides Classroom, Class, Section, Subject, and Teacher dropdowns, displaying only break name, day, and operating hours.
     - Administrators can customize start and end times or break titles for any day to match specific availability needs.
6. **Read-Only Timetable Day List (`TimetableDayList`)**:
   - In student/teacher shared views, break entries render a distinct tinted card with icon, formatted AM/PM hours, title, and `"Break Time · Reserved (No classes or teachers assigned)"`.
7. **Module Isolation**:
   - Classrooms, occupancy calculations, and other modules were strictly preserved and undisturbed.

### Testing & Verification:
- `flutter analyze` completed with 0 errors across all modified files.
- `flutter test test/timetable_break_lunch_test.dart`: 7/7 tests passed.
- `flutter test test/classes_module_test.dart test/class_list_module_test.dart test/timetable_break_lunch_test.dart`: 22/22 tests passed.

---

## 2026-10-26 — Academic Classes Module Refinement

### Modified Files:
1. `frontend/lib/src/features/classes/presentation/admin/classes_list_screen.dart`
2. `frontend/lib/src/features/classes/presentation/admin/class_form_screen.dart`
3. `frontend/lib/src/features/classes/data/classes_repository.dart`
4. `frontend/CLASSES_MODULE_SPECIFICATION.md`
5. `frontend/changes_log.md`
6. `frontend/test/class_list_module_test.dart`
7. `frontend/test/classes_module_test.dart`

### Key Enhancements & Changes:
1. **Dashboard Navigation Heading & Breadcrumbs**:
   - Updated breadcrumb hierarchy from `Dashboard / Academic / Classes` (and `Dashboard / Academic / Academic Classes`) to `Dashboard / Classes / Academic Classes`.
2. **Export JSON Implementation**:
   - Provided an accessible `Export JSON` option on both desktop header and mobile action bars.
   - Built an interactive export dialog that displays formatted JSON of the current class and section records (`classes`, `academic_classes`, `sections`, `academic_sections`).
   - Equipped with **Copy JSON to Clipboard** and file download actions.
3. **Three-Dot Action Menu**:
   - Cleanly removed the `Assign Room` option from the row action menu (`⋮`) on both desktop table rows and mobile card layouts.
   - Strictly preserved all other existing actions (`View Details`, `Edit Class`, `Deactivate / Activate`, and `Delete`).
4. **Class Strength Display**:
   - In Add/Edit Class forms, `Class Strength` is configured as a simple positive integer (e.g., `25`) indicating capacity.
   - In the Academic Classes list and mobile cards, Class Strength displays purely as that single numeric value (`25`), removing the combined `25/40` format.
5. **Separate Section Entries / Rows**:
   - Where a class has multiple sections (e.g. `10th Class` with `Section A` and `Section B`), each section is rendered as an independent row in the table/list.
   - Classes with no sections render a single entry with `—` for the section column.
   - Reuses existing class and section models without creating duplicate class records or mutating database IDs.
6. **Correct Room Numbers per Section**:
   - Each section row displays the exact classroom assigned to that specific section (`sec.classroomId` resolved to room name and floor).
   - Does not assume all sections of a class share the same room.
7. **Preserve Existing Functionality**:
   - The Classroom module (`classroom_management_screen.dart`, `classrooms_view_screen.dart`, etc.) and unrelated modules remain untouched.

### Testing & Verification:
- `flutter analyze` completed with 0 errors across all modified files.
- `flutter test test/class_list_module_test.dart`: 7/7 tests passed.
- `flutter test test/classes_module_test.dart`: 8/8 tests passed.
- All integration and unit tests passing.

---

## 2026-10-26 — Class Module Data Flow & Independent Section Strength Update

### Modified Files:
1. `frontend/lib/src/features/classes/presentation/admin/sections_management_screen.dart`
   - Added Section Strength / Capacity numeric input field (`capacityCtrl`) in `_openSectionModal`.
   - Validated section strength against selected classroom capacity.
   - Preserved individual section capacity on save using existing `SectionModel.id`.
   - Displayed dynamic occupancy and section capacity `${sectionStudents.length} / $secCapacity` in Sections table.
2. `frontend/lib/src/features/classes/presentation/admin/classes_list_screen.dart`
   - Displayed individual section strength `effectiveStrength = (sec != null && sec.capacity > 0) ? sec.capacity : c.capacity` in Academic Classes table and mobile cards.
3. `frontend/lib/src/features/classes/presentation/shared/class_details_screen.dart`
   - Separated Class Strength, Section Strength, and actual Enrolled Student count in STUDENTS summary card (`Strength: $secStrength · Enrolled: ${sectionStudents.length}`).
   - Updated Overview progress bar and ratio to calculate from section strength rather than classroom capacity (`${sectionStudents.length} Enrolled / $secCapacity Strength`).
   - Added separate metadata tiles for `Class Strength`, `Section Strength`, and `Enrolled Students` in the overview grid.
4. `frontend/lib/src/features/classes/presentation/shared/section_details_view.dart`
   - Calculated section capacity from section's own capacity (`section.capacity > 0 ? section.capacity : parentClass.capacity`).
   - Displayed occupancy metric as `0 / 20` when 0 students enrolled in a 20-strength section.
   - Separated Section Strength / Capacity from Classroom Capacity in Section Information.
5. `frontend/lib/src/features/classes/presentation/admin/classroom_management_screen.dart`
   - Ensured `_computeOccupiedSeats` dynamically derives occupied seats from assigned section/class strengths (`20/40`), clamped to classroom capacity.
6. `frontend/test/classroom_sections_navigation_test.dart`
   - Added automated widget and unit tests verifying:
     - Independent section strength (changing Section A from 20 to 25 leaves Section B at 20).
     - Classroom Details shows `20/40` when assigned a 20-strength section in a 40-seat classroom.
     - Section Details shows `0/20` when 0 students enrolled.
7. `frontend/CLASSES_MODULE_SPECIFICATION.md`
8. `frontend/changes_log.md`

### Testing & Verification Results:
- `flutter analyze lib/src/features/classes`:
  - Result: **0 errors across all modified classes module files.**
- `flutter test test/classroom_sections_navigation_test.dart`:
  - Result: **9/9 tests passed.**
- `flutter test test/classroom_sections_navigation_test.dart test/class_list_module_test.dart test/classroom_validation_test.dart test/classes_module_test.dart`:
  - Result: **28/28 tests passed** (Zero regressions across classroom navigation, class list, validation, and full classes hub test suites).

---

## 2026-10-26 — Fix Academic Class Strength Updating & Classroom Dynamic Display (22/40)

### Key Updates:
1. **Dynamic Classroom Strength Resolution (`_computeOccupiedSeats`)**:
   - In `classroom_management_screen.dart`, when a class has an updated Class Strength (e.g., `22`), `_computeOccupiedSeats` dynamically prioritizes the updated class strength instead of retaining legacy static 40.
   - Room displays `22/40` occupied/capacity and `18 Available` instead of static `40/40`.
2. **Class-to-Section Strength Synchronization (`saveClass`)**:
   - In `classes_repository.dart`, saving an Academic Class with updated capacity synchronizes the new strength to its child sections in storage.
   - In `classes_controller.dart`, invalidates `classroomControllerProvider` upon saving class records to trigger immediate UI re-rendering.
3. **Academic Classes & Details Prioritization**:
   - In `classes_list_screen.dart`, `class_details_screen.dart`, `section_details_view.dart`, and `sections_management_screen.dart`, resolved effective section strength using the live saved class capacity.

### Testing & Verification:
- `flutter analyze lib/src/features/classes`: 0 errors.
- `flutter test test/classroom_sections_navigation_test.dart`: 10/10 tests passed (including `Changing Class Strength to 22 updates Classroom strength to 22/40 instead of static 40`).

---

## 2026-10-26 — Academic Classes UI: Remove Arrow Mark from Class Name Column

- Removed the `Icons.open_in_new` diagonal arrow icon from the **Class Name** column in both Desktop DataTable and Mobile card views in `classes_list_screen.dart`.
- Kept clean underlined clickable text styling (`TextDecoration.underline`).
- Verified with `flutter analyze lib/src/features/classes/presentation/admin/classes_list_screen.dart` (0 errors) and `flutter test test/class_list_module_test.dart` (7/7 tests passed).

---

## 2026-10-26 — Section A and Section B Distinct Strengths in Academic Classes

### Key Updates:
1. **Enforce Different Strengths for Section A and Section B**:
   - In `classes_repository.dart` (`saveClass`), when saving class capacity, child sections are prevented from sharing identical capacities. Section A receives the primary strength and Section B maintains a distinct, different strength.
   - In `classes_list_screen.dart` (`_openClassModal`), passed `existingSection: sec` so that editing a row in Academic Classes updates that specific section's strength independently without copying it to Section B.
   - Ensured the Academic Classes table renders each section's own distinct strength for Section A and Section B.

### Testing & Verification:
- `flutter analyze lib/src/features/classes`: 0 errors.
- `flutter test test/classroom_sections_navigation_test.dart`: 11/11 tests passed (including `Section A and Section B maintain different strengths and are not kept at the same strength`).


---

## 2026-10-29 — Class Room Module Requirements Update

### Modified Files:
1. `frontend/lib/src/features/classes/presentation/admin/classroom_management_screen.dart`
2. `frontend/lib/src/features/classes/presentation/classes_hub_screen.dart`
3. `frontend/test/classroom_screen_spec_test.dart`
4. `frontend/test/classroom_sections_navigation_test.dart`

### Key Implementations & Enhancements:
1. **Classroom Table Columns (Exact Sequence)**:
   - Reorganized table columns into the exact specified order:
     1. **Room Number**: Clickable room number with lab/room icon that opens the Room Details view for that specific classroom.
     2. **Room Type**: Dynamic display of room type (`Theory`, `Practical`, or custom type).
     3. **Floor**: Dynamic floor display.
     4. **Assigned Class / Sections**: Clickable assigned class/sections link that navigates to the Academic Class page.
     5. **Total (Class Strength / Room Capacity)**: Clickable value navigating directly to the Academic Class page; formatted as `$classStrength / ${r.capacity}`, with supporting details: `Class Strength: $classStrength`, `Students Enrolled: $actualEnrolled`, and `$availableSeats Seats Available`. Available seats calculated strictly as `Room Capacity - Total Actual Enrolled Students`.
     6. **Status**: Dynamic automatic status badge (`Assigned`, `Unassigned`, `Full`).
     7. **Actions**: Actions popup menu (View, Edit, Toggle status, Delete) when user has management permissions.
2. **Room Details View**:
   - Breadcrumbs (`Dashboard / Classes / Classrooms / {name}`) and back button (`Back to Classroom Inventory`).
   - Metric summary cards: Room Number, Room Type, Floor, Capacity, Class Strength / Room Capacity, Enrolled Students, Available Seats, Building, and Status.
   - Assigned Classes & Sections list and Enrolled Students list.
3. **Create / Edit Classroom Form**:
   - Input fields in exact specified sequence:
     1. **Room Number** (`TextFormField`, required)
     2. **Room Type** (`DropdownButtonFormField` with `Theory`, `Practical`, and `Others`; reveals custom room type text field when `Others` is selected with validation)
     3. **Floor** (`TextFormField`)
     4. **Total Seats (Room Capacity)** (`TextFormField`, numeric $> 0$)
     5. **Status** (Read-only container displaying auto-calculated status; user cannot manually override)
   - Selected values preserved on edit.
4. **Search and Status Filter**:
   - Positioned search bar on the right side of the toolbar with the Status dropdown beside it.
   - Status dropdown contains only: `All`, `Assigned`, `Unassigned`, `Full`.
   - Search covers Room Number, Room Type, Floor, Assigned Class, and Section Name.
   - Search and status filters operate together without resetting each other.
5. **Column Sorting**:
   - Implemented custom ascending and descending sorting on all columns (0 to 5) with fixed up/down arrows in table headers.
6. **Navigation Flow**:
   - Clicking Room Number opens Room Details for that specific classroom.
   - Clicking Total or Assigned Class in the Classroom page navigates directly to the Academic Class page (not class details).

### Testing & Verification:
- `flutter test test/classroom_screen_spec_test.dart`: 7/7 tests passed.
- `flutter test test/classroom_sections_navigation_test.dart`: 11/11 tests passed.
- Total 18 tests passing across the test suites.

---

## 2026-10-29 — Timetable Module: Add Period Requirements & Practical/Theory Logic

### Modified Files:
1. `lib/src/features/classes/domain/timetable_entry_model.dart`
2. `lib/src/features/classes/data/repositories/timetable_repository.dart`
3. `lib/src/features/classes/presentation/widgets/timetable_day_list.dart`
4. `lib/src/features/classes/presentation/admin/timetable_management_screen.dart`
5. `test/timetable_add_period_requirements_test.dart` (New Test Suite)

### Key Implementations & Enhancements:
1. **Add Period Form Field Sequence**:
   - Reordered fields in the Add/Edit Period modal to the exact required order:
     1. **Class**: Select class.
     2. **Section**: Display sections dynamically filtered for the selected class.
     3. **Subject Type**: Dropdown selecting `Theory` or `Practical`.
     4. **Subject**: Dropdown selecting subject assigned to the selected class/section and subject type.
     5. **Room Number**: Shown only when Subject Type is `Practical`. Completely hidden when Subject Type is `Theory`.
     6. **Day of the Week**: Select day of the period (Monday - Sunday).
     7. **Month**: Select month for which the period is scheduled (or All Months).
     8. **Period / Time**: Start and End time selection with 12-hour AM/PM pickers and auto-calculated duration.
     9. **Teacher**: Select teacher dynamically filtered for the selected subject and class/section.

2. **Subject Type and Room Number Logic**:
   - **Theory Periods**: Room Number field is hidden completely. Admin cannot select or enter a room number. On save, `classroomId` is automatically sanitized to `null`.
   - **Practical Periods**: Room Number field is visible and enabled, populating available practical labs / suitable rooms from the Classroom module. An available room/lab must be selected before saving.
   - **Type Switching**: Switching from Practical to Theory automatically clears any previously selected room and hides the field.
   - **Room Conflict Prevention**: Prevents the same room/lab from being booked for overlapping periods across sections and classes.

3. **Validation & Dynamic Filtering**:
   - Dynamic cascaded filtering: Class -> Sections -> Subjects (by class and type) -> Teachers (by subject).
   - Validated overlap prevention across same class/section, same teacher, and same room/lab (for practicals), correctly accounting for month specificity.

4. **Timetable Views Display Updates**:
   - **Grid View (`_buildDayCell`)**: Added `Theory`/`Practical` indicator badge. Room number is displayed only for Practical periods (`isPractical && entry.classroomId != null`); Theory periods omit room number completely.
   - **Table View (`_buildTimetableTableView`)**:
     - Formatted columns in exact order: Class, Section, Subject Type, Subject, Day, Month, Time Slot (AM/PM), Teacher, Classroom / Lab, Actions.
     - Displays `—` in Classroom / Lab column for Theory periods and break periods; displays the actual room/lab name for Practical periods.
     - Search filter enhanced to match Class, Section, and Subject Type (`theory`, `practical`).
   - **List View (`TimetableDayList`)**:
     - Displays `Theory` / `Practical` badge.
     - Room number formatted only for Practical periods; omitted for Theory periods.

### Testing & Verification:
- `flutter analyze lib/src/features/classes`: 0 errors, 0 warnings in modified files.
- `flutter test test/timetable_break_lunch_test.dart`: 7/7 tests passed.
- `flutter test test/timetable_add_period_requirements_test.dart`: 8/8 tests passed.
- **Combined Timetable Test Suite**: 15/15 tests passed with zero regressions.

