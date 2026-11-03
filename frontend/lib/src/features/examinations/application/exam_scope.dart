import '../domain/exam_master_data.dart';
import '../domain/exam_paper_model.dart';
import '../domain/examination_actor.dart';

/// Role-based scoping helpers. Each role only sees what belongs to it.

/// The class-section a student / parent / class in-charge belongs to.
String? actorSectionId(ExaminationActor actor, ExamMasterData master) {
  if (actor.role == ExamRole.student || actor.role == ExamRole.parent) {
    return master.studentById(actor.studentId)?.sectionId ?? actor.sectionId;
  }
  return actor.sectionId;
}

/// True when this teacher teaches the subject of the paper or invigilates it.
bool teacherOwnsPaper(ExamPaper paper, ExaminationActor actor, ExamMasterData master) {
  final id = actor.teacherId;
  if (id == null || id.isEmpty) return false;
  return master.subjectById(paper.subjectId)?.teacherId == id || paper.invigilatorId == id;
}

List<ExamPaper> scopePapers(
  List<ExamPaper> papers,
  ExaminationActor actor,
  ExamMasterData master,
) {
  final p = actor.permissions;
  if (p.isAdminOrPrincipal) return papers;
  if (p.isTeacher) {
    return papers.where((x) => teacherOwnsPaper(x, actor, master)).toList();
  }
  final sec = actorSectionId(actor, master);
  return papers.where((x) => x.classSectionId == sec).toList();
}

/// Sections a role may work with in dropdowns.
List<ExamSectionInfo> scopeSections(
  List<ExamSectionInfo> sections,
  ExaminationActor actor,
  ExamMasterData master,
) {
  final p = actor.permissions;
  if (p.isAdminOrPrincipal || p.isTeacher) return sections;
  final sec = actorSectionId(actor, master);
  return sections.where((s) => s.id == sec).toList();
}
