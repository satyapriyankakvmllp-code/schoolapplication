import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/src/features/authentication/domain/user_model.dart';
import 'package:frontend/src/features/classes/data/classes_local_datasource.dart';
import 'package:frontend/src/features/classes/domain/class_model.dart';
import 'package:frontend/src/features/classes/domain/classes_actor.dart';
import 'package:frontend/src/features/classes/domain/classroom_model.dart';
import 'package:frontend/src/features/classes/domain/section_model.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  const admin = ClassesActor(role: UserRole.admin, userId: 'USR-ADMIN-01');

  test('duplicate room numbers are rejected in any spelling', () async {
    final ds = ClassesLocalDataSource();
    for (final name in ['Room 101', 'room 101', '101']) {
      expect(
        () => ds.saveClassroom(
          admin,
          ClassroomModel(id: '', name: name, building: 'X', capacity: 30),
          isNew: true,
        ),
        throwsA(isA<ClassesDataException>()),
        reason: name,
      );
    }
    final ok = await ds.saveClassroom(
      admin,
      const ClassroomModel(
        id: '',
        name: 'Room 401',
        building: 'X',
        capacity: 30,
        roomType: 'Practical',
      ),
      isNew: true,
    );
    expect(ok.roomType, 'Practical');
    expect(ok.status, 'Unassigned');
    expect(ok.isAvailable, isTrue);
  });

  test(
    'classroom assignment status follows actual class and section usage',
    () async {
      final ds = ClassesLocalDataSource();
      final room = await ds.saveClassroom(
        admin,
        const ClassroomModel(
          id: '',
          name: 'Room 403',
          building: 'X',
          capacity: 30,
        ),
        isNew: true,
      );
      expect(room.status, 'Unassigned');
      expect(room.isAvailable, isTrue);

      final classModel = await ds.saveClass(
        admin,
        const ClassModel(
          id: '',
          name: 'Room Status Test Class',
          gradeLevel: 21,
          academicYear: '2026-2027',
        ),
        isNew: true,
      );
      final assignedClass = await ds.saveClass(
        admin,
        classModel.copyWith(classroomId: room.id),
      );
      expect(assignedClass.classroomId, room.id);
      expect(
        (await ds.getClassrooms(
          admin,
        )).firstWhere((classroom) => classroom.id == room.id).status,
        'Assigned',
      );

      await ds.saveClass(admin, assignedClass.copyWith(clearClassroom: true));
      expect(
        (await ds.getClassrooms(
          admin,
        )).firstWhere((classroom) => classroom.id == room.id).status,
        'Unassigned',
      );

      final section = await ds.saveSection(
        admin,
        SectionModel(
          id: '',
          classId: classModel.id,
          name: 'A',
          capacity: 30,
          classroomId: room.id,
        ),
        isNew: true,
      );
      expect(
        (await ds.getClassrooms(
          admin,
        )).firstWhere((classroom) => classroom.id == room.id).status,
        'Assigned',
      );

      await ds.deleteSection(admin, section.id);
      expect(
        (await ds.getClassrooms(
          admin,
        )).firstWhere((classroom) => classroom.id == room.id).status,
        'Unassigned',
      );
    },
  );

  test(
    'an unassigned room cannot be marked Assigned without class or section use',
    () async {
      final ds = ClassesLocalDataSource();
      final room = await ds.saveClassroom(
        admin,
        const ClassroomModel(
          id: '',
          name: 'Room 404',
          building: 'X',
          capacity: 30,
          status: 'Assigned',
        ),
        isNew: true,
      );

      expect(room.status, 'Unassigned');
      expect(room.isAvailable, isTrue);
    },
  );

  test('a room held by another class cannot be assigned again', () async {
    final ds = ClassesLocalDataSource();
    // room-101 belongs to 1st Class in the seed data.
    expect(
      () => ds.saveClass(
        admin,
        const ClassModel(
          id: '',
          name: 'Class Z',
          gradeLevel: 11,
          academicYear: '2026-2027',
          classroomId: 'room-101',
        ),
        isNew: true,
      ),
      throwsA(isA<ClassesDataException>()),
    );
    final fine = await ds.saveClass(
      admin,
      const ClassModel(
        id: '',
        name: 'Class Y',
        gradeLevel: 12,
        academicYear: '2026-2027',
        classroomId: 'room-lab1',
      ),
      isNew: true,
    );
    expect(fine.classroomId, 'room-lab1');
  });

  test('an Unavailable room cannot be assigned', () async {
    final ds = ClassesLocalDataSource();
    final room = await ds.saveClassroom(
      admin,
      const ClassroomModel(
        id: '',
        name: 'Room 402',
        building: 'X',
        capacity: 30,
        status: 'Unavailable',
      ),
      isNew: true,
    );
    expect(
      () => ds.saveClass(
        admin,
        ClassModel(
          id: '',
          name: 'Class W',
          gradeLevel: 13,
          academicYear: '2026-2027',
          classroomId: room.id,
        ),
        isNew: true,
      ),
      throwsA(isA<ClassesDataException>()),
    );
  });

  test(
    'editing a section can move its room without losing its class or teacher',
    () async {
      final ds = ClassesLocalDataSource();
      final classModel = await ds.saveClass(
        admin,
        const ClassModel(
          id: '',
          name: 'Section Room Test Class',
          gradeLevel: 20,
          academicYear: '2026-2027',
        ),
        isNew: true,
      );
      final firstRoom = await ds.saveClassroom(
        admin,
        const ClassroomModel(
          id: '',
          name: 'Room 501',
          building: '',
          capacity: 30,
        ),
        isNew: true,
      );
      final nextRoom = await ds.saveClassroom(
        admin,
        const ClassroomModel(
          id: '',
          name: 'Room 502',
          building: '',
          capacity: 30,
        ),
        isNew: true,
      );
      final section = await ds.saveSection(
        admin,
        SectionModel(
          id: '',
          classId: classModel.id,
          name: 'A',
          capacity: 30,
          classroomId: firstRoom.id,
          classTeacherId: 'STF-2026-0111',
        ),
        isNew: true,
      );

      final updated = await ds.saveSection(
        admin,
        section.copyWith(classroomId: nextRoom.id),
      );

      expect(updated.classId, classModel.id);
      expect(updated.classroomId, nextRoom.id);
      expect(updated.name, 'A');
      expect(updated.classTeacherId, 'STF-2026-0111');
    },
  );
}
