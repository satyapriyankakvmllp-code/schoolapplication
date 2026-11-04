import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/frontdesk_controller.dart';

class InterviewSchedulerScreen extends ConsumerStatefulWidget {
  final bool isDark;

  const InterviewSchedulerScreen({
    super.key,
    required this.isDark,
  });

  @override
  ConsumerState<InterviewSchedulerScreen> createState() => _InterviewSchedulerScreenState();
}

class _InterviewSchedulerScreenState extends ConsumerState<InterviewSchedulerScreen> {
  void _showBookInterviewDialog(BuildContext context) {
    final applicantCtrl = TextEditingController();
    final gradeCtrl = TextEditingController(text: 'Class 6');
    final parentCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+91 ');
    final venueCtrl = TextEditingController(text: 'Admissions Panel Room 102');
    final panelCtrl = TextEditingController(text: 'Dr. Sarah Jenkins & Anita Desai');
    final notesCtrl = TextEditingController();
    DateTime chosenDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay chosenTime = const TimeOfDay(hour: 10, minute: 30);
    InterviewSlotItem? collisionWarning;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = widget.isDark;

            void checkCollisions() {
              final targetDateTime = DateTime(
                chosenDate.year,
                chosenDate.month,
                chosenDate.day,
                chosenTime.hour,
                chosenTime.minute,
              );
              final conflict = ref.read(interviewSlotsProvider.notifier).checkConflict(
                    roomVenue: venueCtrl.text,
                    interviewerName: panelCtrl.text,
                    dateTime: targetDateTime,
                  );
              setModalState(() => collisionWarning = conflict);
            }

            return Dialog(
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 540),
                padding: const EdgeInsets.all(22),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.event_available_outlined, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Book Admission Interview Slot',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Schedule applicant interaction with admission panel & avoid clashes',
                                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Collision Warning
                      if (collisionWarning != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEF4444)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Schedule Clash: ${collisionWarning!.roomVenue} or panel is already booked for ${collisionWarning!.applicantName} around this time. Please adjust slot or room.',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Text('Applicant Student Name *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: applicantCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Samarth Kapoor',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Grade Applied *',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: gradeCtrl,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Parent Name',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: parentCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Ritu Kapoor',
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text('Contact Phone Number *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: phoneCtrl,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Date & Time Selectors
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_month, size: 14),
                              label: Text('${chosenDate.day}/${chosenDate.month}/${chosenDate.year}', style: const TextStyle(fontSize: 11)),
                              onPressed: () async {
                                final p = await showDatePicker(
                                  context: context,
                                  initialDate: chosenDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 90)),
                                );
                                if (p != null) {
                                  setModalState(() => chosenDate = p);
                                  checkCollisions();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.access_time, size: 14),
                              label: Text(chosenTime.format(context), style: const TextStyle(fontSize: 11)),
                              onPressed: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: chosenTime,
                                );
                                if (t != null) {
                                  setModalState(() => chosenTime = t);
                                  checkCollisions();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Venue / Room *',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: venueCtrl,
                                  onChanged: (_) => checkCollisions(),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Interviewing Panel *',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: panelCtrl,
                                  onChanged: (_) => checkCollisions(),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text('Interview Objective & Focus Notes',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'e.g. Science aptitude evaluation and elective choice guidance',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Confirm Schedule'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              if (applicantCtrl.text.trim().isEmpty) return;
                              final newSlot = InterviewSlotItem(
                                id: 'INT-0${DateTime.now().millisecondsSinceEpoch % 100}',
                                applicantName: applicantCtrl.text.trim(),
                                grade: gradeCtrl.text.trim(),
                                parentName: parentCtrl.text.trim().isEmpty ? 'Parent' : parentCtrl.text.trim(),
                                contactPhone: phoneCtrl.text.trim(),
                                interviewDateTime: DateTime(
                                  chosenDate.year,
                                  chosenDate.month,
                                  chosenDate.day,
                                  chosenTime.hour,
                                  chosenTime.minute,
                                ),
                                roomVenue: venueCtrl.text.trim(),
                                interviewerName: panelCtrl.text.trim(),
                                status: 'Confirmed Slot',
                                notes: notesCtrl.text.trim(),
                              );
                              ref.read(interviewSlotsProvider.notifier).addInterview(newSlot);
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Interview slot booked & confirmation sent!'),
                                  backgroundColor: Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRecordAssessmentDialog(BuildContext context, InterviewSlotItem slot) {
    int academic = slot.assessment?.academicScore ?? 4;
    int behavioral = slot.assessment?.behavioralScore ?? 4;
    int communication = slot.assessment?.communicationScore ?? 4;
    int alignment = slot.assessment?.guardianAlignmentScore ?? 4;
    String outcome = slot.assessment?.outcome ?? 'Recommended';
    final feedbackCtrl = TextEditingController(text: slot.assessment?.evaluatorFeedback ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = widget.isDark;

            Widget buildScoreSelector(String title, int currentScore, ValueChanged<int> onSelect) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: List.generate(5, (index) {
                          final score = index + 1;
                          final isSelected = score <= currentScore;
                          return InkWell(
                            onTap: () => onSelect(score),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Icon(
                                isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: isSelected ? const Color(0xFFF59E0B) : Colors.grey.shade400,
                                size: 22,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Dialog(
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 540),
                padding: const EdgeInsets.all(22),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.rate_review_outlined, color: Color(0xFF8B5CF6)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Record Interview Assessment',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Applicant: ${slot.applicantName} (${slot.grade})',
                                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Evaluation Rubric (1 - 5 Stars):',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                      ),
                      const SizedBox(height: 12),

                      buildScoreSelector('1. Academic & Conceptual Aptitude', academic, (v) => setModalState(() => academic = v)),
                      buildScoreSelector('2. Behavioral & Discipline Observation', behavioral, (v) => setModalState(() => behavioral = v)),
                      buildScoreSelector('3. Language & Articulation Skills', communication, (v) => setModalState(() => communication = v)),
                      buildScoreSelector('4. Parental Alignment with Ethos', alignment, (v) => setModalState(() => alignment = v)),

                      const Divider(height: 20),

                      Text('Recommendation Outcome *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: outcome,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: ['Recommended', 'Conditional', 'Waitlist', 'Not Recommended'].map((o) {
                          return DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 12)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => outcome = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      Text('Evaluator Remarks & Feedback *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: feedbackCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter strengths, observations, stream recommendations, and follow-up guidance',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Save Assessment Result'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              final assessment = InterviewAssessment(
                                academicScore: academic,
                                behavioralScore: behavioral,
                                communicationScore: communication,
                                guardianAlignmentScore: alignment,
                                outcome: outcome,
                                evaluatorFeedback: feedbackCtrl.text.trim().isEmpty ? 'Evaluation recorded.' : feedbackCtrl.text.trim(),
                                evaluatedAt: DateTime.now(),
                                evaluatedBy: slot.interviewerName,
                              );
                              ref.read(interviewSlotsProvider.notifier).recordAssessment(slot.id, assessment);
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Interview assessment recorded and linked to ticket!'),
                                  backgroundColor: Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final slots = ref.watch(interviewSlotsProvider);
    final isDark = widget.isDark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interview & Interaction Scheduler',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Manage upcoming admission panel appointments, conflict-free booking, and rubric scores',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: Text(isMobile ? 'Book' : 'Book Interview'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showBookInterviewDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Interview Slots List
          if (slots.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D31) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
              ),
              child: const Center(
                child: Text('No interview slots currently booked.'),
              ),
            )
          else
            ...slots.map((slot) {
              final isAssessed = slot.assessment != null;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131D31) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.calendar_today_outlined, color: Color(0xFF10B981), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    slot.applicantName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      slot.grade,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      slot.status,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Time: ${slot.interviewDateTime.day}/${slot.interviewDateTime.month}/${slot.interviewDateTime.year} at ${slot.interviewDateTime.hour}:${slot.interviewDateTime.minute.toString().padLeft(2, '0')} • Venue: ${slot.roomVenue}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                'Parent: ${slot.parentName} (${slot.contactPhone}) • Panel: ${slot.interviewerName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Assessment result badge & feedback if already evaluated
                    if (isAssessed) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_outlined, size: 16, color: Color(0xFF8B5CF6)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Outcome: ${slot.assessment!.outcome} • Avg Score: ${slot.assessment!.averageScore.toStringAsFixed(1)}/5.0 — "${slot.assessment!.evaluatorFeedback}"',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: Icon(isAssessed ? Icons.edit : Icons.rate_review, size: 14),
                          label: Text(
                            isAssessed ? 'Update Assessment' : 'Record Result',
                            style: const TextStyle(fontSize: 11),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF8B5CF6),
                            side: const BorderSide(color: Color(0xFF8B5CF6)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          onPressed: () => _showRecordAssessmentDialog(context, slot),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
