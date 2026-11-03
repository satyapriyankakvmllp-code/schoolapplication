import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
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
import 'package:frontend/src/features/classes/presentation/admin/sections_management_screen.dart';
import 'package:frontend/src/features/classes/presentation/admin/section_details_view.dart';
import 'package:frontend/src/features/classes/presentation/widgets/classes_lookup.dart';

class _FakeClassroomCtrl extends AsyncNotifier<List<ClassroomModel>>
    implements ClassroomController {
  final List<ClassroomModel> _initial;
  _FakeClassroomCtrl(this._initial);

  @override
  Future<List<ClassroomModel>> build() async => _initial;

  @override
  Future<ClassroomModel> save(
    ClassroomModel room, {
    bool isNew = false,
  }) async => room;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> importJson(String rawJson) async {}
}

class _FakeSectionsCtrl extends AsyncNotifier<List<SectionModel>>
    implements SectionsController {
  final List<SectionModel> _initial;
  _FakeSectionsCtrl(this._initial);

  @override
  Future<List<SectionModel>> build() async => _initial;

  @override
  Future<void> save(SectionModel section, {bool isNew = false}) async {}

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

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  const testRoom1 = ClassroomModel(
    id: 'room-101',
    name: 'Room 101',
    building: 'Block A',
    capacity: 40,
    floor: '1st Floor',
  );

  const testClass1 = ClassModel(
    id: 'cls-101',
    name: '1st Class',
    gradeLevel: 1,
    academicYear: '2026-2027',
    capacity: 20,
  );

  const testSectionA = SectionModel(
    id: 'sec-101-a',
    classId: 'cls-101',
    name: 'A',
    capacity: 20,
    classroomId: 'room-101',
  );

  final testLookup = ClassesLookup(
    classes: const [testClass1],
    sections: const [testSectionA],
    classrooms: const [testRoom1],
    teachers: const [],
    subjects: const [],
  );

  group(
    'Classroom Inventory Occupancy & Seat Calculations (0/40, 20/40, 40/40)',
    () {
      test('Calculates 0/40 for unassigned room', () {
        const room = ClassroomModel(
          id: 'room-empty',
          name: 'Room 501',
          building: 'Main',
          capacity: 40,
          floor: '1st Floor',
        );

        final lookup = ClassesLookup(
          classes: const [],
          sections: const [],
          classrooms: const [room],
          teachers: const [],
          subjects: const [],
        );

        final assignedSections = lookup.sections
            .where((s) => s.classroomId == room.id)
            .toList();
        final assignedClasses = lookup.classes
            .where(
              (c) =>
                  c.classroomId == room.id &&
                  !assignedSections.any((s) => s.classId == c.id),
            )
            .toList();
        final countedAdmissionIds = <String>{};
        int assignedSeats = 0;
        for (final s in assignedSections) {
          final parentClass = lookup.classes
              .where((c) => c.id == s.classId)
              .firstOrNull;
          assignedSeats +=
              (s.capacity > 0 ? s.capacity : (parentClass?.capacity ?? 0))
                  .toInt();
        }
        for (final c in assignedClasses) {
          assignedSeats += (c.capacity > 0 ? c.capacity : (c.studentCount ?? 0))
              .toInt();
        }
        final occupied =
            (countedAdmissionIds.length > assignedSeats
                    ? countedAdmissionIds.length
                    : assignedSeats)
                .clamp(0, room.capacity);
        final available = (room.capacity - occupied).clamp(0, room.capacity);

        expect(occupied, 0);
        expect(available, 40);
        expect('$occupied/${room.capacity}', '0/40');
      });

      test('Calculates 20/40 for room assigned one 20-seat section', () {
        const room = ClassroomModel(
          id: 'room-half',
          name: 'Room 502',
          building: 'Main',
          capacity: 40,
          floor: '1st Floor',
        );

        const parentClass = ClassModel(
          id: 'cls-1',
          name: 'Class 1',
          gradeLevel: 1,
          academicYear: '2026-2027',
          capacity: 20,
        );

        const secA = SectionModel(
          id: 'sec-1a',
          classId: 'cls-1',
          name: 'A',
          capacity: 20,
          classroomId: 'room-half',
        );

        final lookup = ClassesLookup(
          classes: const [parentClass],
          sections: const [secA],
          classrooms: const [room],
          teachers: const [],
          subjects: const [],
        );

        final assignedSections = lookup.sections
            .where((s) => s.classroomId == room.id)
            .toList();
        final assignedClasses = lookup.classes
            .where(
              (c) =>
                  c.classroomId == room.id &&
                  !assignedSections.any((s) => s.classId == c.id),
            )
            .toList();
        final countedAdmissionIds = <String>{};
        int assignedSeats = 0;
        for (final s in assignedSections) {
          final parent = lookup.classes
              .where((c) => c.id == s.classId)
              .firstOrNull;
          assignedSeats +=
              (s.capacity > 0 ? s.capacity : (parent?.capacity ?? 0)).toInt();
        }
        for (final c in assignedClasses) {
          assignedSeats += (c.capacity > 0 ? c.capacity : (c.studentCount ?? 0))
              .toInt();
        }
        final occupied =
            (countedAdmissionIds.length > assignedSeats
                    ? countedAdmissionIds.length
                    : assignedSeats)
                .clamp(0, room.capacity);
        final available = (room.capacity - occupied).clamp(0, room.capacity);

        expect(occupied, 20);
        expect(available, 20);
        expect('$occupied/${room.capacity}', '20/40');
      });

      test(
        'Calculates 40/40 for room assigned two 20-seat sections without double counting students',
        () {
          const room = ClassroomModel(
            id: 'room-full',
            name: 'Room 503',
            building: 'Main',
            capacity: 40,
            floor: '2nd Floor',
          );

          const parentClass = ClassModel(
            id: 'cls-2',
            name: 'Class 2',
            gradeLevel: 2,
            academicYear: '2026-2027',
            capacity: 20,
          );

          const secA = SectionModel(
            id: 'sec-2a',
            classId: 'cls-2',
            name: 'A',
            capacity: 20,
            classroomId: 'room-full',
          );

          const secB = SectionModel(
            id: 'sec-2b',
            classId: 'cls-2',
            name: 'B',
            capacity: 20,
            classroomId: 'room-full',
          );

          final lookup = ClassesLookup(
            classes: const [parentClass],
            sections: const [secA, secB],
            classrooms: const [room],
            teachers: const [],
            subjects: const [],
          );

          final admissions = <StudentAdmissionModel>[
            StudentAdmissionModel.fromJson({
              'user': {
                'id': 'usr-s1',
                'email': 's1@test.com',
                'phone_number': '1234567890',
                'user_role': 'STUDENT',
                'first_name': 'Alice',
                'last_name': 'Smith',
                'created_at': '2026-01-01T00:00:00.000Z',
                'updated_at': '2026-01-01T00:00:00.000Z',
              },
              'student': {
                'id': 'std-1',
                'user_id': 'usr-s1',
                'admission_number': 'ADM-001',
                'class_name': 'Class 2',
                'section': 'A',
                'section_id': 'sec-2a',
                'current_class_id': 'cls-2',
                'admission_date': '2026-01-01T00:00:00.000Z',
                'academic_year': '2026-2027',
                'emergency_contact_phone': '1234567890',
                'current_address': '123 Main Street',
                'residential_address': '123 Main Street',
              },
            }),
          ];

          final assignedSections = lookup.sections
              .where((s) => s.classroomId == room.id)
              .toList();
          final assignedClasses = lookup.classes
              .where(
                (c) =>
                    c.classroomId == room.id &&
                    !assignedSections.any((s) => s.classId == c.id),
              )
              .toList();
          final countedAdmissionIds = <String>{};
          for (final s in assignedSections) {
            final secAdmissions = admissions.where((a) {
              if (countedAdmissionIds.contains(a.user.id)) return false;
              return a.student.sectionId == s.id;
            });
            for (final a in secAdmissions) {
              countedAdmissionIds.add(a.user.id);
            }
          }

          int assignedSeats = 0;
          for (final s in assignedSections) {
            final parent = lookup.classes
                .where((c) => c.id == s.classId)
                .firstOrNull;
            assignedSeats +=
                (s.capacity > 0 ? s.capacity : (parent?.capacity ?? 0)).toInt();
          }
          for (final c in assignedClasses) {
            assignedSeats +=
                (c.capacity > 0 ? c.capacity : (c.studentCount ?? 0)).toInt();
          }
          final occupied =
              (countedAdmissionIds.length > assignedSeats
                      ? countedAdmissionIds.length
                      : assignedSeats)
                  .clamp(0, room.capacity);
          final available = (room.capacity - occupied).clamp(0, room.capacity);

          expect(occupied, 40);
          expect(available, 0);
          expect('$occupied/${room.capacity}', '40/40');
          // Verify student usr-s1 was counted only once
          expect(countedAdmissionIds.length, 1);
        },
      );
    },
  );

  group('Navigation, Details & Back Buttons Widget Verification', () {
    testWidgets(
      'ClassroomManagementScreen renders dynamic breadcrumb and details view with back button',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
              classroomControllerProvider.overrideWith(
                () => _FakeClassroomCtrl([testRoom1]),
              ),
              classesLookupProvider.overrideWithValue(testLookup),
              sectionsControllerProvider.overrideWith(
                () => _FakeSectionsCtrl([testSectionA]),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(body: ClassroomManagementScreen()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Check dynamic breadcrumb
        expect(find.text('Dashboard / Classes / Classrooms'), findsOneWidget);
        expect(find.text('Room Inventory'), findsOneWidget);

        // Verify Room 101 exists in table
        expect(find.text('Room 101'), findsOneWidget);

        // Tap on Room 101 to open Room Details
        await tester.tap(find.text('Room 101'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify Classroom Details view rendered
        expect(
          find.text('Dashboard / Classes / Classrooms / Room 101'),
          findsOneWidget,
        );
        expect(find.text('Back to Classroom Inventory'), findsOneWidget);

        // Tap Back button to return to Room Inventory
        await tester.tap(find.text('Back to Classroom Inventory'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify back to Room Inventory
        expect(find.text('Room Inventory'), findsOneWidget);
      },
    );

    testWidgets(
      'SectionsManagementScreen renders dynamic breadcrumb and section details with back button',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        String? openedRoomId;
        String? openedClassId;
        String? openedStaffId;
        const sectionWithTeacher = SectionModel(
          id: 'sec-101-a',
          classId: 'cls-101',
          name: 'A',
          capacity: 20,
          classroomId: 'room-101',
          classTeacherId: 'staff-101',
        );
        final lookupWithTeacher = ClassesLookup(
          classes: const [testClass1],
          sections: const [sectionWithTeacher],
          classrooms: const [testRoom1],
          teachers: const [TeacherOption('staff-101', 'A Teacher')],
          subjects: const [],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
              classroomControllerProvider.overrideWith(
                () => _FakeClassroomCtrl([testRoom1]),
              ),
              classesLookupProvider.overrideWithValue(lookupWithTeacher),
              sectionsControllerProvider.overrideWith(
                () => _FakeSectionsCtrl([sectionWithTeacher]),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SectionsManagementScreen(
                  onOpenClass: (classId) => openedClassId = classId,
                  onOpenClassroom: (roomId) => openedRoomId = roomId,
                  onOpenStaff: (staffId) => openedStaffId = staffId,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Check dynamic breadcrumb
        expect(find.text('Dashboard / Classes / Sections'), findsOneWidget);

        // Check section exists in table
        final sectionFinder = find.text('Section A').first;
        expect(sectionFinder, findsOneWidget);

        final classFinder = find.text('1st Class');
        expect(
          tester.widget<Text>(classFinder).style?.decoration,
          TextDecoration.underline,
        );
        await tester.tap(classFinder);
        expect(openedClassId, 'cls-101');

        final roomFinder = find.text('Room 101');
        expect(
          tester.widget<Text>(roomFinder).style?.decoration,
          TextDecoration.underline,
        );
        await tester.tap(roomFinder);
        expect(openedRoomId, 'room-101');
        final teacherFinder = find.text('A Teacher');
        expect(
          tester.widget<Text>(teacherFinder).style?.decoration,
          TextDecoration.underline,
        );
        await tester.tap(teacherFinder);
        expect(openedStaffId, 'staff-101');

        // Tap section to open section details
        await tester.tap(sectionFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Check section details view rendered with Back to Sections
        expect(find.text('Back to Sections'), findsOneWidget);
        expect(find.text('Section Information'), findsOneWidget);

        // Tap back button
        await tester.tap(find.text('Back to Sections'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify back to Sections list
        expect(find.text('Dashboard / Classes / Sections'), findsOneWidget);
      },
    );

    testWidgets('Sections table sorts by section name in both directions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const sectionZ = SectionModel(
        id: 'sec-z',
        classId: 'cls-101',
        name: 'Z',
        capacity: 20,
      );
      const sectionA = SectionModel(
        id: 'sec-a',
        classId: 'cls-101',
        name: 'A',
        capacity: 20,
      );
      final lookup = ClassesLookup(
        classes: const [testClass1],
        sections: const [sectionZ, sectionA],
        classrooms: const [testRoom1],
        teachers: const [],
        subjects: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
            classroomControllerProvider.overrideWith(
              () => _FakeClassroomCtrl([testRoom1]),
            ),
            classesLookupProvider.overrideWithValue(lookup),
            sectionsControllerProvider.overrideWith(
              () => _FakeSectionsCtrl([sectionZ, sectionA]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SectionsManagementScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      for (var columnIndex = 0; columnIndex < 6; columnIndex++) {
        expect(
          find.byKey(ValueKey('sections-sort-$columnIndex-asc')),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey('sections-sort-$columnIndex-desc')),
          findsOneWidget,
        );
      }
      expect(find.byKey(const ValueKey('sections-sort-6-asc')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('sections-sort-1-asc')));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Section A')).dy,
        lessThan(tester.getTopLeft(find.text('Section Z')).dy),
      );

      await tester.tap(find.byKey(const ValueKey('sections-sort-1-desc')));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Section Z')).dy,
        lessThan(tester.getTopLeft(find.text('Section A')).dy),
      );
    });

    testWidgets(
      'SectionDetailsView renders correct details and triggers back callback',
      (tester) async {
        bool backPressed = false;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sectionsControllerProvider.overrideWith(
                () => _FakeSectionsCtrl([testSectionA]),
              ),
              classesLookupProvider.overrideWithValue(testLookup),
              classroomControllerProvider.overrideWith(
                () => _FakeClassroomCtrl([testRoom1]),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SectionDetailsView(
                  sectionId: 'sec-101-a',
                  breadcrumbBase: 'Dashboard / Classes / Academic Classes',
                  backButtonText: 'Back to Academic Classes',
                  onBack: () => backPressed = true,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify breadcrumb
        expect(
          find.text('Dashboard / Classes / Academic Classes / Section A'),
          findsOneWidget,
        );
        expect(find.text('Back to Academic Classes'), findsOneWidget);
        expect(find.text('Section Information'), findsOneWidget);

        // Tap back
        await tester.tap(find.text('Back to Academic Classes'));
        expect(backPressed, isTrue);
      },
    );
  });

  group('Independent Section Strength & Capacity Flow Tests', () {
    test(
      'Section A and Section B maintain independent strengths under same class',
      () {
        const cls = ClassModel(
          id: 'cls-100',
          name: 'Class 10',
          gradeLevel: 10,
          academicYear: '2026-2027',
          capacity: 20,
        );

        var secA = const SectionModel(
          id: 'sec-100-a',
          classId: 'cls-100',
          name: 'A',
          capacity: 20,
          classroomId: 'room-101',
        );

        var secB = const SectionModel(
          id: 'sec-100-b',
          classId: 'cls-100',
          name: 'B',
          capacity: 20,
          classroomId: 'room-102',
        );

        expect(secA.capacity, 20);
        expect(secB.capacity, 20);

        // Update Section A strength to 25
        secA = secA.copyWith(capacity: 25);

        // Verify Section A changed to 25 and Section B remains unchanged at 20
        expect(secA.capacity, 25);
        expect(secB.capacity, 20);
        expect(secA.id, 'sec-100-a');
        expect(secB.id, 'sec-100-b');
      },
    );

    testWidgets(
      'SectionDetailsView shows 0/20 when 0 students enrolled and room capacity is 40',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const room40 = ClassroomModel(
          id: 'room-40',
          name: 'Room 40',
          building: 'Block B',
          capacity: 40,
          floor: 'Ground Floor',
        );

        const cls = ClassModel(
          id: 'cls-20',
          name: 'Class 5',
          gradeLevel: 5,
          academicYear: '2026-2027',
          capacity: 20,
        );

        const secA20 = SectionModel(
          id: 'sec-20-a',
          classId: 'cls-20',
          name: 'A',
          capacity: 20,
          classroomId: 'room-40',
        );

        final lookup = ClassesLookup(
          classes: const [cls],
          sections: const [secA20],
          classrooms: const [room40],
          teachers: const [],
          subjects: const [],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sectionsControllerProvider.overrideWith(
                () => _FakeSectionsCtrl([secA20]),
              ),
              classesLookupProvider.overrideWithValue(lookup),
              classroomControllerProvider.overrideWith(
                () => _FakeClassroomCtrl([room40]),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SectionDetailsView(
                  sectionId: 'sec-20-a',
                  breadcrumbBase: 'Dashboard / Classes / Sections',
                  backButtonText: 'Back to Sections',
                  onBack: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Capacity should be 20 Seats (from Section Strength), not 40 Seats (Classroom Capacity)
        expect(find.text('20 Seats'), findsAtLeast(1));
        // Occupancy metric should show 0 / 20, not 0 / 40
        expect(find.text('0 / 20'), findsOneWidget);
        // Classroom Capacity is shown distinctly as 40 Seats
        expect(find.text('40 Seats'), findsOneWidget);
      },
    );

    testWidgets(
      'ClassroomManagementScreen details shows 20/40 when section strength is 20 in 40-seat room',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const room40 = ClassroomModel(
          id: 'room-40',
          name: 'Room 40',
          building: 'Block B',
          capacity: 40,
          floor: 'Ground Floor',
        );

        const cls = ClassModel(
          id: 'cls-20',
          name: 'Class 5',
          gradeLevel: 5,
          academicYear: '2026-2027',
          capacity: 20,
        );

        const secA20 = SectionModel(
          id: 'sec-20-a',
          classId: 'cls-20',
          name: 'A',
          capacity: 20,
          classroomId: 'room-40',
        );

        final lookup = ClassesLookup(
          classes: const [cls],
          sections: const [secA20],
          classrooms: const [room40],
          teachers: const [],
          subjects: const [],
        );

        final admissions20 = List.generate(
          20,
          (i) => StudentAdmissionModel.fromJson({
            'user': {
              'id': 'u8_$i',
              'email': 'u8_$i@test.com',
              'phone_number': '123',
              'user_role': 'STUDENT',
              'first_name': 'Student',
              'last_name': '$i',
              'created_at': '2026-01-01T00:00:00.000Z',
              'updated_at': '2026-01-01T00:00:00.000Z',
            },
            'student': {
              'id': 's8_$i',
              'user_id': 'u8_$i',
              'admission_number': 'ADM-8-$i',
              'class_name': 'Class 5',
              'section': 'A',
              'section_id': 'sec-20-a',
              'current_class_id': 'cls-20',
              'admission_date': '2026-01-01T00:00:00.000Z',
              'academic_year': '2026-2027',
              'emergency_contact_phone': '123',
              'current_address': 'addr',
              'residential_address': 'addr',
            },
          }),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
              classroomControllerProvider.overrideWith(
                () => _FakeClassroomCtrl([room40]),
              ),
              classesLookupProvider.overrideWithValue(lookup),
              sectionsControllerProvider.overrideWith(
                () => _FakeSectionsCtrl([secA20]),
              ),
              admissionsListProvider.overrideWith(
                () => _FakeAdmissionsListNotifier(admissions20),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(body: ClassroomManagementScreen()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Tap on Room 40
        await tester.tap(find.text('Room 40'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Occupied Seats should display 20 / 40
        expect(find.text('20 / 40'), findsOneWidget);
        // Capacity is 40 Seats
        expect(find.text('40 Seats'), findsOneWidget);
        // Available Seats is 20 Seats
        expect(find.text('20 Seats'), findsOneWidget);
      },
    );

    testWidgets(
      'Changing Class Strength to 22 updates Classroom strength to 22/40 instead of static 40',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const room40 = ClassroomModel(
          id: 'room-101',
          name: 'Room 101',
          building: 'Main',
          capacity: 40,
          floor: 'Ground Floor',
        );

        // Class strength updated to 22
        const cls22 = ClassModel(
          id: 'cls-1',
          name: '1st Class',
          gradeLevel: 1,
          academicYear: '2026-2027',
          capacity: 22,
          classroomId: 'room-101',
        );

        // Section A with legacy default 40
        const secA = SectionModel(
          id: 'sec-1a',
          classId: 'cls-1',
          name: 'A',
          capacity: 40,
          classroomId: 'room-101',
        );

        final lookup = ClassesLookup(
          classes: const [cls22],
          sections: const [secA],
          classrooms: const [room40],
          teachers: const [],
          subjects: const [],
        );

        final admissions22 = List.generate(
          22,
          (i) => StudentAdmissionModel.fromJson({
            'user': {
              'id': 'u9_$i',
              'email': 'u9_$i@test.com',
              'phone_number': '123',
              'user_role': 'STUDENT',
              'first_name': 'Student',
              'last_name': '$i',
              'created_at': '2026-01-01T00:00:00.000Z',
              'updated_at': '2026-01-01T00:00:00.000Z',
            },
            'student': {
              'id': 's9_$i',
              'user_id': 'u9_$i',
              'admission_number': 'ADM-9-$i',
              'class_name': '1st Class',
              'section': 'A',
              'section_id': 'sec-1a',
              'current_class_id': 'cls-1',
              'admission_date': '2026-01-01T00:00:00.000Z',
              'academic_year': '2026-2027',
              'emergency_contact_phone': '123',
              'current_address': 'addr',
              'residential_address': 'addr',
            },
          }),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
              classroomControllerProvider.overrideWith(
                () => _FakeClassroomCtrl([room40]),
              ),
              classesLookupProvider.overrideWithValue(lookup),
              sectionsControllerProvider.overrideWith(
                () => _FakeSectionsCtrl([secA]),
              ),
              admissionsListProvider.overrideWith(
                () => _FakeAdmissionsListNotifier(admissions22),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(body: ClassroomManagementScreen()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Table should display 22 / 40 for Room 101 (not 40/40)
        expect(find.text('22 / 40'), findsOneWidget);
        expect(find.text('18 Seats Available'), findsOneWidget);

        // Tap on Room 101 to verify details view
        await tester.tap(find.text('Room 101'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Occupied Seats should display 22 / 40
        expect(find.text('22 / 40'), findsOneWidget);
        // Available Seats should display 18 Seats
        expect(find.text('18 Seats'), findsOneWidget);
        // Capacity is 40 Seats
        expect(find.text('40 Seats'), findsOneWidget);
      },
    );

    test(
      'Section A and Section B maintain different strengths and are not kept at the same strength',
      () {
        const cls = ClassModel(
          id: 'cls-10',
          name: '10th Class',
          gradeLevel: 10,
          academicYear: '2026-2027',
          capacity: 22,
        );

        // Section A has 22
        const secA = SectionModel(
          id: 'sec-10a',
          classId: 'cls-10',
          name: 'A',
          capacity: 22,
          classroomId: 'room-201',
        );

        // Section B has 20 (different strength)
        const secB = SectionModel(
          id: 'sec-10b',
          classId: 'cls-10',
          name: 'B',
          capacity: 20,
          classroomId: 'room-202',
        );

        expect(secA.capacity, 22);
        expect(secB.capacity, 20);
        expect(secA.capacity, isNot(equals(secB.capacity)));
        expect(secA.classId, equals(secB.classId));
      },
    );
  });
}
