import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/src/features/classes/domain/class_model.dart';
import 'package:frontend/src/features/classes/domain/subject_model.dart';
import 'package:frontend/src/features/classes/presentation/widgets/classes_lookup.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  final mockTeachers = [
    const TeacherOption(
      'tch-math-1',
      'Dr. Rajeshwari Swaminathan',
      designation: 'HOD & Senior PGT Mathematics',
      department: 'Mathematics',
      specialization: 'Pure Calculus & Analytical Geometry',
      assignedSubjects: ['Mathematics', 'Advanced Mathematics'],
    ),
    const TeacherOption(
      'tch-math-2',
      'Rakesh Sharma',
      designation: 'Mathematics HOD',
      department: 'Mathematics',
      specialization: 'Algebra & Geometry',
      assignedSubjects: ['Mathematics'],
    ),
    const TeacherOption(
      'tch-phy-1',
      'Vikramaditya Sen',
      designation: 'Senior PGT Physics',
      department: 'Science',
      specialization: 'Quantum Mechanics & Optics',
      assignedSubjects: ['Physics'],
    ),
    const TeacherOption(
      'tch-phy-2',
      'Arvind Singh',
      designation: 'Physics & Science Teacher',
      department: 'Science',
      specialization: 'Physics & General Science',
      assignedSubjects: ['Physics'],
    ),
    const TeacherOption(
      'tch-chem-1',
      'Pooja Mehta',
      designation: 'Chemistry Teacher',
      department: 'Science',
      specialization: 'Organic Chemistry',
      assignedSubjects: ['Chemistry'],
    ),
    const TeacherOption(
      'tch-eng-1',
      'Ananya Deshmukh',
      designation: 'TGT English & Literature',
      department: 'English',
      specialization: 'Contemporary World Literature',
      assignedSubjects: ['English Language', 'English Literature'],
    ),
    const TeacherOption(
      'tch-eng-2',
      'Anita Roy',
      designation: 'Class In-Charge 10A',
      department: 'English',
      specialization: 'Language Arts',
      assignedSubjects: ['English'],
    ),
    const TeacherOption(
      'tch-eng-3',
      'Sanjay Verma',
      designation: 'English Literature Teacher',
      department: 'English',
      specialization: 'English Literature',
      assignedSubjects: ['English'],
    ),
    const TeacherOption(
      'tch-cs-1',
      'Pooja Mehta CS',
      designation: 'Computer Science Faculty',
      department: 'Computer Science',
      specialization: 'Python & AI',
      assignedSubjects: ['Computer Science'],
    ),
    const TeacherOption(
      'tch-soc-1',
      'Meenakshi Sundaram',
      designation: 'Social Science Faculty',
      department: 'Social Science',
      specialization: 'History & Civics',
      assignedSubjects: ['Social Science'],
    ),
    const TeacherOption(
      'tch-pe-1',
      'Captain Vijay Chauhan',
      designation: 'Physical Education Director',
      department: 'Physical Education',
      specialization: 'Sports & Athletics',
      assignedSubjects: ['Physical Education'],
    ),
  ];

  final mockClasses = [
    const ClassModel(
      id: 'cls-10',
      name: 'Class 10',
      code: 'CLS-10',
      gradeLevel: 10,
      academicYear: '2026-2027',
      status: 'Active',
    ),
    const ClassModel(
      id: 'cls-9',
      name: 'Class 9',
      code: 'CLS-9',
      gradeLevel: 9,
      academicYear: '2026-2027',
      status: 'Active',
    ),
  ];

  final mockSubjects = [
    const SubjectModel(
      id: 'sub-math-10',
      classId: 'cls-10',
      name: 'Mathematics',
      code: 'MTH-101',
      type: 'Theory',
    ),
    const SubjectModel(
      id: 'sub-phy-10',
      classId: 'cls-10',
      name: 'Physics',
      code: 'PHY-102',
      type: 'Theory',
    ),
    const SubjectModel(
      id: 'sub-chem-10',
      classId: 'cls-10',
      name: 'Chemistry',
      code: 'CHM-103',
      type: 'Theory',
    ),
    const SubjectModel(
      id: 'sub-sci-10',
      classId: 'cls-10',
      name: 'Science',
      code: 'SCI-104',
      type: 'Theory',
    ),
    const SubjectModel(
      id: 'sub-eng-10',
      classId: 'cls-10',
      name: 'English',
      code: 'ENG-105',
      type: 'Theory',
    ),
    const SubjectModel(
      id: 'sub-hin-10',
      classId: 'cls-10',
      name: 'Hindi Core',
      code: 'HIN-106',
      type: 'Theory',
    ),
    const SubjectModel(
      id: 'sub-eng-9',
      classId: 'cls-9',
      name: 'English Literature',
      code: 'ENG-901',
      type: 'Theory',
    ),
  ];

  final testLookup = ClassesLookup(
    classes: mockClasses,
    sections: const [],
    subjects: mockSubjects,
    classrooms: const [],
    teachers: mockTeachers,
  );

  group('Assignments - Subject Qualification Filter Logic', () {
    test('Maths shows only Maths teachers', () {
      final teachers = testLookup.qualifiedTeachersForSubject('Mathematics');
      expect(teachers.map((t) => t.name).toList(), containsAll(['Dr. Rajeshwari Swaminathan', 'Rakesh Sharma']));
      expect(teachers.any((t) => t.name == 'Vikramaditya Sen'), isFalse);
      expect(teachers.any((t) => t.name == 'Anita Roy'), isFalse);
      expect(teachers.any((t) => t.name == 'Pooja Mehta'), isFalse);
    });

    test('Physics shows only Physics teachers', () {
      final teachers = testLookup.qualifiedTeachersForSubject('Physics');
      expect(teachers.map((t) => t.name).toList(), containsAll(['Vikramaditya Sen', 'Arvind Singh']));
      expect(teachers.any((t) => t.name == 'Dr. Rajeshwari Swaminathan'), isFalse);
      expect(teachers.any((t) => t.name == 'Pooja Mehta'), isFalse);
      expect(teachers.any((t) => t.name == 'Anita Roy'), isFalse);
    });

    test('Chemistry shows only Chemistry teachers', () {
      final teachers = testLookup.qualifiedTeachersForSubject('Chemistry');
      expect(teachers.map((t) => t.name).toList(), containsAll(['Pooja Mehta']));
      expect(teachers.any((t) => t.name == 'Vikramaditya Sen'), isFalse);
      expect(teachers.any((t) => t.name == 'Rakesh Sharma'), isFalse);
    });

    test('Science shows only Science faculty (Physics, Chemistry, General Science)', () {
      final teachers = testLookup.qualifiedTeachersForSubject('Science');
      expect(teachers.map((t) => t.name).toList(), containsAll(['Vikramaditya Sen', 'Arvind Singh', 'Pooja Mehta']));
      expect(teachers.any((t) => t.name == 'Dr. Rajeshwari Swaminathan'), isFalse);
      expect(teachers.any((t) => t.name == 'Anita Roy'), isFalse);
    });

    test('English shows only English teachers', () {
      final teachers = testLookup.qualifiedTeachersForSubject('English');
      expect(teachers.map((t) => t.name).toList(), containsAll(['Ananya Deshmukh', 'Anita Roy', 'Sanjay Verma']));
      expect(teachers.any((t) => t.name == 'Vikramaditya Sen'), isFalse);
      expect(teachers.any((t) => t.name == 'Pooja Mehta'), isFalse);
    });

    test('Subject with no qualified teacher returns empty list', () {
      final teachers = testLookup.qualifiedTeachersForSubject('Hindi Core');
      expect(teachers, isEmpty);
    });

    test('Computer Science shows only Computer Science teachers', () {
      final teachers = testLookup.qualifiedTeachersForSubject('Computer Science');
      expect(teachers.map((t) => t.name).toList(), contains('Pooja Mehta CS'));
      expect(teachers.any((t) => t.name == 'Dr. Rajeshwari Swaminathan'), isFalse);
      expect(teachers.any((t) => t.name == 'Vikramaditya Sen'), isFalse);
    });

    test('Social Science shows only Social Science teachers', () {
      final teachers = testLookup.qualifiedTeachersForSubject('Social Science');
      expect(teachers.map((t) => t.name).toList(), contains('Meenakshi Sundaram'));
      expect(teachers.any((t) => t.name == 'Vikramaditya Sen'), isFalse);
      expect(teachers.any((t) => t.name == 'Anita Roy'), isFalse);
    });

    test('Physical Education shows only Physical Education teachers', () {
      final teachers = testLookup.qualifiedTeachersForSubject('Physical Education');
      expect(teachers.map((t) => t.name).toList(), contains('Captain Vijay Chauhan'));
      expect(teachers.any((t) => t.name == 'Dr. Rajeshwari Swaminathan'), isFalse);
    });

    test('Null or empty subject returns empty list safely', () {
      expect(testLookup.qualifiedTeachersForSubject(null), isEmpty);
      expect(testLookup.qualifiedTeachersForSubject(''), isEmpty);
    });
  });
}
