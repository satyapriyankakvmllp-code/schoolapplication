import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/src/features/authentication/domain/user_model.dart';
import 'package:frontend/src/features/classes/domain/class_model.dart';
import 'package:frontend/src/features/classes/domain/classes_actor.dart';
import 'package:frontend/src/features/classes/domain/section_model.dart';
import 'package:frontend/src/features/classes/domain/subject_model.dart';
import 'package:frontend/src/features/classes/domain/timetable_entry_model.dart';
import 'package:frontend/src/features/classes/data/classes_repository.dart';
import 'package:frontend/src/features/classes/data/classes_local_datasource.dart';
import 'package:frontend/src/features/admissions/data/admissions_repository.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Academic Workflow Implementation & Validation (Steps 1 to 7)', () {
    const adminActor = ClassesActor(
      role: UserRole.admin,
      userId: 'USR-ADMIN-01',
    );

    test(
      'Step 1: Classes - Create Class 1 and Class 2, edit, deactivate, and view',
      () async {
        final ds = ClassesLocalDataSource();

        // Create Class 1
        final class1 = await ds.saveClass(
          adminActor,
          const ClassModel(
            id: '',
            name: 'Class 1',
            code: 'CLS-01',
            academicYear: '2026-27',
            status: 'Active',
            gradeLevel: 1,
          ),
          isNew: true,
        );
        expect(class1.id.isNotEmpty, isTrue);
        expect(class1.name, 'Class 1');
        expect(class1.code, 'CLS-01');
        expect(class1.academicYear, '2026-27');
        expect(class1.status, 'Active');

        // Create Class 2
        final class2 = await ds.saveClass(
          adminActor,
          const ClassModel(
            id: '',
            name: 'Class 2',
            code: 'CLS-02',
            academicYear: '2026-27',
            status: 'Active',
            gradeLevel: 2,
          ),
          isNew: true,
        );
        expect(class2.id.isNotEmpty, isTrue);
        expect(class2.name, 'Class 2');

        // Both appear in classes list
        final classes = await ds.getClasses(adminActor);
        expect(classes.any((c) => c.name == 'Class 1'), isTrue);
        expect(classes.any((c) => c.name == 'Class 2'), isTrue);

        // Edit Class 1
        final editedClass1 = await ds.saveClass(
          adminActor,
          class1.copyWith(academicYear: '2027-28'),
        );
        expect(editedClass1.academicYear, '2027-28');

        // Deactivate Class 2
        final deactivatedClass2 = await ds.saveClass(
          adminActor,
          class2.copyWith(status: 'Inactive'),
        );
        expect(deactivatedClass2.isActive, isFalse);
        expect(deactivatedClass2.status, 'Inactive');

        // Duplicate prevention test
        expect(
          () async => await ds.saveClass(
            adminActor,
            const ClassModel(
              id: '',
              name: 'Class 1',
              gradeLevel: 1,
              academicYear: '2026-27',
            ),
            isNew: true,
          ),
          throwsA(isA<ClassesDataException>()),
        );
      },
    );

    test(
      'Step 2: Sections - Create sections under each class and filter by class',
      () async {
        final ds = ClassesLocalDataSource();

        // Create Class 1 and Class 2
        final c1 = await ds.saveClass(
          adminActor,
          const ClassModel(
            id: '',
            name: 'Test Class 1',
            gradeLevel: 1,
            academicYear: '2026-27',
          ),
          isNew: true,
        );
        final c2 = await ds.saveClass(
          adminActor,
          const ClassModel(
            id: '',
            name: 'Test Class 2',
            gradeLevel: 2,
            academicYear: '2026-27',
          ),
          isNew: true,
        );

        // Create Section A and Section B under Class 1
        final sec1A = await ds.saveSection(
          adminActor,
          SectionModel(
            id: '',
            classId: c1.id,
            name: 'A',
            capacity: 30,
            classroomId: 'room-101',
            classTeacherId: 'tch-101',
            status: 'Active',
          ),
          isNew: true,
        );

        final sec1B = await ds.saveSection(
          adminActor,
          SectionModel(
            id: '',
            classId: c1.id,
            name: 'B',
            capacity: 35,
            classroomId: 'room-102',
            classTeacherId: 'tch-102',
            status: 'Active',
          ),
          isNew: true,
        );
        expect(sec1A.id.isNotEmpty, isTrue);
        expect(sec1B.id.isNotEmpty, isTrue);

        // Create Section A under Class 2
        final sec2A = await ds.saveSection(
          adminActor,
          SectionModel(
            id: '',
            classId: c2.id,
            name: 'A',
            capacity: 28,
            classroomId: 'room-201',
            classTeacherId: 'tch-103',
            status: 'Active',
          ),
          isNew: true,
        );

        // Filter sections: When you select Class 1, only its sections (A and B) should be shown
        final allSections = await ds.getSections(adminActor);
        final c1Sections = allSections
            .where((s) => s.classId == c1.id)
            .toList();
        final c2Sections = allSections
            .where((s) => s.classId == c2.id)
            .toList();

        expect(c1Sections.length, 2);
        expect(c1Sections.map((s) => s.name).toSet(), {'A', 'B'});
        expect(c1Sections.any((s) => s.id == sec2A.id), isFalse);

        expect(c2Sections.length, 1);
        expect(c2Sections.first.name, 'A');
        expect(c2Sections.first.id, sec2A.id);

        // Duplicate section prevention in same class
        expect(
          () async => await ds.saveSection(
            adminActor,
            SectionModel(id: '', classId: c1.id, name: 'A', capacity: 30),
            isNew: true,
          ),
          throwsA(isA<ClassesDataException>()),
        );
      },
    );

    test(
      'Step 3: Subjects - Add subjects (Theory/Practical, Syllabus, Teacher) and assign to classes',
      () async {
        final ds = ClassesLocalDataSource();

        final c1 = await ds.saveClass(
          adminActor,
          const ClassModel(
            id: '',
            name: 'Academic Class 1',
            gradeLevel: 1,
            academicYear: '2026-27',
          ),
          isNew: true,
        );

        // Class 1 -> English, Maths, Science
        final subEnglish = await ds.saveSubject(
          adminActor,
          SubjectModel(
            id: '',
            classId: c1.id,
            name: 'English',
            code: 'ENG-101',
            type: 'Theory',
            syllabus: 'Grammar, Phonics, Reading Comprehension',
            teacherId: 'tch-101',
          ),
          isNew: true,
        );
        expect(subEnglish.id.isNotEmpty, isTrue);

        final subMaths = await ds.saveSubject(
          adminActor,
          SubjectModel(
            id: '',
            classId: c1.id,
            name: 'Maths',
            code: 'MTH-101',
            type: 'Theory',
            syllabus: 'Counting, Addition, Subtraction, Shapes',
            teacherId: 'tch-102',
          ),
          isNew: true,
        );
        expect(subMaths.id.isNotEmpty, isTrue);

        final subScience = await ds.saveSubject(
          adminActor,
          SubjectModel(
            id: '',
            classId: c1.id,
            name: 'Science',
            code: 'SCI-101',
            type: 'Practical',
            syllabus: 'Plants, Animals, Weather observation',
            teacherId: 'tch-103',
          ),
          isNew: true,
        );
        expect(subScience.id.isNotEmpty, isTrue);

        final subjects = await ds.getSubjects(adminActor);
        final c1Subjects = subjects.where((s) => s.classId == c1.id).toList();

        expect(c1Subjects.length, 3);
        expect(
          c1Subjects.any((s) => s.name == 'English' && s.type == 'Theory'),
          isTrue,
        );
        expect(
          c1Subjects.any((s) => s.name == 'Maths' && s.code == 'MTH-101'),
          isTrue,
        );
        expect(
          c1Subjects.any((s) => s.name == 'Science' && s.isPractical),
          isTrue,
        );
      },
    );

    test(
      'Step 4: Timetable - Conflict prevention (Same teacher cannot teach two classes simultaneously)',
      () async {
        final ds = ClassesLocalDataSource();

        final c1 = await ds.saveClass(
          adminActor,
          const ClassModel(
            id: '',
            name: 'TT Class 1',
            gradeLevel: 1,
            academicYear: '2026-27',
          ),
          isNew: true,
        );
        final c2 = await ds.saveClass(
          adminActor,
          const ClassModel(
            id: '',
            name: 'TT Class 2',
            gradeLevel: 2,
            academicYear: '2026-27',
          ),
          isNew: true,
        );

        final sec1A = await ds.saveSection(
          adminActor,
          SectionModel(id: '', classId: c1.id, name: 'A', capacity: 30),
          isNew: true,
        );
        final sec2A = await ds.saveSection(
          adminActor,
          SectionModel(id: '', classId: c2.id, name: 'A', capacity: 30),
          isNew: true,
        );

        final sub1 = await ds.saveSubject(
          adminActor,
          SubjectModel(
            id: '',
            classId: c1.id,
            name: 'Maths 1',
            code: 'M-1',
            teacherId: 'tch-101',
          ),
          isNew: true,
        );
        final sub2 = await ds.saveSubject(
          adminActor,
          SubjectModel(
            id: '',
            classId: c2.id,
            name: 'Maths 2',
            code: 'M-2',
            teacherId: 'tch-101',
          ),
          isNew: true,
        );

        // Period 1: Class 1A -> Monday 08:00 - 08:45 -> Teacher tch-101
        final period1 = await ds.saveTimetableEntry(
          adminActor,
          TimetableEntryModel(
            id: '',
            classId: c1.id,
            sectionId: sec1A.id,
            subjectId: sub1.id,
            teacherId: 'tch-101',
            dayOfWeek: 1, // Monday
            startTime: '08:00',
            endTime: '08:45',
          ),
          isNew: true,
        );
        expect(period1.id.isNotEmpty, isTrue);

        // Conflict test: Attempt to assign the SAME teacher (tch-101) to Class 2A at overlapping Monday 08:15 - 09:00
        expect(
          () async => await ds.saveTimetableEntry(
            adminActor,
            TimetableEntryModel(
              id: '',
              classId: c2.id,
              sectionId: sec2A.id,
              subjectId: sub2.id,
              teacherId: 'tch-101', // Conflict!
              dayOfWeek: 1,
              startTime: '08:15',
              endTime: '09:00',
            ),
            isNew: true,
          ),
          throwsA(
            isA<ClassesDataException>().having(
              (e) => e.message,
              'message',
              contains('That teacher is already teaching in that time slot'),
            ),
          ),
        );
      },
    );

    test(
      'Step 6 & 7: Connect Admission students to Classes and Dynamic JSON Linking',
      () async {
        final admRepo = MockAdmissionsRepository();
        final classesRepo = MockClassesRepository();

        // 1. Admin gets current admissions and assigns a student to a class and section
        final admissions = await admRepo.getAdmissions();
        expect(admissions.isNotEmpty, isTrue);

        final initialStudent = admissions.first;
        final assignedStudent = initialStudent.copyWith(
          student: initialStudent.student.copyWith(
            currentClassId: 'cls-1',
            sectionId: 'sec-1a',
            className: 'Class 1',
            section: 'A',
          ),
        );

        // 2. Admin saves assigned student
        await admRepo.saveAdmission(assignedStudent);

        // 3. The student appears in that class's student list without duplicating records
        final refreshedAdmissions = await admRepo.getAdmissions();
        expect(refreshedAdmissions.length, admissions.length); // No duplicates!

        final studentsInClass1 = refreshedAdmissions.where((a) {
          return a.student.currentClassId == 'cls-1' &&
              (a.student.sectionId == 'sec-1a' || a.student.section == 'A');
        }).toList();

        expect(
          studentsInClass1.any(
            (a) => a.student.id == initialStudent.student.id,
          ),
          isTrue,
        );

        // 4. Verify the student record is reused directly
        final retrievedStudent = refreshedAdmissions.firstWhere(
          (a) => a.student.id == initialStudent.student.id,
        );
        expect(retrievedStudent.user.id, initialStudent.user.id);
        expect(retrievedStudent.student.currentClassId, 'cls-1');

        // 5. Verify JSON dynamic export contains structured relationships
        final exportedJson = classesRepo.exportJsonString();
        expect(exportedJson.contains('"classes":'), isTrue);
        expect(exportedJson.contains('"sections":'), isTrue);
        expect(exportedJson.contains('"subjects":'), isTrue);
        expect(exportedJson.contains('"timetable":'), isTrue);
      },
    );
  });
}
