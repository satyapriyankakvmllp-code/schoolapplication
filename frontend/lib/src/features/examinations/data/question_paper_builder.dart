import 'dart:math';
import '../domain/exam_planning_model.dart';

/// Pure logic for checking a question paper against its pattern and for
/// auto-picking questions. No storage access here.
class QuestionPaperBuilder {
  /// Checks the selected items against the pattern.
  static PaperPatternCheck evaluate({
    required ExamPattern pattern,
    required List<QuestionPaperItem> items,
    required Map<String, Question> questions,
  }) {
    final blockers = <String>[];
    final warnings = <String>[];
    final perSection = <String, int>{};

    for (final sec in pattern.sections) {
      final chosen = items.where((i) => i.sectionName == sec.sectionName).toList();
      perSection[sec.sectionName] = chosen.length;
      if (chosen.length != sec.noOfQuestions) {
        blockers.add(
          '${sec.sectionName}: needs ${sec.noOfQuestions} questions, ${chosen.length} selected.',
        );
      }
      for (final it in chosen) {
        final q = questions[it.questionId];
        if (q == null) {
          blockers.add('${sec.sectionName}: a selected question no longer exists.');
        } else if (q.type != sec.questionType) {
          blockers.add(
            '${sec.sectionName}: question ${it.questionNumber} is ${questionTypeLabel(q.type)}, '
            'expected ${questionTypeLabel(sec.questionType)}.',
          );
        }
      }
    }
    final known = pattern.sections.map((s) => s.sectionName).toSet();
    if (items.any((i) => !known.contains(i.sectionName))) {
      blockers.add('Some questions belong to a section that is not in the pattern.');
    }

    final total = pattern.sectionsTotal;
    if ((total - pattern.maxMarks).abs() > 0.001) {
      blockers.add(
        'Pattern totals ${_f(total)} marks but the paper is for ${_f(pattern.maxMarks)}. Fix the pattern first.',
      );
    }

    // Chapter coverage
    if (pattern.topics.isNotEmpty) {
      final marksByTopic = <String, double>{};
      var allMarks = 0.0;
      for (final it in items) {
        final q = questions[it.questionId];
        final key = q?.topicId ?? '';
        marksByTopic[key] = (marksByTopic[key] ?? 0) + it.marks;
        allMarks += it.marks;
      }
      for (final t in pattern.topics) {
        if (t.weightagePercent <= 0) continue;
        final got = marksByTopic[t.topicId] ?? 0;
        if (got <= 0) {
          blockers.add('Chapter "${t.topicTitle}" has no questions in this paper.');
        } else if (allMarks > 0) {
          final share = got / allMarks * 100;
          if ((share - t.weightagePercent).abs() > 15) {
            warnings.add(
              '"${t.topicTitle}" carries ${share.toStringAsFixed(0)}% of the marks, planned ${_f(t.weightagePercent)}%.',
            );
          }
        }
      }
    }

    final notApproved = items.where((i) => questions[i.questionId]?.isApproved == false).length;
    if (notApproved > 0) {
      warnings.add('$notApproved selected question${notApproved == 1 ? ' is' : 's are'} not approved yet.');
    }

    return PaperPatternCheck(
      blockers: blockers,
      warnings: warnings,
      selectedPerSection: perSection,
      totalMarks: total,
    );
  }

  static String _f(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  /// Fills every section up to the required number of questions, following
  /// the chapter weightage and an easy / medium / hard mix. Keeps questions
  /// that are already selected.
  static List<QuestionPaperItem> autoPick({
    required ExamPattern pattern,
    required List<Question> bank,
    required List<QuestionPaperItem> existing,
    required String questionPaperId,
    required String Function() newId,
    Random? random,
  }) {
    final rnd = random ?? Random();
    final result = <QuestionPaperItem>[...existing];
    final used = result.map((i) => i.questionId).toSet();
    const mix = ['EASY', 'MEDIUM', 'EASY', 'MEDIUM', 'HARD'];

    for (final sec in pattern.sections) {
      final have = result.where((i) => i.sectionName == sec.sectionName).length;
      var need = sec.noOfQuestions - have;
      if (need <= 0) continue;

      var pool = bank
          .where((q) => q.type == sec.questionType && !used.contains(q.id))
          .toList();
      final approved = pool.where((q) => q.isApproved).toList();
      if (approved.length >= need) pool = approved;
      pool.shuffle(rnd);

      // Quota per chapter from the weightage.
      final quotas = <String, int>{};
      if (pattern.topics.isNotEmpty) {
        var assigned = 0;
        for (final t in pattern.topics) {
          final q = (need * t.weightagePercent / 100).round();
          quotas[t.topicId] = q;
          assigned += q;
        }
        // Fix rounding drift on the heaviest chapter.
        if (assigned != need && pattern.topics.isNotEmpty) {
          final heavy = [...pattern.topics]
            ..sort((a, b) => b.weightagePercent.compareTo(a.weightagePercent));
          quotas[heavy.first.topicId] = (quotas[heavy.first.topicId] ?? 0) + (need - assigned);
          if ((quotas[heavy.first.topicId] ?? 0) < 0) quotas[heavy.first.topicId] = 0;
        }
      }

      final picked = <Question>[];
      var mixIndex = 0;
      Question? takeFrom(List<Question> list) {
        if (list.isEmpty) return null;
        final want = mix[mixIndex % mix.length];
        mixIndex++;
        final i = list.indexWhere((q) => q.difficulty == want);
        return list.removeAt(i >= 0 ? i : 0);
      }

      quotas.forEach((topicId, quota) {
        final inTopic = pool.where((q) => q.topicId == topicId).toList();
        for (var k = 0; k < quota && need - picked.length > 0; k++) {
          final q = takeFrom(inTopic);
          if (q == null) break;
          picked.add(q);
          pool.removeWhere((x) => x.id == q.id);
        }
      });
      while (picked.length < need && pool.isNotEmpty) {
        final q = takeFrom(pool);
        if (q == null) break;
        picked.add(q);
      }

      for (final q in picked) {
        used.add(q.id);
        result.add(QuestionPaperItem(
          id: newId(),
          questionPaperId: questionPaperId,
          questionId: q.id,
          sectionName: sec.sectionName,
          questionNumber: 0,
          marks: sec.marksEach,
        ));
      }
    }
    return renumber(result, pattern);
  }

  /// Orders items by pattern section and numbers them 1..N across the paper.
  static List<QuestionPaperItem> renumber(List<QuestionPaperItem> items, ExamPattern pattern) {
    final out = <QuestionPaperItem>[];
    var n = 1;
    for (final sec in pattern.sections) {
      for (final it in items.where((i) => i.sectionName == sec.sectionName)) {
        out.add(QuestionPaperItem(
          id: it.id,
          questionPaperId: it.questionPaperId,
          questionId: it.questionId,
          sectionName: it.sectionName,
          questionNumber: n++,
          marks: it.marks,
        ));
      }
    }
    return out;
  }
}
