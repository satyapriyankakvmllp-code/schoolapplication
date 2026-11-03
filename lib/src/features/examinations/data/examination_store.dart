import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../domain/exam_records_model.dart';
import 'examination_local_datasource.dart';

/// Thin helper over the shared examination JSON document.
///
/// Every repository uses ONE [ExaminationLocalDataSource] instance (through
/// the Riverpod provider) so they always see each other's writes.
class ExaminationStore {
  final ExaminationLocalDataSource dataSource;
  final Uuid _uuid = const Uuid();

  ExaminationStore(this.dataSource);

  /// Collections kept in examination.json.
  static const List<String> collections = [
    'exam_schedules',
    'exam_papers',
    'hall_tickets',
    'exam_attendance',
    'student_exam_marks',
    'exam_student_remarks',
    'report_cards',
    'exam_syllabus_patterns',
    'pattern_sections',
    'pattern_topics',
    'question_bank',
    'question_options',
    'question_papers',
    'question_paper_items',
    'syllabus_topics',
  ];

  Future<Map<String, dynamic>> load() async {
    final raw = await dataSource.readExaminationJson();
    final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    for (final key in collections) {
      if (data[key] is! List) data[key] = <dynamic>[];
    }
    // Old placeholder papers (without a class or subject) cannot be used by
    // the timetable, so they are ignored.
    data['exam_papers'] = (data['exam_papers'] as List)
        .whereType<Map>()
        .where((p) => p['class_section_id'] != null && p['subject_id'] != null)
        .toList();
    if (data['grade_scale'] is! List || (data['grade_scale'] as List).isEmpty) {
      data['grade_scale'] = GradeBand.defaults.map((g) => g.toJson()).toList();
    }
    return data;
  }

  Future<void> save(Map<String, dynamic> data) async {
    const encoder = JsonEncoder.withIndent('  ');
    await dataSource.writeExaminationJson(encoder.convert(data));
  }

  List<Map<String, dynamic>> listOf(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is! List) return <Map<String, dynamic>>[];
    return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void setList(Map<String, dynamic> data, String key, List<Map<String, dynamic>> v) {
    data[key] = v;
  }

  String newId(String prefix) => '$prefix-${_uuid.v4().substring(0, 8)}';

  String nowIso() => DateTime.now().toUtc().toIso8601String();

  String todayStr() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
