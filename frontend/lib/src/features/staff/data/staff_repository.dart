import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/asset_loader.dart';
import '../domain/class_subject_assignment.dart';
import '../domain/staff_compensation_model.dart';
import '../domain/staff_login_account_model.dart';
import '../domain/staff_member_model.dart';

abstract class StaffRepository {
  Future<List<StaffMemberModel>> getStaffList();
  Future<StaffMemberModel?> getStaffById(String id);
  Future<StaffMemberModel> saveStaff(StaffMemberModel staff);
  Future<bool> deleteOrDeactivateStaff(String id);
  Future<String> generateNextStaffId();
}

class MockStaffRepository implements StaffRepository {
  final AssetLoader _assetLoader;
  static const String _mockDataPath = 'assets/data/staff/staff.json';
  static const String _prefsKey = 'edupulse_saved_staff_records';

  List<StaffMemberModel>? _cachedStaff;
  bool _isJsonLoaded = false;

  MockStaffRepository({AssetLoader? assetLoader, bool preloadDefaultsOnly = false})
      : _assetLoader = assetLoader ?? const AssetLoader() {
    _cachedStaff = _buildDefaultStaff();
    if (preloadDefaultsOnly) {
      _isJsonLoaded = true;
    }
  }

  Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 400),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureLoaded() async {
    if (_isJsonLoaded) return;
    _isJsonLoaded = true;

    List<StaffMemberModel> baseList = [];
    try {
      final List<dynamic> raw = await _assetLoader.loadJsonList(_mockDataPath, delayMs: 0);
      baseList = raw.map((item) => StaffMemberModel.fromMap(item as Map<String, dynamic>)).toList();
    } catch (_) {
      // Fallback to in-memory Indian faculty list
      baseList = _buildDefaultStaff();
    }

    // Overlay SharedPreferences saved/updated records
    try {
      final prefs = await _getPrefs();
      final savedJson = prefs?.getString(_prefsKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> savedRaw = jsonDecode(savedJson);
        final savedList = savedRaw
            .map((item) => StaffMemberModel.fromMap(item as Map<String, dynamic>))
            .toList();

        final map = <String, StaffMemberModel>{};
        for (final s in baseList) {
          map[s.id] = s;
        }
        for (final s in savedList) {
          map[s.id] = s;
        }
        _cachedStaff = map.values.toList();
        return;
      }
    } catch (_) {}

    _cachedStaff = baseList;
  }

  Future<void> _persistCache() async {
    if (_cachedStaff == null) return;
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        final rawList = _cachedStaff!.map((s) => s.toMap()).toList();
        await prefs.setString(_prefsKey, jsonEncode(rawList));
      }
    } catch (_) {}
  }

  @override
  Future<List<StaffMemberModel>> getStaffList() async {
    await _ensureLoaded();
    return List.unmodifiable(_cachedStaff ?? _buildDefaultStaff());
  }

  @override
  Future<StaffMemberModel?> getStaffById(String id) async {
    await _ensureLoaded();
    try {
      return _cachedStaff?.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<StaffMemberModel> saveStaff(StaffMemberModel staff) async {
    await _ensureLoaded();
    _cachedStaff ??= _buildDefaultStaff();

    final index = _cachedStaff!.indexWhere((s) => s.id == staff.id);
    if (index >= 0) {
      _cachedStaff![index] = staff;
    } else {
      _cachedStaff!.insert(0, staff);
    }

    await _persistCache();
    return staff;
  }

  @override
  Future<bool> deleteOrDeactivateStaff(String id) async {
    await _ensureLoaded();
    if (_cachedStaff == null) return false;

    final index = _cachedStaff!.indexWhere((s) => s.id == id);
    if (index >= 0) {
      // Switch status to inactive rather than hard deleting to preserve institutional audit
      _cachedStaff![index] = _cachedStaff![index].copyWith(status: StaffStatus.inactive);
      await _persistCache();
      return true;
    }
    return false;
  }

  @override
  Future<String> generateNextStaffId() async {
    await _ensureLoaded();
    final list = _cachedStaff ?? _buildDefaultStaff();
    int maxSeq = 100;

    for (final member in list) {
      final parts = member.id.split('-');
      if (parts.length >= 3) {
        final seq = int.tryParse(parts[2]);
        if (seq != null && seq > maxSeq) {
          maxSeq = seq;
        }
      }
    }

    final nextSeq = (maxSeq + 1).toString().padLeft(4, '0');
    return 'STF-2026-$nextSeq';
  }

  List<StaffMemberModel> _buildDefaultStaff() {
    return [
      StaffMemberModel(
        id: 'STF-2026-0101',
        fullName: 'Dr. Rajeshwari Swaminathan',
        category: StaffCategory.teaching,
        designation: 'HOD & Senior PGT Mathematics',
        department: 'Mathematics',
        qualification: 'Ph.D. in Applied Mathematics, M.Sc., B.Ed.',
        specialization: 'Pure Calculus, Advanced Trigonometry & Analytical Geometry',
        phone: '+91 98450 12345',
        email: 'rajeshwari.swaminathan@edupulse.edu.in',
        currentAddress: 'Flat 402, Kaveri Heights, Indiranagar, Bengaluru, KA 560038',
        permanentAddress: 'Plot 12, Swaminathan Nilayam, Anna Nagar, Chennai, TN 600040',
        joiningDate: DateTime(2020, 6, 15),
        employmentType: EmploymentType.permanent,
        assignedClasses: const [
          ClassSubjectAssignment(
            grade: 'Class 10',
            section: 'A',
            subject: 'Mathematics',
            isClassTeacher: true,
            periodsPerWeek: 6,
          ),
          ClassSubjectAssignment(
            grade: 'Class 12',
            section: 'A',
            subject: 'Advanced Mathematics',
            isClassTeacher: false,
            periodsPerWeek: 6,
          ),
        ],
        compensation: const StaffCompensationModel(
          basicSalary: 85000.0,
          payFrequency: 'Monthly',
          bankName: 'State Bank of India',
          accountNumber: '30192847561',
          ifscCode: 'SBIN0004512',
          panNumber: 'ABCPS1234E',
          epfUan: '100984726152',
        ),
        loginAccount: const StaffLoginAccountModel(
          isEnabled: true,
          institutionalEmail: 'rajeshwari.swaminathan@edupulse.edu.in',
          systemRole: 'teacher',
          isFirstLoginPasswordChangeRequired: false,
        ),
        status: StaffStatus.active,
        gender: 'Female',
        dateOfBirth: DateTime(1982, 4, 12),
        bloodGroup: 'O+',
        emergencyContact: '+91 98450 99887',
      ),
      StaffMemberModel(
        id: 'STF-2026-0102',
        fullName: 'Vikramaditya Sen',
        category: StaffCategory.teaching,
        designation: 'Senior PGT Physics',
        department: 'Science',
        qualification: 'M.Sc. Physics (IIT Kharagpur), B.Ed.',
        specialization: 'Electrodynamics, Quantum Mechanics & Wave Optics',
        phone: '+91 97110 54321',
        email: 'vikramaditya.sen@edupulse.edu.in',
        currentAddress: 'B-14, Green Glen Layout, Bellandur, Bengaluru, KA 560103',
        permanentAddress: '58/2, Ballygunge Circular Road, Kolkata, WB 700019',
        joiningDate: DateTime(2021, 4, 1),
        employmentType: EmploymentType.permanent,
        assignedClasses: const [
          ClassSubjectAssignment(
            grade: 'Class 11',
            section: 'A',
            subject: 'Physics',
            isClassTeacher: true,
            periodsPerWeek: 5,
          ),
          ClassSubjectAssignment(
            grade: 'Class 12',
            section: 'B',
            subject: 'Physics',
            isClassTeacher: false,
            periodsPerWeek: 5,
          ),
        ],
        compensation: const StaffCompensationModel(
          basicSalary: 78000.0,
          payFrequency: 'Monthly',
          bankName: 'HDFC Bank',
          accountNumber: '5010048291039',
          ifscCode: 'HDFC0000240',
          panNumber: 'BKFPS9876Q',
          epfUan: '100874635291',
        ),
        loginAccount: const StaffLoginAccountModel(
          isEnabled: true,
          institutionalEmail: 'vikramaditya.sen@edupulse.edu.in',
          systemRole: 'teacher',
          isFirstLoginPasswordChangeRequired: false,
        ),
        status: StaffStatus.active,
        gender: 'Male',
        dateOfBirth: DateTime(1985, 9, 24),
        bloodGroup: 'B+',
        emergencyContact: '+91 97110 88776',
      ),
      StaffMemberModel(
        id: 'STF-2026-0103',
        fullName: 'Ananya Deshmukh',
        category: StaffCategory.teaching,
        designation: 'TGT English & Literature',
        department: 'Humanities',
        qualification: 'M.A. English Literature, B.Ed. (EFL University)',
        specialization: 'Contemporary World Literature & Creative Rhetoric',
        phone: '+91 94220 87654',
        email: 'ananya.deshmukh@edupulse.edu.in',
        currentAddress: 'A-304, Palm Meadows, Whitefield, Bengaluru, KA 560066',
        permanentAddress: '74 Shivaji Nagar, Pune, MH 411005',
        joiningDate: DateTime(2022, 6, 10),
        employmentType: EmploymentType.permanent,
        assignedClasses: const [
          ClassSubjectAssignment(
            grade: 'Class 8',
            section: 'B',
            subject: 'English Language',
            isClassTeacher: true,
            periodsPerWeek: 5,
          ),
          ClassSubjectAssignment(
            grade: 'Class 9',
            section: 'A',
            subject: 'English Literature',
            isClassTeacher: false,
            periodsPerWeek: 4,
          ),
        ],
        compensation: const StaffCompensationModel(
          basicSalary: 62000.0,
          payFrequency: 'Monthly',
          bankName: 'ICICI Bank',
          accountNumber: '004701582914',
          ifscCode: 'ICIC0000047',
          panNumber: 'CPDPA5432K',
          epfUan: '100763524189',
        ),
        loginAccount: const StaffLoginAccountModel(
          isEnabled: true,
          institutionalEmail: 'ananya.deshmukh@edupulse.edu.in',
          systemRole: 'teacher',
          isFirstLoginPasswordChangeRequired: false,
        ),
        status: StaffStatus.active,
        gender: 'Female',
        dateOfBirth: DateTime(1990, 11, 18),
        bloodGroup: 'A+',
        emergencyContact: '+91 94220 11223',
      ),
      StaffMemberModel(
        id: 'STF-2026-0104',
        fullName: 'Ramesh Bhat',
        category: StaffCategory.teaching,
        designation: 'TGT Social Science & History',
        department: 'Humanities',
        qualification: 'M.A. Modern Indian History, B.Ed.',
        specialization: 'Medieval & Post-Independence Indian History',
        phone: '+91 93410 78901',
        email: 'ramesh.bhat@edupulse.edu.in',
        currentAddress: '12, 5th Cross, Malleshwaram, Bengaluru, KA 560003',
        permanentAddress: '12, 5th Cross, Malleshwaram, Bengaluru, KA 560003',
        joiningDate: DateTime(2019, 7, 1),
        employmentType: EmploymentType.permanent,
        assignedClasses: const [
          ClassSubjectAssignment(
            grade: 'Class 6',
            section: 'B',
            subject: 'Social Studies',
            isClassTeacher: true,
            periodsPerWeek: 4,
          ),
          ClassSubjectAssignment(
            grade: 'Class 7',
            section: 'A',
            subject: 'History & Civics',
            isClassTeacher: false,
            periodsPerWeek: 4,
          ),
        ],
        compensation: const StaffCompensationModel(
          basicSalary: 59000.0,
          payFrequency: 'Monthly',
          bankName: 'Canara Bank',
          accountNumber: '118204928103',
          ifscCode: 'CNRB0001182',
          panNumber: 'BRTPB6789L',
          epfUan: '100652413290',
        ),
        loginAccount: const StaffLoginAccountModel(
          isEnabled: true,
          institutionalEmail: 'ramesh.bhat@edupulse.edu.in',
          systemRole: 'teacher',
          isFirstLoginPasswordChangeRequired: false,
        ),
        status: StaffStatus.active,
        gender: 'Male',
        dateOfBirth: DateTime(1983, 2, 14),
        bloodGroup: 'B-',
        emergencyContact: '+91 93410 33445',
      ),
      StaffMemberModel(
        id: 'STF-2026-0105',
        fullName: 'Sunita Verma',
        category: StaffCategory.administrative,
        designation: 'Chief Accountant & Bursar',
        department: 'Accounts & Finance',
        qualification: 'M.Com, Chartered Accountant (Inter), Tally ERP Expert',
        specialization: null,
        phone: '+91 98100 23456',
        email: 'sunita.verma@edupulse.edu.in',
        currentAddress: 'Flat 101, Prestige Oasis, Yelahanka, Bengaluru, KA 560064',
        permanentAddress: 'C-22, Civil Lines, Jaipur, RJ 302006',
        joiningDate: DateTime(2018, 3, 1),
        employmentType: EmploymentType.permanent,
        assignedClasses: const [],
        compensation: const StaffCompensationModel(
          basicSalary: 72000.0,
          payFrequency: 'Monthly',
          bankName: 'Punjab National Bank',
          accountNumber: '089201928374',
          ifscCode: 'PUNB0089200',
          panNumber: 'AVIPV4567M',
          epfUan: '100541328912',
        ),
        loginAccount: const StaffLoginAccountModel(
          isEnabled: true,
          institutionalEmail: 'sunita.verma@edupulse.edu.in',
          systemRole: 'admin',
          isFirstLoginPasswordChangeRequired: false,
        ),
        status: StaffStatus.active,
        gender: 'Female',
        dateOfBirth: DateTime(1980, 8, 30),
        bloodGroup: 'AB+',
        emergencyContact: '+91 98100 66554',
      ),
      StaffMemberModel(
        id: 'STF-2026-0106',
        fullName: 'Priya Sharma',
        category: StaffCategory.administrative,
        designation: 'Senior Admissions & Front-Desk Officer',
        department: 'Admissions & Reception',
        qualification: 'MBA in Public Relations, B.Com',
        specialization: null,
        phone: '+91 98860 34567',
        email: 'priya.sharma@edupulse.edu.in',
        currentAddress: '24, Rosewood Residency, JP Nagar Phase 6, Bengaluru, KA 560078',
        permanentAddress: '45-A, Model Town, Ludhiana, PB 141002',
        joiningDate: DateTime(2023, 1, 15),
        employmentType: EmploymentType.permanent,
        assignedClasses: const [],
        compensation: const StaffCompensationModel(
          basicSalary: 48000.0,
          payFrequency: 'Monthly',
          bankName: 'Axis Bank',
          accountNumber: '918020048192039',
          ifscCode: 'UTIB0000624',
          panNumber: 'ARFPS1234N',
          epfUan: '100430219847',
        ),
        loginAccount: const StaffLoginAccountModel(
          isEnabled: true,
          institutionalEmail: 'priya.sharma@edupulse.edu.in',
          systemRole: 'frontDesk',
          isFirstLoginPasswordChangeRequired: false,
        ),
        status: StaffStatus.active,
        gender: 'Female',
        dateOfBirth: DateTime(1994, 5, 19),
        bloodGroup: 'O+',
        emergencyContact: '+91 98860 77665',
      ),
      StaffMemberModel(
        id: 'STF-2026-0107',
        fullName: 'Kalyan Iyer',
        category: StaffCategory.teaching,
        designation: 'Computer Science & AI Lab Instructor',
        department: 'Computer Science',
        qualification: 'M.Tech in Computer Science, B.Tech (NIT Trichy)',
        specialization: 'Artificial Intelligence, Python Programming & Robotics',
        phone: '+91 97400 45678',
        email: 'kalyan.iyer@edupulse.edu.in',
        currentAddress: 'Tower 3-801, Brigade Metropolis, Mahadevapura, Bengaluru, KA 560048',
        permanentAddress: '19 Subramaniam Street, R.A. Puram, Chennai, TN 600028',
        joiningDate: DateTime(2023, 8, 1),
        employmentType: EmploymentType.probationary,
        assignedClasses: const [
          ClassSubjectAssignment(
            grade: 'Class 10',
            section: 'B',
            subject: 'Information Technology',
            isClassTeacher: false,
            periodsPerWeek: 4,
          ),
          ClassSubjectAssignment(
            grade: 'Class 12',
            section: 'A',
            subject: 'Computer Science',
            isClassTeacher: false,
            periodsPerWeek: 5,
          ),
        ],
        compensation: const StaffCompensationModel(
          basicSalary: 68000.0,
          payFrequency: 'Monthly',
          bankName: 'Kotak Mahindra Bank',
          accountNumber: '2810938471',
          ifscCode: 'KKBK0008064',
          panNumber: 'AWKPI5678R',
          epfUan: '100329104856',
        ),
        loginAccount: const StaffLoginAccountModel(
          isEnabled: true,
          institutionalEmail: 'kalyan.iyer@edupulse.edu.in',
          systemRole: 'teacher',
          isFirstLoginPasswordChangeRequired: false,
        ),
        status: StaffStatus.active,
        gender: 'Male',
        dateOfBirth: DateTime(1993, 7, 22),
        bloodGroup: 'O-',
        emergencyContact: '+91 97400 22110',
      ),
      StaffMemberModel(
        id: 'STF-2026-0108',
        fullName: 'Meenakshi Sundaram',
        category: StaffCategory.administrative,
        designation: 'Chief Librarian & Archival Head',
        department: 'Library',
        qualification: 'M.Lib.Sc., Ph.D. in Library Science',
        specialization: null,
        phone: '+91 98440 56789',
        email: 'meenakshi.sundaram@edupulse.edu.in',
        currentAddress: '18, 2nd Main, Vyalikaval, Bengaluru, KA 560003',
        permanentAddress: '18, 2nd Main, Vyalikaval, Bengaluru, KA 560003',
        joiningDate: DateTime(2017, 9, 1),
        employmentType: EmploymentType.permanent,
        assignedClasses: const [],
        compensation: const StaffCompensationModel(
          basicSalary: 56000.0,
          payFrequency: 'Monthly',
          bankName: 'Bank of Baroda',
          accountNumber: '29100100049281',
          ifscCode: 'BARB0VJYBAN',
          panNumber: 'ACXPS9182S',
          epfUan: '100218093745',
        ),
        loginAccount: const StaffLoginAccountModel(
          isEnabled: false,
          institutionalEmail: 'meenakshi.sundaram@edupulse.edu.in',
          systemRole: 'admin',
          isFirstLoginPasswordChangeRequired: false,
        ),
        status: StaffStatus.onLeave,
        gender: 'Female',
        dateOfBirth: DateTime(1978, 3, 15),
        bloodGroup: 'A-',
        emergencyContact: '+91 98440 99001',
      ),
      StaffMemberModel(
        id: 'STF-2026-0109',
        fullName: 'Gurpreet Singh Gill',
        category: StaffCategory.teaching,
        designation: 'Physical Education Director & Coach',
        department: 'Physical Education',
        qualification: 'M.P.Ed. (Sports Biomechanics), NIS Certified Athletics Coach',
        specialization: 'Track & Field, Football & Strength Conditioning',
        phone: '+91 99150 67890',
        email: 'gurpreet.singh@edupulse.edu.in',
        currentAddress: 'Villa 14, Prestige Silver Oak, ECC Road, Bengaluru, KA 560066',
        permanentAddress: 'Kothi 110, Sector 18, Chandigarh, CH 160018',
        joiningDate: DateTime(2020, 1, 10),
        employmentType: EmploymentType.permanent,
        assignedClasses: const [
          ClassSubjectAssignment(
            grade: 'Class 9',
            section: 'A',
            subject: 'Physical & Health Education',
            isClassTeacher: false,
            periodsPerWeek: 3,
          ),
          ClassSubjectAssignment(
            grade: 'Class 10',
            section: 'A',
            subject: 'Physical & Health Education',
            isClassTeacher: false,
            periodsPerWeek: 3,
          ),
        ],
        compensation: const StaffCompensationModel(
          basicSalary: 54000.0,
          payFrequency: 'Monthly',
          bankName: 'HDFC Bank',
          accountNumber: '5010039281048',
          ifscCode: 'HDFC0000053',
          panNumber: 'BLGPS8271T',
          epfUan: '100107982634',
        ),
        loginAccount: const StaffLoginAccountModel(
          isEnabled: true,
          institutionalEmail: 'gurpreet.singh@edupulse.edu.in',
          systemRole: 'teacher',
          isFirstLoginPasswordChangeRequired: false,
        ),
        status: StaffStatus.active,
        gender: 'Male',
        dateOfBirth: DateTime(1988, 12, 5),
        bloodGroup: 'O+',
        emergencyContact: '+91 99150 44556',
      ),
      StaffMemberModel(
        id: 'STF-2026-0110',
        fullName: 'Manjula Nayak',
        category: StaffCategory.support,
        designation: 'Senior Campus Caretaker & Housekeeping Lead',
        department: 'Campus Operations',
        qualification: 'Secondary School Certificate (SSLC)',
        specialization: null,
        phone: '+91 96110 78901',
        email: 'manjula.nayak@edupulse.edu.in',
        currentAddress: '28, Austin Town, Neelasandra, Bengaluru, KA 560047',
        permanentAddress: '28, Austin Town, Neelasandra, Bengaluru, KA 560047',
        joiningDate: DateTime(2016, 6, 1),
        employmentType: EmploymentType.permanent,
        assignedClasses: const [],
        compensation: const StaffCompensationModel(
          basicSalary: 28000.0,
          payFrequency: 'Monthly',
          bankName: 'State Bank of India',
          accountNumber: '20193847102',
          ifscCode: 'SBIN0000813',
          panNumber: 'AQMPN1928U',
          epfUan: '100096871523',
        ),
        loginAccount: null,
        status: StaffStatus.active,
        gender: 'Female',
        dateOfBirth: DateTime(1975, 1, 10),
        bloodGroup: 'B+',
        emergencyContact: '+91 96110 99880',
      ),
    ];
  }
}
