import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../application/exam_flow_controller.dart';
import '../../application/exam_paper_controller.dart';
import '../../application/examination_access.dart';
import '../../data/exam_flow_repository.dart';
import '../../domain/exam_flow_models.dart';
import '../../domain/exam_timetable_model.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import 'flow_ui.dart';

/// Screen 3: Hall Tickets (Admit Cards)
/// Flow: Exam -> Class -> Section -> Students loaded automatically.
/// Supports both batch generation and manual issue/edit of seat numbers & hall ticket numbers.
class HallTicketsTab extends ConsumerStatefulWidget {
  final ExamSchedule exam;
  const HallTicketsTab({super.key, required this.exam});

  @override
  ConsumerState<HallTicketsTab> createState() => _HallTicketsTabState();
}

class _HallTicketsTabState extends ConsumerState<HallTicketsTab> {
  String? _selectedClassId;
  String? _selectedSectionId;
  final Set<String> _selectedStudentIds = {};
  bool _generating = false;

  void _openManualTicketDialog({
    StudentRef? student,
    HallTicket? existingTicket,
    required ExamReferenceData refData,
  }) {
    showDialog(
      context: context,
      builder: (_) => IssueManualHallTicketDialog(
        exam: widget.exam,
        preselectedStudent: student,
        existingTicket: existingTicket,
        refData: refData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(examinationPermissionsProvider);
    final ticketsAsync = ref.watch(hallTicketsProvider(widget.exam.examScheduleId));
    final studentsAsync = ref.watch(studentsProvider);
    final timetableAsync = ref.watch(examTimetableProvider(widget.exam.examScheduleId));
    final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final canManage = perms.isAdminOrPrincipal && !widget.exam.isCancelled;

    if (perms.isStudentOrParent) {
      return _buildStudentView(ticketsAsync, refData, timetableAsync);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Filter Bar: Class & Section selector
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.confirmation_number_outlined, color: kExamGreen, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Hall Tickets Management',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            // Class Selector
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: refData.classes.any((c) => c.id == _selectedClassId) ? _selectedClassId : null,
                isExpanded: true,
                decoration: flowDecoration(context, 'Class'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Classes')),
                  for (final c in {for (final x in refData.classes) x.id: x}.values)
                    DropdownMenuItem(value: c.id, child: Text(c.label)),
                ],
                onChanged: (v) {
                  setState(() {
                    _selectedClassId = v;
                    _selectedSectionId = null;
                    _selectedStudentIds.clear();
                  });
                },
              ),
            ),
            // Section Selector
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                value: refData.sectionsForClass(_selectedClassId).any((s) => s.id == _selectedSectionId)
                    ? _selectedSectionId
                    : null,
                isExpanded: true,
                decoration: flowDecoration(context, 'Section'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Sections')),
                  for (final s in {for (final x in refData.sectionsForClass(_selectedClassId)) x.id: x}.values)
                    DropdownMenuItem(value: s.id, child: Text(s.label)),
                ],
                onChanged: (v) {
                  setState(() {
                    _selectedSectionId = v;
                    _selectedStudentIds.clear();
                  });
                },
              ),
            ),
            // Actions
            if (canManage) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.add_card, size: 16),
                label: const Text('Issue Manual Hall Ticket', style: TextStyle(fontSize: 12)),
                onPressed: () => _openManualTicketDialog(refData: refData),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kExamGreen),
                icon: _generating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(_selectedStudentIds.isEmpty
                    ? 'Generate All'
                    : 'Generate for Selected (${_selectedStudentIds.length})'),
                onPressed: _generating ? null : () => _handleGenerate(refData),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        ticketsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load hall tickets: $e'),
            ),
          ),
          data: (tickets) {
            return studentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading students: $e'),
              data: (allStudents) {
                // Filter students by selected Class and Section
                final availableSections = refData.sectionsForClass(_selectedClassId).map((s) => s.id).toSet();
                var students = allStudents.where((s) {
                  if (_selectedSectionId != null) {
                    return s.sectionId == _selectedSectionId;
                  }
                  if (_selectedClassId != null) {
                    return availableSections.contains(s.sectionId);
                  }
                  return true;
                }).toList();

                if (students.isEmpty) {
                  return const FlowEmpty(
                    Icons.people_outline,
                    'No students found for the selected class/section.',
                  );
                }

                final timetable = timetableAsync.valueOrNull ?? [];
                final hasAllSelected = _selectedStudentIds.length == students.length && students.isNotEmpty;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Batch Selection Header
                    if (canManage)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: hasAllSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedStudentIds.addAll(students.map((s) => s.id));
                                  } else {
                                    _selectedStudentIds.clear();
                                  }
                                });
                              },
                            ),
                            Text(
                              'Select All (${students.length} students)',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const Spacer(),
                            if (tickets.isNotEmpty)
                              OutlinedButton.icon(
                                icon: const Icon(Icons.print_outlined, size: 16),
                                label: const Text('Print / Preview All Issued', style: TextStyle(fontSize: 12)),
                                onPressed: () => _printAll(tickets, allStudents, refData, timetable),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),

                    // Students & Tickets Roster Table / Cards
                    for (final s in students)
                      Builder(builder: (context) {
                        final t = tickets.where((x) => x.studentId == s.id).firstOrNull;
                        final isSelected = _selectedStudentIds.contains(s.id);
                        final hasTicket = t != null;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? kExamGreen
                                  : (Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0)),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                if (canManage)
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedStudentIds.add(s.id);
                                        } else {
                                          _selectedStudentIds.remove(s.id);
                                        }
                                      });
                                    },
                                  ),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: hasTicket ? const Color(0xFFE6F6F2) : Colors.grey.shade200,
                                  child: Icon(
                                    hasTicket ? Icons.check_circle_outline : Icons.badge_outlined,
                                    color: hasTicket ? kExamGreen : Colors.grey.shade600,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${s.rollNumber.isNotEmpty ? "${s.rollNumber}. " : ""}${s.name}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Adm: ${s.admissionNumber}   |   ${refData.sectionName(s.sectionId)}${t?.seatNumber != null ? "   |   Seat: ${t!.seatNumber}" : ""}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white70
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasTicket) ...[
                                  FlowChip(t.number, const Color(0xFF0F766E)),
                                  const SizedBox(width: 8),
                                  statusChip(t.status),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Preview & Print',
                                    icon: const Icon(Icons.visibility_outlined, size: 20),
                                    onPressed: () => _showPreview(s, t, refData, timetable),
                                  ),
                                  if (canManage) ...[
                                    IconButton(
                                      tooltip: 'Edit Seat / Hall Ticket',
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      onPressed: () => _openManualTicketDialog(student: s, existingTicket: t, refData: refData),
                                    ),
                                    IconButton(
                                      tooltip: t.status == 'ISSUED' ? 'Revoke' : 'Re-issue',
                                      icon: Icon(
                                        t.status == 'ISSUED' ? Icons.block : Icons.restore,
                                        size: 18,
                                        color: t.status == 'ISSUED' ? Colors.red : Colors.green,
                                      ),
                                      onPressed: () async {
                                        await ref.read(examFlowActionsProvider).ticketStatus(
                                              widget.exam.examScheduleId,
                                              t.id,
                                              t.status == 'ISSUED' ? 'REVOKED' : 'ISSUED',
                                            );
                                        flowSnack(context, t.status == 'ISSUED' ? 'Ticket revoked.' : 'Ticket re-issued.');
                                      },
                                    ),
                                  ],
                                ] else ...[
                                  const FlowChip('Not Generated', Color(0xFF64748B)),
                                  if (canManage) ...[
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                      onPressed: () => _openManualTicketDialog(student: s, refData: refData),
                                      child: const Text('Issue Manually', style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 6),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                      onPressed: () => _generateSingle(s),
                                      child: const Text('Auto Generate', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStudentView(
    AsyncValue<List<HallTicket>> ticketsAsync,
    ExamReferenceData refData,
    AsyncValue<List<ExamTimetableEntry>> timetableAsync,
  ) {
    return ticketsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (tickets) {
        final myTicket = tickets
            .where((t) => t.studentId == ExamFlowRepository.demoStudentId && t.status == 'ISSUED')
            .firstOrNull;

        if (myTicket == null) {
          return const FlowEmpty(
            Icons.confirmation_number_outlined,
            'Your hall ticket has not been issued yet or the exam is cancelled.',
          );
        }

        final me = StudentRef(
          id: ExamFlowRepository.demoStudentId,
          name: 'Satya (Active Student)',
          admissionNumber: 'ADM-2026-0042',
          rollNumber: '10',
          sectionId: 'cls-sec-10a',
        );

        final timetable = timetableAsync.valueOrNull ?? [];

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified, color: kExamGreen, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Official Digital Admit Card / Hall Ticket',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: kExamGreen),
                          icon: const Icon(Icons.print, size: 16),
                          label: const Text('Print Ticket'),
                          onPressed: () => _showPreview(me, myTicket, refData, timetable),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    _buildTicketCardContent(me, myTicket, refData, timetable),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleGenerate(ExamReferenceData refData) async {
    setState(() => _generating = true);
    try {
      final res = await ref.read(examFlowActionsProvider).generateTickets(
            widget.exam,
            sectionId: _selectedSectionId,
            selectedStudentIds: _selectedStudentIds.isNotEmpty ? _selectedStudentIds.toList() : null,
          );
      final created = res['created'] ?? 0;
      final skipped = res['skipped'] ?? 0;
      if (mounted) {
        if (created == 0 && skipped == 0) {
          flowSnack(context, 'All hall tickets already exist.');
        } else if (skipped > 0) {
          flowSnack(context, '$created ticket(s) generated. $skipped skipped (no timetable scheduled).');
        } else {
          flowSnack(context, '$created hall ticket(s) generated.');
        }
        setState(() => _selectedStudentIds.clear());
      }
    } catch (e) {
      if (mounted) {
        flowSnack(context, flowError(e), error: true);
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _generateSingle(StudentRef s) async {
    setState(() => _generating = true);
    try {
      final res = await ref.read(examFlowActionsProvider).generateTickets(
            widget.exam,
            selectedStudentIds: [s.id],
          );
      final created = res['created'] ?? 0;
      if (mounted) {
        if (created > 0) {
          flowSnack(context, 'Hall ticket generated for ${s.name}.');
        } else {
          flowSnack(context, 'Skipped: ${s.name} has no timetable entries scheduled.');
        }
      }
    } catch (e) {
      if (mounted) flowSnack(context, flowError(e), error: true);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _showPreview(
    StudentRef s,
    HallTicket t,
    ExamReferenceData refData,
    List<ExamTimetableEntry> timetable,
  ) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTicketCardContent(s, t, refData, timetable),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: kExamGreen),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download / Print'),
                        onPressed: () {
                          flowSnack(context, 'Hall ticket downloaded for ${s.name}.');
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _printAll(
    List<HallTicket> tickets,
    List<StudentRef> allStudents,
    ExamReferenceData refData,
    List<ExamTimetableEntry> timetable,
  ) {
    flowSnack(context, 'Sent ${tickets.length} hall ticket(s) to printable queue.');
  }

  Widget _buildTicketCardContent(
    StudentRef s,
    HallTicket t,
    ExamReferenceData refData,
    List<ExamTimetableEntry> timetable,
  ) {
    final myPapers = timetable.where((p) => p.classSectionId == s.sectionId).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: School Name & Badge
          Center(
            child: Column(
              children: [
                const Text(
                  'EDUPULSE PUBLIC SCHOOL & SENIOR COLLEGE',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Affiliation: CBSE-AFF-2026-9021 | Bengaluru, Karnataka',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  'HALL TICKET / ADMIT CARD — ACADEMIC YEAR ${widget.exam.academicYear}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
                ),
                Text(
                  widget.exam.examName.toUpperCase(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 20),

          // Student Details & Photo Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Student Name', s.name),
                    _infoRow('Admission No.', s.admissionNumber),
                    _infoRow('Roll Number', s.rollNumber),
                    _infoRow('Class / Section', refData.sectionName(s.sectionId)),
                    _infoRow('Hall Ticket No.', t.number),
                    if (t.seatNumber != null) _infoRow('Assigned Seat', t.seatNumber!),
                    _infoRow('Issue Date', t.issueDate),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Container(
                    width: 72,
                    height: 86,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey.shade100,
                    ),
                    child: s.photoUrl != null
                        ? Image.network(s.photoUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.person, size: 40))
                        : const Icon(Icons.person, size: 40, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      t.token.substring(0, t.token.length > 8 ? 8 : t.token.length),
                      style: const TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Timetable Rows
          const Text(
            'EXAMINATION TIMETABLE',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          if (myPapers.isEmpty)
            const Text('No timetable entries allocated for this section.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic))
          else
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.15)),
                  children: const [
                    Padding(padding: EdgeInsets.all(6), child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    Padding(padding: EdgeInsets.all(6), child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    Padding(padding: EdgeInsets.all(6), child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    Padding(padding: EdgeInsets.all(6), child: Text('Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  ],
                ),
                for (final p in myPapers)
                  TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.all(6), child: Text(p.examDate ?? '—', style: const TextStyle(fontSize: 11.5))),
                      Padding(padding: const EdgeInsets.all(6), child: Text(refData.subjectName(p.subjectId), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
                      Padding(padding: const EdgeInsets.all(6), child: Text('${p.startTime} - ${p.endTime}', style: const TextStyle(fontSize: 11.5))),
                      Padding(padding: const EdgeInsets.all(6), child: Text(p.roomId == null ? '—' : refData.roomName(p.roomId), style: const TextStyle(fontSize: 11.5))),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for Admin to manually issue or customize a Hall Ticket (seat number, number, status)
class IssueManualHallTicketDialog extends ConsumerStatefulWidget {
  final ExamSchedule exam;
  final StudentRef? preselectedStudent;
  final HallTicket? existingTicket;
  final ExamReferenceData refData;

  const IssueManualHallTicketDialog({
    super.key,
    required this.exam,
    this.preselectedStudent,
    this.existingTicket,
    required this.refData,
  });

  @override
  ConsumerState<IssueManualHallTicketDialog> createState() => _IssueManualHallTicketDialogState();
}

class _IssueManualHallTicketDialogState extends ConsumerState<IssueManualHallTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _classId;
  String? _sectionId;
  String? _studentId;
  String? _roomId;
  late final TextEditingController _numberCtrl;
  late final TextEditingController _seatCtrl;
  String _status = 'ISSUED';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.preselectedStudent;
    final t = widget.existingTicket;

    _sectionId = s?.sectionId;
    _classId = widget.refData.classIdForSection(_sectionId);
    _studentId = s?.id ?? t?.studentId;

    final defaultNum = t?.number ?? 'HT-${widget.exam.startDate.replaceAll('-', '').substring(0, 4)}-${(s?.rollNumber ?? '01').padLeft(4, '0')}';
    _numberCtrl = TextEditingController(text: defaultNum);
    _seatCtrl = TextEditingController(text: t?.seatNumber ?? '');
    _status = t?.status ?? 'ISSUED';

    if (t?.seatNumber != null) {
      for (final r in widget.refData.rooms) {
        if (t!.seatNumber!.contains(r.label) || t.seatNumber!.contains(r.id)) {
          _roomId = r.id;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _seatCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_studentId == null || _studentId!.isEmpty) {
      flowSnack(context, 'Please select a student.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final roomName = _roomId != null ? widget.refData.roomName(_roomId) : '';
      String seatVal = _seatCtrl.text.trim();
      if (seatVal.isEmpty && roomName.isNotEmpty) {
        seatVal = roomName;
      }

      final ticket = HallTicket(
        id: widget.existingTicket?.id ?? 'ht-${const Uuid().v4().substring(0, 8)}',
        examScheduleId: widget.exam.examScheduleId,
        studentId: _studentId!,
        number: _numberCtrl.text.trim(),
        token: widget.existingTicket?.token ?? const Uuid().v4().substring(0, 12).toUpperCase(),
        issueDate: widget.existingTicket?.issueDate ?? DateTime.now().toIso8601String().split('T').first,
        status: _status,
        seatNumber: seatVal.isNotEmpty ? seatVal : null,
      );

      await ref.read(examFlowActionsProvider).saveTicket(ticket);
      if (mounted) {
        flowSnack(
          context,
          widget.existingTicket != null ? 'Hall ticket updated successfully.' : 'Hall ticket issued successfully.',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) flowSnack(context, flowError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);
    final availableSections = widget.refData.sectionsForClass(_classId);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.existingTicket != null ? 'Edit Hall Ticket' : 'Issue Manual Hall Ticket',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                // 1. Class
                DropdownButtonFormField<String>(
                  value: widget.refData.classes.any((c) => c.id == _classId) ? _classId : null,
                  isExpanded: true,
                  decoration: flowDecoration(context, 'Class *'),
                  items: [
                    for (final c in {for (final x in widget.refData.classes) x.id: x}.values)
                      DropdownMenuItem(value: c.id, child: Text(c.label)),
                  ],
                  onChanged: widget.preselectedStudent != null ? null : (v) {
                    setState(() {
                      _classId = v;
                      _sectionId = null;
                      _studentId = null;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // 2. Section
                DropdownButtonFormField<String>(
                  value: availableSections.any((s) => s.id == _sectionId) ? _sectionId : null,
                  isExpanded: true,
                  decoration: flowDecoration(context, 'Section *', hint: _classId == null ? 'Select Class first' : null),
                  items: [
                    for (final s in {for (final x in availableSections) x.id: x}.values)
                      DropdownMenuItem(value: s.id, child: Text(s.label)),
                  ],
                  onChanged: widget.preselectedStudent != null ? null : (v) {
                    setState(() {
                      _sectionId = v;
                      _studentId = null;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // 3. Student
                studentsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading students: $e'),
                  data: (allStudents) {
                    final sectionStudents = _sectionId != null
                        ? allStudents.where((s) => s.sectionId == _sectionId).toList()
                        : allStudents;

                    return DropdownButtonFormField<String>(
                      value: sectionStudents.any((s) => s.id == _studentId) ? _studentId : null,
                      isExpanded: true,
                      decoration: flowDecoration(context, 'Student *', hint: _sectionId == null ? 'Select Section first' : null),
                      items: [
                        for (final s in sectionStudents)
                          DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.rollNumber.isNotEmpty ? "${s.rollNumber}. " : ""}${s.name} (${s.admissionNumber})'),
                          ),
                      ],
                      validator: (v) => v == null || v.isEmpty ? 'Student is required' : null,
                      onChanged: widget.preselectedStudent != null ? null : (v) => setState(() => _studentId = v),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 4. Hall Ticket Number
                TextFormField(
                  controller: _numberCtrl,
                  decoration: flowDecoration(context, 'Hall Ticket Number *'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Hall ticket number is required' : null,
                ),
                const SizedBox(height: 12),

                // 5. Examination Room Dropdown
                DropdownButtonFormField<String>(
                  value: widget.refData.rooms.any((r) => r.id == _roomId) ? _roomId : null,
                  isExpanded: true,
                  decoration: flowDecoration(context, 'Examination Room *', hint: 'Select Room'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— Select Examination Room —')),
                    for (final r in widget.refData.rooms)
                      DropdownMenuItem(
                        value: r.id,
                        child: Text('${r.label} (${r.capacity} seats)'),
                      ),
                  ],
                  validator: (v) => v == null || v.isEmpty ? 'Examination room is required' : null,
                  onChanged: (v) {
                    setState(() {
                      _roomId = v;
                      if (v != null) {
                        final roomName = widget.refData.roomName(v);
                        if (_seatCtrl.text.isEmpty) {
                          final roll = widget.preselectedStudent?.rollNumber ?? '01';
                          _seatCtrl.text = '$roomName - Desk $roll';
                        }
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),

                // 6. Seat Number / Desk allocation
                TextFormField(
                  controller: _seatCtrl,
                  decoration: flowDecoration(
                    context,
                    'Seat / Desk Number (Optional)',
                    hint: 'e.g. Room 101 - Desk 12',
                  ),
                ),
                const SizedBox(height: 12),

                // 7. Status
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: flowDecoration(context, 'Status *'),
                  items: const [
                    DropdownMenuItem(value: 'ISSUED', child: Text('ISSUED (Active)')),
                    DropdownMenuItem(value: 'REVOKED', child: Text('REVOKED (Inactive)')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'ISSUED'),
                ),
                const SizedBox(height: 20),

                // Dialog Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: kExamGreen),
                      onPressed: _saving ? null : _handleSave,
                      child: Text(_saving ? 'Saving...' : 'Save Hall Ticket'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
