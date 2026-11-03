import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/src/features/admissions/application/admissions_controller.dart';
import 'package:frontend/src/features/admissions/data/admissions_repository.dart';
import 'package:frontend/src/features/admissions/domain/student_profile_model.dart';
import 'package:frontend/src/features/authentication/application/auth_controller.dart';
import 'package:frontend/src/features/authentication/domain/user_model.dart';
import 'package:frontend/src/features/classes/application/classes_access.dart';
import 'package:frontend/src/features/classes/data/classes_repository.dart';
import 'package:frontend/src/features/classes/domain/classes_actor.dart';
import 'package:frontend/src/features/classes/domain/class_model.dart';
import 'package:frontend/src/features/classes/domain/daily_lesson_model.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase B: Student-Class-Section Relationship Verification', () {
    test(
      'Authoritative admissions contain Aarav Sharma and Ananya Iyer in Class 10 sections',
      () async {
        final repo = MockAdmissionsRepository();
        final admissions = await repo.getAdmissions();

        final aarav = admissions.firstWhere((a) => a.student.id == 'std-1001');
        expect(aarav.user.fullName, 'Aarav Sharma');
        expect(aarav.student.currentClassId, 'cls-10');
        expect(aarav.student.sectionId, 'sec-10a');
        expect(aarav.student.className, 'Class 10');

        final ananya = admissions.firstWhere((a) => a.student.id == 'std-1002');
        expect(ananya.user.fullName, 'Ananya Iyer');
        expect(ananya.student.currentClassId, 'cls-10');
        expect(ananya.student.sectionId, 'sec-10b');
        expect(ananya.student.className, 'Class 10');
      },
    );

    test(
      'Legacy class-section IDs (cls-10a, cls-10b) are migrated safely without data loss',
      () {
        final legacyAarav = StudentProfileModel.fromJson({
          'id': 'std-legacy-1',
          'user_id': 'usr-legacy-1',
          'admission_number': 'ADM-2026-999',
          'class_name': 'Class 10-A',
          'section': 'A',
          'current_class_id': 'cls-10a',
          'admission_date': '2026-06-01T00:00:00.000',
          'academic_year': '2026-2027',
          'current_address': 'Address 1',
          'residential_address': 'Address 1',
        });

        expect(legacyAarav.currentClassId, 'cls-10');
        expect(legacyAarav.sectionId, 'sec-10a');

        final legacyAnanya = StudentProfileModel.fromJson({
          'id': 'std-legacy-2',
          'user_id': 'usr-legacy-2',
          'admission_number': 'ADM-2026-998',
          'class_name': 'Class 10-B',
          'section': 'B',
          'current_class_id': 'cls-10b',
          'admission_date': '2026-06-01T00:00:00.000',
          'academic_year': '2026-2027',
          'current_address': 'Address 2',
          'residential_address': 'Address 2',
        });

        expect(legacyAnanya.currentClassId, 'cls-10');
        expect(legacyAnanya.sectionId, 'sec-10b');
      },
    );

    test(
      'Class and section relationships match classes.json persistent data',
      () async {
        final classesRepo = MockClassesRepository();
        const adminActor = ClassesActor(
          role: UserRole.admin,
          userId: 'USR-ADMIN-01',
        );

        final classes = await classesRepo.getClasses(adminActor);
        final sections = await classesRepo.getSections(adminActor);

        // Class 10 exists
        final class10 = classes.firstWhere((c) => c.id == 'cls-10');
        expect(class10.name, '10th Class');

        // Sections for Class 10 exist
        final class10Sections = sections
            .where((s) => s.classId == 'cls-10')
            .toList();
        expect(
          class10Sections.any((s) => s.id == 'sec-10a' && s.name == 'A'),
          isTrue,
        );
        expect(
          class10Sections.any((s) => s.id == 'sec-10b' && s.name == 'B'),
          isTrue,
        );
      },
    );

    test(
      'Updating student profile preserves student ID without duplicating record',
      () async {
        final repo = MockAdmissionsRepository();
        final initialList = await repo.getAdmissions();
        final originalAarav = initialList.firstWhere(
          (a) => a.student.id == 'std-1001',
        );

        final updatedAarav = originalAarav.copyWith(
          student: originalAarav.student.copyWith(rollNumber: '10A-99'),
        );

        await repo.saveAdmission(updatedAarav);
        final refreshedList = await repo.getAdmissions();

        expect(refreshedList.length, initialList.length);
        final refreshedAarav = refreshedList.firstWhere(
          (a) => a.student.id == 'std-1001',
        );
        expect(refreshedAarav.student.rollNumber, '10A-99');
        expect(refreshedAarav.student.currentClassId, 'cls-10');
        expect(refreshedAarav.student.sectionId, 'sec-10a');
      },
    );

    test(
      'Teacher cannot write lesson for unassigned subject or delete classes',
      () async {
        final classesRepo = MockClassesRepository();
        const teacherActor = ClassesActor(
          role: UserRole.teacher,
          userId: 'tch-102',
        );

        // Attempt to delete class
        expect(
          () async => await classesRepo.deleteClass(teacherActor, 'cls-10'),
          throwsA(isA<ClassesPermissionException>()),
        );

        // Attempt to write lesson for subject assigned to another teacher (sub-103 is PHY assigned to tch-104)
        expect(
          () async => await classesRepo.saveLesson(
            teacherActor,
            DailyLessonModel(
              id: '',
              classId: 'cls-10',
              sectionId: 'sec-10a',
              subjectId: 'sub-103',
              teacherId: 'tch-102',
              date: DateTime.now(),
              title: 'Unassigned subject lesson',
            ),
            isNew: true,
          ),
          throwsA(isA<ClassesPermissionException>()),
        );
      },
    );

    test(
      'Student role cannot mutate class or curriculum data and only views enrolled class',
      () async {
        final classesRepo = MockClassesRepository();
        const studentActor = ClassesActor(
          role: UserRole.student,
          userId: 'std-1001',
          studentId: 'std-1001',
          studentUserId: 'std-1001',
          studentClassId: 'cls-10',
          studentSectionId: 'sec-10a',
          studentClassName: '10th Class',
          studentSection: 'A',
        );

        final visibleClasses = await classesRepo.getClasses(studentActor);
        for (final c in visibleClasses) {
          expect(c.name, '10th Class');
        }

        expect(
          () async => await classesRepo.saveClass(
            studentActor,
            const ClassModel(
              id: '',
              name: 'Illegal Class',
              gradeLevel: 5,
              academicYear: '2026-2027',
            ),
            isNew: true,
          ),
          throwsA(isA<ClassesPermissionException>()),
        );
      },
    );

    test(
      'Student scope includes only the enrolled section and never falls back',
      () async {
        final repo = MockClassesRepository();
        const student = ClassesActor(
          role: UserRole.student,
          userId: 'usr-1001',
          studentId: 'std-1001',
          studentUserId: 'usr-1001',
          studentClassId: 'cls-10',
          studentSectionId: 'sec-10a',
        );

        expect((await repo.getClasses(student)).map((c) => c.id), ['cls-10']);
        expect((await repo.getSections(student)).map((section) => section.id), [
          'sec-10a',
        ]);
        expect(
          (await repo.getTimetable(
            student,
          )).every((entry) => entry.sectionId == 'sec-10a'),
          isTrue,
        );
        expect(
          (await repo.getTeacherAssignments(
            student,
          )).every((assignment) => assignment.sectionId == 'sec-10a'),
          isTrue,
        );
        expect(
          (await repo.getTeacherWork(student)).every(
            (work) =>
                work.classId == 'cls-10' &&
                (work.sectionId == null ||
                    work.sectionId!.isEmpty ||
                    work.sectionId == 'sec-10a'),
          ),
          isTrue,
        );

        const unlinkedStudent = ClassesActor(
          role: UserRole.student,
          userId: 'usr-unlinked-student',
        );
        expect(await repo.getClasses(unlinkedStudent), isEmpty);
        expect(await repo.getSections(unlinkedStudent), isEmpty);
        expect(await repo.getSubjects(unlinkedStudent), isEmpty);
        expect(await repo.getTimetable(unlinkedStudent), isEmpty);
        expect(await repo.getTeacherWork(unlinkedStudent), isEmpty);

        const mismatchedStudent = ClassesActor(
          role: UserRole.student,
          userId: 'usr-impersonator',
          studentId: 'std-1001',
          studentUserId: 'usr-1001',
          studentClassId: 'cls-10',
          studentSectionId: 'sec-10a',
        );
        expect(await repo.getClasses(mismatchedStudent), isEmpty);
        expect(await repo.getTeacherWork(mismatchedStudent), isEmpty);

        const unlinkedParent = ClassesActor(
          role: UserRole.parent,
          userId: 'usr-unlinked-parent',
          studentId: 'std-1001',
          studentClassId: 'cls-10',
          studentSectionId: 'sec-10a',
        );
        expect(await repo.getClasses(unlinkedParent), isEmpty);
        expect(await repo.getTeacherWork(unlinkedParent), isEmpty);
      },
    );

    test(
      'Teacher reads only their assigned subjects and academic work',
      () async {
        final repo = MockClassesRepository();
        const teacher = ClassesActor(role: UserRole.teacher, userId: 'tch-102');
        const teacherAliases = {'tch-102', 'STF-2026-0112'};

        final assignments = await repo.getTeacherAssignments(teacher);
        final subjects = await repo.getSubjects(teacher);
        final subjectIds = subjects.map((subject) => subject.id).toSet();
        final classes = await repo.getClasses(teacher);
        final classIds = classes.map((classModel) => classModel.id).toSet();

        expect(
          assignments.every(
            (assignment) => teacherAliases.contains(assignment.teacherId),
          ),
          isTrue,
        );
        expect(
          subjects.every(
            (subject) =>
                teacherAliases.contains(subject.teacherId) ||
                assignments.any(
                  (assignment) => assignment.subjectId == subject.id,
                ),
          ),
          isTrue,
        );
        expect(
          (await repo.getTimetable(teacher)).every(
            (entry) =>
                teacherAliases.contains(entry.teacherId) &&
                classIds.contains(entry.classId),
          ),
          isTrue,
        );
        expect(
          (await repo.getCurriculum(
            teacher,
          )).every((unit) => subjectIds.contains(unit.subjectId)),
          isTrue,
        );
        expect(
          (await repo.getLessons(
            teacher,
          )).every((lesson) => subjectIds.contains(lesson.subjectId)),
          isTrue,
        );
        expect(
          (await repo.getTeacherWork(teacher)).every(
            (work) =>
                teacherAliases.contains(work.teacherId) &&
                subjectIds.contains(work.subjectId),
          ),
          isTrue,
        );
      },
    );

    test(
      'Parent actor resolves only a child explicitly linked to their user ID',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(activeUserRoleProvider.notifier).state = UserRole.parent;
        container.read(parentActiveChildIdProvider.notifier).state = 'std-1001';
        await container.read(admissionsListProvider.future);

        final linkedActor = container.read(classesActorProvider);
        expect(linkedActor.userId, 'usr-2001');
        expect(linkedActor.studentId, 'std-1001');
        expect(linkedActor.linkedParentUserId, 'usr-2001');

        container.read(parentActiveChildIdProvider.notifier).state = 'std-1002';
        final unlinkedActor = container.read(classesActorProvider);
        expect(unlinkedActor.studentId, isNull);
        expect(
          await container
              .read(classesRepositoryProvider)
              .getClasses(unlinkedActor),
          isEmpty,
        );
      },
    );
  });
}
