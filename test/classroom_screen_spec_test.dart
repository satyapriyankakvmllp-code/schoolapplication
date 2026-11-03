import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/src/features/admissions/application/admissions_controller.dart';
import 'package:frontend/src/features/admissions/domain/student_admission_model.dart';
import 'package:frontend/src/features/authentication/application/auth_controller.dart';
import 'package:frontend/src/features/authentication/domain/user_model.dart';
import 'package:frontend/src/features/classes/application/classroom_controller.dart';
import 'package:frontend/src/features/classes/application/sections_controller.dart';
import 'package:frontend/src/features/classes/domain/class_model.dart';
import 'package:frontend/src/features/classes/domain/classroom_model.dart';
import 'package:frontend/src/features/classes/domain/section_model.dart';
import 'package:frontend/src/features/classes/presentation/admin/classroom_management_screen.dart';
import 'package:frontend/src/features/classes/presentation/widgets/classes_lookup.dart';

class _FakeClassroomCtrl extends AsyncNotifier<List<ClassroomModel>>
    implements ClassroomController {
  final List<ClassroomModel> _initial;
  _FakeClassroomCtrl(this._initial);

  @override
  Future<List<ClassroomModel>> build() async {
    state = AsyncData(_initial);
    return _initial;
  }

  @override
  Future<ClassroomModel> save(ClassroomModel room, {bool isNew = false}) async {
    final idx = _initial.indexWhere((r) => r.id == room.id);
    if (idx >= 0) {
      _initial[idx] = room;
    } else {
      _initial.add(room);
    }
    state = AsyncValue.data(List.from(_initial));
    return room;
  }

  @override
  Future<void> delete(String id) async {
    _initial.removeWhere((r) => r.id == id);
    state = AsyncValue.data(List.from(_initial));
  }

  @override
  Future<void> importJson(String rawJson) async {}
}

class _FakeSectionsCtrl extends AsyncNotifier<List<SectionModel>>
    implements SectionsController {
  final List<SectionModel> _initial;
  _FakeSectionsCtrl(this._initial);

  @override
  Future<List<SectionModel>> build() async {
    state = AsyncData(_initial);
    return _initial;
  }

  @override
  Future<SectionModel> save(SectionModel section, {bool isNew = false}) async =>
      section;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> importJson(String rawJson) async {}
}

