import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/src/features/authentication/domain/user_model.dart';
import 'package:frontend/src/features/authentication/application/auth_controller.dart';
import 'package:frontend/src/features/classes/data/classes_local_datasource.dart';
import 'package:frontend/src/features/classes/domain/class_model.dart';
import 'package:frontend/src/features/classes/domain/classroom_model.dart';
import 'package:frontend/src/features/classes/domain/section_model.dart';
import 'package:frontend/src/features/classes/domain/classes_actor.dart';
import 'package:frontend/src/features/classes/presentation/admin/classes_list_screen.dart';
import 'package:frontend/src/features/classes/presentation/admin/sections_management_screen.dart';
import 'package:frontend/src/features/classes/presentation/widgets/classes_lookup.dart';
import 'package:frontend/src/features/classes/application/classes_controller.dart';
import 'package:frontend/src/features/classes/application/sections_controller.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  const admin = ClassesActor(role: UserRole.admin, userId: 'USR-ADMIN-01');

  group('Class List Module - Form Validation & Capacity Rules', () {
    test('Class strength cannot exceed selected classroom capacity', () async {
      final ds = ClassesLocalDataSource();
      final createdRoom = await ds.saveClassroom(
        admin,
        const ClassroomModel(
          id: '',
          name: 'Room Cap 501',
          building: 'Main',
          capacity: 30,
        ),
        isNew: true,
      );

      // Attempting to save class with strength 35 into room with capacity 30
      expect(
        () => ds.saveClass(
          admin,
          ClassModel(
            id: '',
            name: 'Class Over-Capacity',
            gradeLevel: 10,
            academicYear: '2026-2027',
            classroomId: createdRoom.id,
            capacity: 35,
          ),
          isNew: true,
        ),
        throwsA(isA<ClassesDataException>()),
      );

      // Saving class with strength 30 into room with capacity 30 succeeds
      final ok = await ds.saveClass(
        admin,
        ClassModel(
          id: '',
          name: 'Class Valid Capacity',
          gradeLevel: 10,
          academicYear: '2026-2027',
          classroomId: createdRoom.id,
          capacity: 30,
        ),
        isNew: true,
      );

      expect(ok.capacity, 30);
      expect(ok.classroomId, createdRoom.id);
    });

    test('Class code and name uniqueness validation', () async {
      final ds = ClassesLocalDataSource();

      // Save first class
      await ds.saveClass(
        admin,
        const ClassModel(
          id: 'cls-unique-1',
          name: 'Unique Grade 9',
          code: 'CLS-U9',
          gradeLevel: 9,
          academicYear: '2026-2027',
          capacity: 25,
        ),
        isNew: true,
      );

      // Duplicate class name should throw
      expect(
        () => ds.saveClass(
          admin,
          const ClassModel(
            id: '',
            name: 'unique grade 9', // case insensitive check
            code: 'CLS-DIFF',
            gradeLevel: 9,
            academicYear: '2026-2027',
            capacity: 25,
          ),
          isNew: true,
        ),
        throwsA(isA<ClassesDataException>()),
      );

      // Duplicate class code should throw
      expect(
        () => ds.saveClass(
          admin,
          const ClassModel(
            id: '',
            name: 'Another Class Name',
            code: 'cls-u9', // case insensitive check
            gradeLevel: 9,
            academicYear: '2026-2027',
            capacity: 25,
          ),
          isNew: true,
        ),
        throwsA(isA<ClassesDataException>()),
      );
    });

    test('Class strength cannot be negative', () async {
      final ds = ClassesLocalDataSource();

      expect(
        () => ds.saveClass(
          admin,
          const ClassModel(
            id: '',
            name: 'Negative Capacity Class',
            gradeLevel: 8,
            academicYear: '2026-2027',
            capacity: -5,
          ),
          isNew: true,
        ),
        throwsA(isA<ClassesDataException>()),
      );
    });
  });

  group('Academic Classes UI & Integration Tests', () {
    final fakeClass = const ClassModel(
      id: 'cls-10',
      name: 'Class 10',
      code: 'CLS-10',
      gradeLevel: 10,
      academicYear: '2026-2027',
      classroomId: 'room-101',
      capacity: 20,
      status: 'Active',
    );

    final fakeRoom1 = const ClassroomModel(
      id: 'room-101',
      name: 'Room 101',
      building: 'Main Block',
      capacity: 40,
      status: 'Available',
    );

    final fakeRoom2 = const ClassroomModel(
      id: 'room-102',
      name: 'Room 102',
      building: 'Main Block',
      capacity: 35,
      status: 'Available',
    );

    final fakeSections = [
      const SectionModel(
        id: 'sec-10a',
        classId: 'cls-10',
        name: 'Section A',
        capacity: 20,
      ),
      const SectionModel(
        id: 'sec-10b',
        classId: 'cls-10',
        name: 'Section B',
        capacity: 20,
      ),
    ];

    final fakeSectionsWithRooms = [
      const SectionModel(
        id: 'sec-10a',
        classId: 'cls-10',
        name: 'Section A',
        capacity: 20,
        classroomId: 'room-101',
      ),
      const SectionModel(
        id: 'sec-10b',
        classId: 'cls-10',
        name: 'Section B',
        capacity: 20,
        classroomId: 'room-102',
      ),
    ];

    final fakeLookup = ClassesLookup(
      classes: [fakeClass],
      sections: fakeSections,
      subjects: const [],
      classrooms: [fakeRoom1, fakeRoom2],
      teachers: const [],
    );

    final fakeLookupWithRooms = ClassesLookup(
      classes: [fakeClass],
      sections: fakeSectionsWithRooms,
      subjects: const [],
      classrooms: [fakeRoom1, fakeRoom2],
      teachers: const [],
    );

    testWidgets(
      'Academic Classes displays breadcrumb, separate section rows, distinct rooms, numeric strength, and no assign_room in action menu',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        String? openedRoomId;
        String? openedSectionClassId;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
              classesControllerProvider.overrideWith(
                () => _FakeClassesCtrl([fakeClass]),
              ),
              classesLookupProvider.overrideWithValue(fakeLookupWithRooms),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: AdminClassesListScreen(
                  onOpenClassroom: (roomId) => openedRoomId = roomId,
                  onOpenSections: (classId) => openedSectionClassId = classId,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 1. Heading and Breadcrumb: Dashboard / Classes / Academic Classes
        expect(find.text('Academic Classes'), findsWidgets);
        expect(
          find.text('Dashboard / Classes / Academic Classes'),
          findsOneWidget,
        );

        // Verify columns in exact order
        final dataTable = tester.widget<DataTable>(find.byType(DataTable));
        final colLabels = dataTable.columns.map((column) {
          final label = column.label;
          if (label is Text) return label.data;
          return ((label as Row).children.first as Text).data;
        }).toList();
        expect(colLabels, [
          'Academic Year',
          'Class Code',
          'Class Name',
          'Section Name',
          'Classroom / Room Number',
          'Class Strength',
          'Status',
          'Action',
        ]);
        expect(
          find.byKey(const ValueKey('academic-class-sort-0-asc')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('academic-class-sort-6-desc')),
          findsOneWidget,
        );

        // 5. Verify Section A and Section B are displayed as separate entries/rows (2 rows)
        expect(dataTable.rows.length, 2);
        expect(find.text('Section A'), findsOneWidget);
        expect(find.text('Section B'), findsOneWidget);

        // 6. Verify each section displays its own assigned classroom
        expect(find.text('Room 101'), findsOneWidget);
        expect(find.text('Room 102'), findsOneWidget);

        // 4. Verify Class Strength displays only the numeric value 20, not 20/40
        expect(find.text('20'), findsNWidgets(2)); // One for each row
        expect(find.text('20/40'), findsNothing);

        // Verify Underlines on Class Code, Class Name, Classroom Number, and Section
        final codeTexts = tester.widgetList<Text>(find.text('CLS-10'));
        for (final ct in codeTexts) {
          expect(ct.style?.decoration, TextDecoration.underline);
        }

        final sectionAText = tester.widget<Text>(find.text('Section A'));
        expect(sectionAText.style?.decoration, TextDecoration.underline);

        final room1Text = tester.widget<Text>(find.text('Room 101'));
        expect(room1Text.style?.decoration, TextDecoration.underline);

        // Clicking Section opens Section Details view, with back button to Academic Classes
        await tester.tap(find.text('Section A'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Back to Academic Classes'), findsOneWidget);
        await tester.tap(find.text('Back to Academic Classes'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Clicking Classroom Number calls onOpenClassroom with that section's room
        await tester.tap(find.text('Room 101'));
        await tester.pump();
        expect(openedRoomId, 'room-101');

        // 3. Three-Dot Menu: remove Assign Room option, retain View, Edit, Deactivate, Delete
        final moreVert = find.byIcon(Icons.more_vert).first;
        await tester.ensureVisible(moreVert);
        await tester.tap(moreVert);
        await tester.pumpAndSettle();

        expect(find.text('Assign Classroom'), findsNothing);
        expect(find.text('Assign Room'), findsNothing);
        expect(find.text('View'), findsOneWidget);
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Deactivate'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);

        // Dismiss menu
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // 2. Export JSON option works correctly and shows current class data
        final exportBtn = find.text('Export JSON');
        expect(exportBtn, findsOneWidget);
        await tester.tap(exportBtn);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Global School JSON Data'), findsOneWidget);
        expect(find.text('Copy JSON to Clipboard'), findsOneWidget);
        expect(find.byType(SelectableText), findsOneWidget);

        // Close export dialog
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets('Academic Classes sorts rows from sortable column arrows', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const alphaClass = ClassModel(
        id: 'cls-alpha',
        name: 'Alpha Class',
        code: 'Z-2',
        gradeLevel: 2,
        academicYear: '2026-2027',
        classroomId: 'room-z',
        capacity: 20,
        status: 'Active',
      );
      const betaClass = ClassModel(
        id: 'cls-beta',
        name: 'Beta Class',
        code: 'A-1',
        gradeLevel: 1,
        academicYear: '2025-2026',
        classroomId: 'room-a',
        capacity: 15,
        status: 'Inactive',
      );
      const sectionZ = SectionModel(
        id: 'sec-z',
        classId: 'cls-alpha',
        name: 'Section Z',
        capacity: 20,
        classroomId: 'room-z',
      );
      const sectionA = SectionModel(
        id: 'sec-a',
        classId: 'cls-beta',
        name: 'Section A',
        capacity: 15,
        classroomId: 'room-a',
      );
      const roomZ = ClassroomModel(
        id: 'room-z',
        name: 'Room Z',
        building: 'Main',
        capacity: 30,
      );
      const roomA = ClassroomModel(
        id: 'room-a',
        name: 'Room A',
        building: 'Main',
        capacity: 25,
      );
      final lookup = ClassesLookup(
        classes: const [alphaClass, betaClass],
        sections: const [sectionZ, sectionA],
        subjects: const [],
        classrooms: const [roomZ, roomA],
        teachers: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
            classesControllerProvider.overrideWith(
              () => _FakeClassesCtrl([alphaClass, betaClass]),
            ),
            classesLookupProvider.overrideWithValue(lookup),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AdminClassesListScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      for (var columnIndex = 0; columnIndex < 7; columnIndex++) {
        final ascendingArrow = find.byKey(
          ValueKey('academic-class-sort-$columnIndex-asc'),
        );
        await tester.ensureVisible(ascendingArrow);
        await tester.tap(ascendingArrow);
        await tester.pumpAndSettle();

        final alphaFirst = columnIndex == 2 || columnIndex == 6;
        final alphaTop = tester.getTopLeft(find.text('Z-2')).dy;
        final betaTop = tester.getTopLeft(find.text('A-1')).dy;
        expect(
          alphaFirst ? alphaTop : betaTop,
          lessThan(alphaFirst ? betaTop : alphaTop),
          reason: 'Sortable column $columnIndex should sort ascending',
        );
      }

      final descendingCodeArrow = find.byKey(
        const ValueKey('academic-class-sort-1-desc'),
      );
      await tester.ensureVisible(descendingCodeArrow);
      await tester.tap(descendingCodeArrow);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Z-2')).dy,
        lessThan(tester.getTopLeft(find.text('A-1')).dy),
        reason: 'Class Code should sort descending',
      );
    });

    testWidgets(
      'Editing a section saves the selected classroom to that section',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const classModel = ClassModel(
          id: 'cls-room-edit',
          name: 'Room Edit Class',
          code: 'CLS-RE',
          gradeLevel: 4,
          academicYear: '2026-2027',
          capacity: 20,
        );
        const section = SectionModel(
          id: 'sec-room-edit',
          classId: 'cls-room-edit',
          name: 'Section A',
          capacity: 18,
          classroomId: 'room-101',
        );
        const newRoom = ClassroomModel(
          id: 'room-202',
          name: 'Room 202',
          building: 'Main',
          capacity: 30,
        );
        final lookup = ClassesLookup(
          classes: const [classModel],
          sections: const [section],
          subjects: const [],
          classrooms: [fakeRoom1, newRoom],
          teachers: const [],
        );
        final classesController = _FakeClassesCtrl([classModel]);
        final sectionsController = _FakeSectionsCtrl([section]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
              classesControllerProvider.overrideWith(() => classesController),
              sectionsControllerProvider.overrideWith(() => sectionsController),
              classesLookupProvider.overrideWithValue(lookup),
            ],
            child: const MaterialApp(
              home: Scaffold(body: AdminClassesListScreen()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final editMenu = find.byIcon(Icons.more_vert).first;
        await tester.ensureVisible(editMenu);
        await tester.tap(editMenu);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        final roomDropdown = find.byKey(const ValueKey('class-room-dropdown'));
        await tester.tap(roomDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Room 202 · — · Capacity: 30'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(sectionsController.savedSection?.classroomId, 'room-202');
        expect(classesController.savedClass?.classroomId, isNull);
      },
    );

    testWidgets(
      'Academic Classes handles class without sections gracefully as a single row',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final classNoSection = const ClassModel(
          id: 'cls-11',
          name: 'Class 11',
          code: 'CLS-11',
          gradeLevel: 11,
          academicYear: '2026-2027',
          classroomId: 'room-101',
          capacity: 25,
          status: 'Active',
        );

        final dynamicLookup = ClassesLookup(
          classes: [classNoSection],
          sections: const [],
          subjects: const [],
          classrooms: [fakeRoom1],
          teachers: const [],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
              classesControllerProvider.overrideWith(
                () => _FakeClassesCtrl([classNoSection]),
              ),
              classesLookupProvider.overrideWithValue(dynamicLookup),
            ],
            child: const MaterialApp(
              home: Scaffold(body: AdminClassesListScreen()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final dataTable = tester.widget<DataTable>(find.byType(DataTable));
        expect(dataTable.rows.length, 1);
        expect(find.text('—'), findsOneWidget); // Section is '—'
        expect(find.text('Room 101'), findsOneWidget);
        expect(find.text('25'), findsOneWidget);
      },
    );

    testWidgets(
      'Add Section modal loads available Classes and Classroom dropdowns',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
              classesControllerProvider.overrideWith(
                () => _FakeClassesCtrl([fakeClass]),
              ),
              classesLookupProvider.overrideWithValue(fakeLookup),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) {
                      return ElevatedButton(
                        onPressed: () =>
                            openSectionModal(context, ref, fakeLookup),
                        child: const Text('Open Modal'),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Open the modal
        await tester.tap(find.text('Open Modal'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Both DropdownButtonFormField widgets for Class and Room exist
        expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String?>), findsOneWidget);

        // Class 10 is loaded in Class dropdown
        expect(find.text('Class 10 (CLS-10)'), findsOneWidget);

        // Room 101 is loaded
        expect(find.text('Room 101 · Capacity: 40'), findsOneWidget);
      },
    );

    testWidgets(
      'Add Section updates the room selection when its class changes',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const secondClass = ClassModel(
          id: 'cls-11',
          name: 'Class 11',
          code: 'CLS-11',
          gradeLevel: 11,
          academicYear: '2026-2027',
          classroomId: 'room-102',
          capacity: 25,
        );
        final lookup = ClassesLookup(
          classes: [fakeClass, secondClass],
          sections: const [],
          subjects: const [],
          classrooms: [fakeRoom1, fakeRoom2],
          teachers: const [],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
              classesControllerProvider.overrideWith(
                () => _FakeClassesCtrl([fakeClass, secondClass]),
              ),
              sectionsControllerProvider.overrideWith(
                () => _FakeSectionsCtrl(const []),
              ),
              classesLookupProvider.overrideWithValue(lookup),
            ],
            child: const MaterialApp(
              home: Scaffold(body: SectionsManagementScreen()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.text('Add Section'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('section-room-dropdown-room-101')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('section-class-dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Class 11 (CLS-11)').last);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('section-room-dropdown-room-102')),
          findsOneWidget,
        );
        expect(find.text('Room 102 · Capacity: 35'), findsOneWidget);
      },
    );

    testWidgets(
      'Add Class modal provides Academic Year and optional classroom dropdowns',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
              classesControllerProvider.overrideWith(
                () => _FakeClassesCtrl([fakeClass]),
              ),
              classesLookupProvider.overrideWithValue(fakeLookup),
            ],
            child: const MaterialApp(
              home: Scaffold(body: AdminClassesListScreen()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Click Add Class
        final addBtn = find.text('Add Class');
        expect(addBtn, findsOneWidget);
        await tester.tap(addBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify Dropdown for Academic Year exists
        expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
        expect(find.text('2026-2027'), findsWidgets);
        expect(find.text('Classroom / Room Number'), findsNWidgets(2));

        final roomDropdown = find.byKey(const ValueKey('class-room-dropdown'));
        expect(roomDropdown, findsOneWidget);
        await tester.tap(roomDropdown);
        await tester.pumpAndSettle();
        expect(find.text('Room 101 · — · Capacity: 40'), findsNothing);
        expect(find.text('Room 102 · — · Capacity: 35'), findsOneWidget);
        await tester.tap(find.text('Room 102 · — · Capacity: 35'));
        await tester.pumpAndSettle();
        expect(find.text('Room 102 · — · Capacity: 35'), findsOneWidget);
      },
    );
  });
}

class _FakeClassesCtrl extends ClassesController {
  final List<ClassModel> data;
  ClassModel? savedClass;

  _FakeClassesCtrl(this.data);

  @override
  Future<List<ClassModel>> build() async => data;

  @override
  Future<void> save(ClassModel model, {bool isNew = false}) async {
    savedClass = model;
  }
}

class _FakeSectionsCtrl extends SectionsController {
  final List<SectionModel> data;
  SectionModel? savedSection;

  _FakeSectionsCtrl(this.data);

  @override
  Future<List<SectionModel>> build() async => data;

  @override
  Future<void> save(SectionModel section, {bool isNew = false}) async {
    savedSection = section;
  }
}
