import 'package:uuid/uuid.dart';

class StaffLeaveModel {
  final String id;
  final String staffId;
  final String staffName;
  final String leaveType; // 'Medical Leave', 'Casual Leave', 'Special Duty Leave', 'Maternity Leave', etc.
  final String dateRange; // e.g. '19 Oct 2026 - 20 Oct 2026'
  final DateTime fromDate;
  final DateTime toDate;
  final int durationDays;
  final String applyDate; // e.g. '15 Oct 2026'
  final String status; // 'Pending', 'Approved', 'Rejected'
  final String reason;
  final String? adminRemarks;
  final String? substituteTeacher;
  final bool isHalfDay;
  final String? halfDaySession; // 'First Half (FN)', 'Second Half (AN)'
  final String? attachmentName;

  const StaffLeaveModel({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.leaveType,
    required this.dateRange,
    required this.fromDate,
    required this.toDate,
    required this.durationDays,
    required this.applyDate,
    required this.status,
    required this.reason,
    this.adminRemarks,
    this.substituteTeacher,
    this.isHalfDay = false,
    this.halfDaySession,
    this.attachmentName,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  StaffLeaveModel copyWith({
    String? id,
    String? staffId,
    String? staffName,
    String? leaveType,
    String? dateRange,
    DateTime? fromDate,
    DateTime? toDate,
    int? durationDays,
    String? applyDate,
    String? status,
    String? reason,
    String? adminRemarks,
    String? substituteTeacher,
    bool? isHalfDay,
    String? halfDaySession,
    String? attachmentName,
  }) {
    return StaffLeaveModel(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      leaveType: leaveType ?? this.leaveType,
      dateRange: dateRange ?? this.dateRange,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      durationDays: durationDays ?? this.durationDays,
      applyDate: applyDate ?? this.applyDate,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      adminRemarks: adminRemarks ?? this.adminRemarks,
      substituteTeacher: substituteTeacher ?? this.substituteTeacher,
      isHalfDay: isHalfDay ?? this.isHalfDay,
      halfDaySession: halfDaySession ?? this.halfDaySession,
      attachmentName: attachmentName ?? this.attachmentName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'staff_id': staffId,
      'staff_name': staffName,
      'leave_type': leaveType,
      'date_range': dateRange,
      'from_date': fromDate.toIso8601String(),
      'to_date': toDate.toIso8601String(),
      'duration_days': durationDays,
      'apply_date': applyDate,
      'status': status,
      'reason': reason,
      'admin_remarks': adminRemarks,
      'substitute_teacher': substituteTeacher,
      'is_half_day': isHalfDay,
      'half_day_session': halfDaySession,
      'attachment_name': attachmentName,
    };
  }

  factory StaffLeaveModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    DateTime parsedFrom = now;
    DateTime parsedTo = now;

    if (map['from_date'] != null) {
      parsedFrom = DateTime.tryParse(map['from_date'].toString()) ?? now;
    }
    if (map['to_date'] != null) {
      parsedTo = DateTime.tryParse(map['to_date'].toString()) ?? now;
    }

    final duration = (map['duration_days'] as num?)?.toInt() ??
        (parsedTo.difference(parsedFrom).inDays + 1).clamp(1, 90);

    return StaffLeaveModel(
      id: (map['id'] ?? const Uuid().v4()).toString(),
      staffId: (map['staff_id'] ?? map['staffId'] ?? '').toString(),
      staffName: (map['staff_name'] ?? map['staffName'] ?? 'Faculty Member').toString(),
      leaveType: (map['leave_type'] ?? map['leaveType'] ?? 'Casual Leave').toString(),
      dateRange: (map['date_range'] ?? map['dateRange'] ?? '').toString(),
      fromDate: parsedFrom,
      toDate: parsedTo,
      durationDays: duration,
      applyDate: (map['apply_date'] ?? map['applyDate'] ?? 'Today').toString(),
      status: (map['status'] ?? 'Pending').toString(),
      reason: (map['reason'] ?? '').toString(),
      adminRemarks: map['admin_remarks']?.toString() ?? map['adminRemarks']?.toString(),
      substituteTeacher: map['substitute_teacher']?.toString() ?? map['substituteTeacher']?.toString(),
      isHalfDay: map['is_half_day'] == true || map['isHalfDay'] == true,
      halfDaySession: map['half_day_session']?.toString() ?? map['halfDaySession']?.toString(),
      attachmentName: map['attachment_name']?.toString() ?? map['attachmentName']?.toString(),
    );
  }
}
