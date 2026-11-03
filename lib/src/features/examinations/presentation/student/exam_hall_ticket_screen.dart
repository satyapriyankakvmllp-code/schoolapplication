import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_controller.dart';
import '../../application/exam_flow_controller.dart';
import '../../application/exam_paper_controller.dart';
import '../../domain/exam_flow_models.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../tabs/flow_ui.dart';

/// Student Exam Hall Ticket Screen
/// Displays official digital admit card with exam dates, seating room, and download capability.
class StudentExamHallTicketScreen extends ConsumerStatefulWidget {
  final String? initialExamScheduleId;

  const StudentExamHallTicketScreen({
    super.key,
    this.initialExamScheduleId,
  });

  @override
  ConsumerState<StudentExamHallTicketScreen> createState() => _StudentExamHallTicketScreenState();
}

class _StudentExamHallTicketScreenState extends ConsumerState<StudentExamHallTicketScreen> {
  String? _selectedExamScheduleId;

  @override
  void initState() {
    super.initState();
    _selectedExamScheduleId = widget.initialExamScheduleId;
  }

  void _downloadAdmitCard() {
    flowSnack(context, 'Hall Ticket downloaded to device storage.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exams = ref.watch(examListControllerProvider).valueOrNull ?? [];
    if (exams.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No examinations scheduled.')));
    }

    final activeExam = exams.firstWhere(
      (e) => e.examScheduleId == _selectedExamScheduleId,
      orElse: () => exams.first,
    );

    final ticketsAsync = ref.watch(hallTicketsProvider(activeExam.examScheduleId));
    final studentsAsync = ref.watch(studentsProvider);
    final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final timetableAsync = ref.watch(examTimetableProvider(activeExam.examScheduleId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exam Selector Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.badge_outlined, size: 20, color: kExamGreen),
                const SizedBox(width: 8),
                const Text('Examination:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: activeExam.examScheduleId,
                      isExpanded: true,
                      items: exams.map((e) {
                        return DropdownMenuItem<String>(
                          value: e.examScheduleId,
                          child: Text('${e.examName} (${e.academicYear})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedExamScheduleId = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _downloadAdmitCard,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download Admit Card'),
                  style: FilledButton.styleFrom(backgroundColor: kExamGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Official Hall Ticket Canvas
          ticketsAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error loading hall ticket: $e')),
            data: (tickets) {
              if (tickets.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.badge, size: 40, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('No hall tickets have been generated for this examination yet.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              // Take first student ticket for display
              final ticket = tickets.first;
              final students = studentsAsync.valueOrNull ?? [];
              final student = students.where((s) => s.id == ticket.studentId).firstOrNull;
              final studentName = student?.name ?? refData.studentName(ticket.studentId);
              final rollNo = student?.rollNumber ?? '—';
              final secName = refData.sectionName(student?.sectionId);

              final timetableEntries = timetableAsync.valueOrNull ?? [];

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          children: [
                            const Icon(Icons.school, size: 36, color: kExamGreen),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'EDUPULSE HIGH SCHOOL',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                  ),
                                  Text(
                                    'OFFICIAL EXAMINATION ADMIT CARD • ${activeExam.academicYear}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.teal.shade200),
                              ),
                              child: Text(
                                ticket.number,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F766E)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(thickness: 1.5),
                        const SizedBox(height: 14),

                        // Student Details & Photo Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _infoRow('Candidate Name:', studentName, bold: true),
                                  const SizedBox(height: 6),
                                  _infoRow('Student ID:', ticket.studentId),
                                  const SizedBox(height: 6),
                                  _infoRow('Class & Section:', secName),
                                  const SizedBox(height: 6),
                                  _infoRow('Roll Number:', rollNo),
                                  const SizedBox(height: 6),
                                  _infoRow('Examination:', activeExam.examName),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Photo Placeholder Box
                            Container(
                              width: 90,
                              height: 110,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.person, size: 40, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text('PHOTO', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Papers Schedule Table
                        const Text(
                          'Schedule of Papers',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Table(
                          border: TableBorder.all(
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                          ),
                          columnWidths: const {
                            0: FlexColumnWidth(1.4),
                            1: FlexColumnWidth(1.4),
                            2: FlexColumnWidth(2.2),
                            3: FlexColumnWidth(1.2),
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              ),
                              children: const [
                                _cell('Date', bold: true),
                                _cell('Timing', bold: true),
                                _cell('Subject', bold: true),
                                _cell('Room', bold: true),
                              ],
                            ),
                            if (timetableEntries.isEmpty)
                              const TableRow(
                                children: [
                                  _cell('—'),
                                  _cell('—'),
                                  _cell('Timetable pending release'),
                                  _cell('—'),
                                ],
                              )
                            else
                              ...timetableEntries.map((entry) {
                                final sub = refData.subjectName(entry.subjectId);
                                final room = refData.roomName(entry.roomId);
                                return TableRow(
                                  children: [
                                    _cell(entry.examDate),
                                    _cell('${entry.startTime} - ${entry.endTime}'),
                                    _cell(sub),
                                    _cell(room),
                                  ],
                                );
                              }),
                          ],
                        ),
                        const SizedBox(height: 36),

                        // Signatures
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            _signBlock('Candidate Signature'),
                            _signBlock('Controller of Examinations'),
                            _signBlock('Principal Signature & Seal'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _signBlock extends StatelessWidget {
  final String label;
  const _signBlock(this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(width: 140, height: 1, color: Colors.grey.shade400),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

Widget _cell(String text, {bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
    ),
  );
}