class _FakeAdmissionsListNotifier
    extends AsyncNotifier<List<StudentAdmissionModel>>
    implements AdmissionsListNotifier {
  final List<StudentAdmissionModel> _initial;
  _FakeAdmissionsListNotifier(this._initial);

  @override
  Future<List<StudentAdmissionModel>> build() async {
    state = AsyncData(_initial);
    return _initial;
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<StudentAdmissionModel> saveAdmission(
    StudentAdmissionModel admission,
  ) async => admission;

  @override
  Future<void> suspendStudent(String studentId) async {}

  @override
  Future<void> deleteAdmission(String studentId) async {}
}

StudentAdmissionModel _makeAdmission(
  String id,
  String classId,
  String sectionId, {
  String className = 'Class 5',
  String section = 'A',
}) {
  return StudentAdmissionModel.fromJson({
    'user': {
      'id': 'usr-$id',
      'email': '$id@test.com',
      'phone_number': '1234567890',
      'user_role': 'STUDENT',
      'first_name': 'First$id',
      'last_name': 'Last$id',
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-01T00:00:00.000Z',
    },
    'student': {
      'id': 'std-$id',
      'user_id': 'usr-$id',
      'admission_number': 'ADM-$id',
      'class_name': className,
      'section': section,
      'section_id': sectionId,
      'current_class_id': classId,
      'admission_date': '2026-01-01T00:00:00.000Z',
      'academic_year': '2026-2027',
      'emergency_contact_phone': '1234567890',
      'current_address': '123 Main Street',
      'residential_address': '123 Main Street',
    },
  });
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  const room101 = ClassroomModel(
    id: 'room-101',
    name: 'Room 101',
    building: 'Block A',
    capacity: 40,
    floor: '1st Floor',
    roomType: 'Theory',
  );

  const room102 = ClassroomModel(
    id: 'room-102',
    name: 'Room 102',
    building: 'Block A',
    capacity: 30,
    floor: '1st Floor',
    roomType: 'Practical',
  );

  const room103 = ClassroomModel(
    id: 'room-103',
    name: 'Room 103',
    building: 'Block B',
    capacity: 25,
    floor: '2nd Floor',
    roomType: 'Computer Lab',
  );

  const class5A = ClassModel(
    id: 'cls-5a',
    name: 'Class 5',
    gradeLevel: 5,
    academicYear: '2026-2027',
    capacity: 40,
  );

  const sec5A = SectionModel(
    id: 'sec-5a',
    classId: 'cls-5a',
    name: 'A',
    capacity: 40,
    classroomId: 'room-101',
  );

  const class6B = ClassModel(
    id: 'cls-6b',
    name: 'Class 6',
    gradeLevel: 6,
    academicYear: '2026-2027',
    capacity: 30,
  );

  const sec6B = SectionModel(
    id: 'sec-6b',
    classId: 'cls-6b',
    name: 'B',
    capacity: 30,
    classroomId: 'room-102',
  );

  // 3 students in room 101 (Class 5 - A)
  final studentsRoom101 = [
    _makeAdmission(
      's1',
      'cls-5a',
      'sec-5a',
      className: 'Class 5',
      section: 'A',
    ),
    _makeAdmission(
      's2',
      'cls-5a',
      'sec-5a',
      className: 'Class 5',
      section: 'A',
    ),
    _makeAdmission(
      's3',
      'cls-5a',
      'sec-5a',
      className: 'Class 5',
      section: 'A',
    ),
  ];

  // 30 students in room 102 (Class 6 - B)
  final studentsRoom102 = List.generate(
    30,
    (i) => _makeAdmission(
      's102_$i',
      'cls-6b',
      'sec-6b',
      className: 'Class 6',
      section: 'B',
    ),
  );

  final allAdmissions = [...studentsRoom101, ...studentsRoom102];

  final testLookup = ClassesLookup(
    classes: const [class5A, class6B],
    sections: const [sec5A, sec6B],
    classrooms: const [room101, room102, room103],
    teachers: const [],
    subjects: const [],
  );

  Widget createWidget({
    void Function(String?)? onOpenClass,
    List<ClassroomModel>? customRooms,
  }) {
    final roomsToUse = customRooms ?? [room101, room102, room103];
    return ProviderScope(
      overrides: [
        activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
        classroomControllerProvider.overrideWith(
          () => _FakeClassroomCtrl(List.from(roomsToUse)),
        ),
        sectionsControllerProvider.overrideWith(
          () => _FakeSectionsCtrl([sec5A, sec6B]),
        ),
        classesLookupProvider.overrideWithValue(testLookup),
        admissionsListProvider.overrideWith(
          () => _FakeAdmissionsListNotifier(allAdmissions),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ClassroomManagementScreen(onOpenClass: onOpenClass),
        ),
      ),
    );
  }

  testWidgets(
    'Classroom screen displays 6 columns in exact order, dynamic strength, enrollment, and status',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Verify 6 columns in DataTable in exact order:
      // Room Number, Room Type, Floor, Assigned Class / Sections, Total (Class Strength / Room Capacity), Status
      expect(find.text('Room Number'), findsOneWidget);
      expect(find.text('Room Type'), findsOneWidget);
      expect(find.text('Floor'), findsOneWidget);
      expect(find.text('Assigned Class / Sections'), findsOneWidget);
      expect(
        find.text('Total (Class Strength / Room Capacity)'),
        findsOneWidget,
      );
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Actions'), findsOneWidget);

      // Verify dynamic calculations in Total column:
      // Room 101: 40 / 40, Class Strength: 40, Students Enrolled: 3, 37 Seats Available
      expect(find.text('40 / 40'), findsOneWidget);
      expect(find.text('Class Strength: 40'), findsOneWidget);
      expect(find.text('Students Enrolled: 3'), findsOneWidget);
      expect(find.text('37 Seats Available'), findsOneWidget);

      // Room 102: 30 / 30, Class Strength: 30, Students Enrolled: 30, 0 Seats Available
      expect(find.text('30 / 30'), findsOneWidget);
      expect(find.text('Class Strength: 30'), findsOneWidget);
      expect(find.text('Students Enrolled: 30'), findsOneWidget);
      expect(find.text('0 Seats Available'), findsOneWidget);

      // Room 103 (unassigned): 0 / 25, Class Strength: 0, Students Enrolled: 0, 25 Seats Available
      expect(find.text('0 / 25'), findsOneWidget);
      expect(find.text('Class Strength: 0'), findsOneWidget);
      expect(find.text('Students Enrolled: 0'), findsOneWidget);
      expect(find.text('25 Seats Available'), findsOneWidget);

      // Verify Room Types displayed in table
      expect(find.text('Theory'), findsOneWidget);
      expect(find.text('Practical'), findsOneWidget);
      expect(find.text('Computer Lab'), findsOneWidget);

      // Verify automatic statuses
      expect(find.text('Assigned'), findsWidgets);
      expect(find.text('Unassigned'), findsWidgets);
    },
  );

  testWidgets(
    'Room Number navigation opens Room Details with all details including Room Type and back button',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Click Room 101 link
      await tester.tap(find.text('Room 101'));
      await tester.pumpAndSettle();

      // In Room Details view:
      expect(
        find.text('Dashboard / Classes / Classrooms / Room 101'),
        findsOneWidget,
      );
      expect(find.text('Classroom Details: Room 101'), findsOneWidget);
      expect(find.text('Room Type'), findsWidgets);
      expect(find.text('1st Floor'), findsWidgets);
      expect(find.text('Block A'), findsWidgets);
      expect(find.text('40 Seats'), findsOneWidget);
      expect(find.text('40 / 40'), findsOneWidget);
      expect(find.text('3 Students'), findsOneWidget);
      expect(find.text('37 Seats'), findsWidgets);

      // Tap Back button
      expect(find.text('Back to Classroom Inventory'), findsOneWidget);
      await tester.tap(find.text('Back to Classroom Inventory'));
      await tester.pumpAndSettle();

      // Returned to table
      expect(find.text('Room Inventory'), findsOneWidget);
    },
  );

  testWidgets(
    'Clicking Total (Class Strength / Room Capacity) navigates to Academic Class page',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? openedClassId;
      await tester.pumpWidget(
        createWidget(onOpenClass: (classId) => openedClassId = classId),
      );
      await tester.pumpAndSettle();

      // Tap Total cell for Room 101 (assigned to Class 5 – A)
      await tester.tap(find.text('40 / 40'));
      await tester.pumpAndSettle();

      expect(openedClassId, 'cls-5a');
    },
  );

  testWidgets('Clicking Assigned Class navigates to Academic Class page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? openedClassId;
    await tester.pumpWidget(
      createWidget(onOpenClass: (classId) => openedClassId = classId),
    );
    await tester.pumpAndSettle();

    // Find clickable Class 5 text (assigned summary is "Class 5 – A")
    final classWidget = find.text('Class 5 – A');
    expect(classWidget, findsOneWidget);

    await tester.tap(classWidget);
    await tester.pumpAndSettle();

    expect(openedClassId, 'cls-5a');
  });

  testWidgets(
    'Status filter and search work together and filter Section Name',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Initially all 3 rooms visible
      expect(find.text('Room 101'), findsOneWidget);
      expect(find.text('Room 102'), findsOneWidget);
      expect(find.text('Room 103'), findsOneWidget);

      // Filter by assignment status: Assigned
      final statusDropdown = find.text('All').first;
      await tester.tap(statusDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Assigned').last);
      await tester.pumpAndSettle();

      // Assigned rooms remain visible regardless of their remaining capacity.
      expect(find.text('Room 101'), findsOneWidget);
      expect(find.text('Room 102'), findsOneWidget);
      expect(find.text('Room 103'), findsNothing);

      // Reset status to All
      await tester.tap(find.text('Assigned').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('All').last);
      await tester.pumpAndSettle();

      // Search by class/section name "Class 6"
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Class 6');
      await tester.pumpAndSettle();

      // Only Room 102 matches Class 6
      expect(find.text('Room 102'), findsOneWidget);
      expect(find.text('Room 101'), findsNothing);
      expect(find.text('Room 103'), findsNothing);
    },
  );

  testWidgets(
    'Sorting with up and down arrows sorts rows ascending and descending',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Verify 6 pairs of up/down arrows in DataTable (6 sortable columns)
      final upArrows = find.descendant(
        of: find.byType(DataTable),
        matching: find.byIcon(Icons.arrow_drop_up),
      );
      final downArrows = find.descendant(
        of: find.byType(DataTable),
        matching: find.byIcon(Icons.arrow_drop_down),
      );
      expect(upArrows, findsNWidgets(6));
      expect(downArrows, findsNWidgets(6));

      // Tap on Down Arrow for Room Number to sort descending
      await tester.tap(downArrows.first);
      await tester.pumpAndSettle();

      // Tap on Up Arrow for Room Number to sort ascending
      await tester.tap(upArrows.first);
      await tester.pumpAndSettle();

      expect(find.text('Room 101'), findsOneWidget);
      expect(find.text('Room 102'), findsOneWidget);
      expect(find.text('Room 103'), findsOneWidget);
    },
  );

  testWidgets(
    'Add Classroom modal includes Room Type with Theory, Practical, Others options and custom validation',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Open Add Classroom Modal
      await tester.tap(find.text('Add Classroom'));
      await tester.pumpAndSettle();

      expect(find.text('Add Classroom'), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Room Type'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Assignment Status'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Unassigned'),
        ),
        findsOneWidget,
      );
      expect(find.text('Theory'), findsWidgets);

      // Select "Others" in Room Type
      await tester.tap(find.text('Theory').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Others').last);
      await tester.pumpAndSettle();

      // Verify custom room type field appears
      expect(find.text('Custom Room Type'), findsOneWidget);

      // Enter Room Number and Total Seats
      final textFields = find.byType(TextFormField);
      // 1st text form field: Room Number
      await tester.enterText(textFields.at(0), 'Room 999');
      // 4th text form field: Total Seats (at index 3)
      await tester.enterText(textFields.at(3), '40');

      // Tap save button (FilledButton in dialog)
      final saveBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      );
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Custom room type validation error appears
      expect(
        find.text('Please enter a custom room type when "Others" is selected.'),
        findsOneWidget,
      );
    },
  );
}
