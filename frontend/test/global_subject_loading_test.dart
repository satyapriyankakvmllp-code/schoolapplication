import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/src/features/authentication/domain/user_model.dart';
import 'package:frontend/src/features/classes/data/classes_repository.dart';
import 'package:frontend/src/features/classes/domain/classes_actor.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'existing globally allocated subjects are available for timetable classes',
    () async {
      const admin = ClassesActor(role: UserRole.admin, userId: 'USR-ADMIN-01');
      final repository = MockClassesRepository();
      final classes = await repository.getClasses(admin);
      final class10 = classes.firstWhere(
        (classModel) => classModel.gradeLevel == 10,
      );
      final subjects = await repository.getSubjects(admin);

      expect(
        subjects
            .where((subject) => subject.classId == class10.id)
            .map((subject) => subject.name),
        containsAll([
          'Mathematics',
          'Physics',
          'Chemistry',
          'Computer Science',
          'English Core',
          'Social Science',
        ]),
      );
    },
  );
}
