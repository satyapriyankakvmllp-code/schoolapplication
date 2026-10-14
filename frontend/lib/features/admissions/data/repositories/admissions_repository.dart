import '../../../../core/network/asset_loader.dart';
import '../models/admission_document_model.dart';
import '../models/admission_request_model.dart';
import '../models/parent_profile_model.dart';
import '../models/student_admission_model.dart';
import '../models/student_profile_model.dart';
import '../models/user_model.dart';

abstract class AdmissionsRepository {
  Future<List<StudentAdmissionModel>> getAdmissions();
  Future<StudentAdmissionModel?> getAdmissionById(String id);
  Future<StudentAdmissionModel> saveAdmission(StudentAdmissionModel admission);
  Future<bool> suspendAdmission(String studentId);
  Future<List<AdmissionRequestModel>> getAdmissionRequests();
  Future<AdmissionRequestModel> updateRequestStatus(
    String requestId,
    AdmissionRequestStatus status, {
    String? rejectionReason,
  });
  Future<AdmissionRequestModel> createAdmissionRequest(AdmissionRequestModel request);
}

class MockAdmissionsRepository implements AdmissionsRepository {
  final AssetLoader _assetLoader;
  static const String _mockDataPath = 'assets/data/admissions/admissions.json';
  static const String _mockRequestsPath = 'assets/data/admissions/admission_requests.json';

  // In-memory cache so newly created or edited students persist in the session
  List<StudentAdmissionModel>? _cachedAdmissions;
  List<AdmissionRequestModel>? _cachedRequests;
  bool _isAdmissionsJsonLoaded = false;
  bool _isRequestsJsonLoaded = false;

  MockAdmissionsRepository({AssetLoader? assetLoader})
      : _assetLoader = assetLoader ?? const AssetLoader() {
    _cachedAdmissions = _buildDefaultIndianAdmissions();
    _cachedRequests = _buildDefaultMockRequests();
  }

  Future<void> _ensureLoaded() async {
    if (_isAdmissionsJsonLoaded) return;
    _isAdmissionsJsonLoaded = true;
    try {
      final List<dynamic> list = await _assetLoader.loadJsonList(_mockDataPath, delayMs: 0);
      final loaded = list
          .map((item) => StudentAdmissionModel.fromJson(item as Map<String, dynamic>))
          .toList();
      if (loaded.isNotEmpty) {
        _cachedAdmissions = loaded;
      }
    } catch (_) {
      // Retain pre-seeded default Indian admissions
    }

    if (_cachedAdmissions == null || _cachedAdmissions!.isEmpty) {
      _cachedAdmissions = _buildDefaultIndianAdmissions();
    }
  }

  static List<StudentAdmissionModel> _buildDefaultIndianAdmissions() {
    return [
      StudentAdmissionModel(
        user: UserModel(
          id: 'usr-1001',
          email: 'aarav.sharma@example.com',
          phoneNumber: '+91 98765 43210',
          userRole: UserRole.student,
          firstName: 'Aarav',
          lastName: 'Sharma',
          gender: Gender.male,
          dateOfBirth: DateTime(2008, 11, 10),
          status: AccountStatus.active,
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 10, 11),
        ),
        student: StudentProfileModel(
          id: 'std-1001',
          userId: 'usr-1001',
          admissionNumber: 'ADM-2026-0042',
          rollNumber: '10',
          currentClassId: 'cls-10a',
          className: 'Class 10',
          section: 'A',
          admissionDate: DateTime(2026, 6, 15),
          academicYear: '2026-2027',
          bloodGroup: 'B+',
          height: '5.4',
          weight: '56kg',
          emergencyContactPhone: '+91 98112 34567',
          currentAddress: 'Flat 402, Green Glen Layout, Bellandur, Bengaluru, Karnataka 560103',
          residentialAddress: 'Flat 402, Green Glen Layout, Bellandur, Bengaluru, Karnataka 560103',
          permanentAddress: 'House No. 12B, Civil Lines, Jaipur, Rajasthan 302006',
          enrollmentStatus: EnrollmentStatus.enrolled,
          dobCertificate: 'Aadhaar_Birth_Certificate.pdf',
          mediumOfInstruction: 'English',
          houseGroup: 'Shivaji House',
          secondLanguage: 'Hindi',
          bankAccountNumber: '30459812456',
          bankName: 'State Bank of India (SBI)',
          ifscCode: 'SBIN0004521',
          nationalIdNumber: '7845 9632 1045',
          previousSchoolName: 'Delhi Public School (DPS), R.K. Puram',
          previousSchoolAddress: 'Sector 12, R.K. Puram, New Delhi',
          hostelName: 'Vivekananda Boys Hostel',
          roomNo: 'Room No. 204',
          additionalDetails: 'Disciplined student with consistent academic excellence and active participation in science olympiads.',
        ),
        father: ParentProfileModel(
          id: 'par-2001',
          userId: 'usr-2001',
          fullName: 'Rajesh Sharma',
          relationship: 'Father',
          phoneNumber: '+91 98112 34567',
          email: 'rajesh.sharma@example.com',
          occupation: 'Senior Project Manager',
          residentialAddress: 'Flat 402, Green Glen Layout, Bellandur, Bengaluru, Karnataka 560103',
        ),
        mother: ParentProfileModel(
          id: 'par-2002',
          userId: 'usr-2002',
          fullName: 'Sunita Sharma',
          relationship: 'Mother',
          phoneNumber: '+91 98112 34568',
          email: 'sunita.sharma@example.com',
          occupation: 'High School Teacher',
          residentialAddress: 'Flat 402, Green Glen Layout, Bellandur, Bengaluru, Karnataka 560103',
        ),
        guardian: ParentProfileModel(
          id: 'par-2001',
          userId: 'usr-2001',
          fullName: 'Rajesh Sharma',
          relationship: 'Guardian (Father)',
          phoneNumber: '+91 98112 34567',
          email: 'rajesh.sharma@example.com',
          residentialAddress: 'Flat 402, Green Glen Layout, Bellandur, Bengaluru, Karnataka 560103',
        ),
        selectedGuardianType: 'Father',
        documents: [
          AdmissionDocumentModel(
            id: 'doc-01',
            title: 'Birth Certificate',
            fileName: 'Aadhaar_Birth_Certificate.pdf',
            fileSize: '1.4 MB',
            fileType: 'pdf',
            isVerified: true,
            uploadedAt: DateTime(2026, 6, 15),
          ),
          AdmissionDocumentModel(
            id: 'doc-02',
            title: 'Previous Academic Record',
            fileName: 'Class_9_Marksheet.pdf',
            fileSize: '2.8 MB',
            fileType: 'pdf',
            isVerified: true,
            uploadedAt: DateTime(2026, 6, 15),
          ),
        ],
        loginEmail: 'aarav.sharma@example.com',
        loginPassword: '••••••••',
      ),
      StudentAdmissionModel(
        user: UserModel(
          id: 'usr-1002',
          email: 'ananya.iyer@example.com',
          phoneNumber: '+91 94451 22334',
          userRole: UserRole.student,
          firstName: 'Ananya',
          lastName: 'Iyer',
          gender: Gender.female,
          dateOfBirth: DateTime(2009, 2, 14),
          status: AccountStatus.active,
          createdAt: DateTime(2026, 6, 5),
          updatedAt: DateTime(2026, 10, 10),
        ),
        student: StudentProfileModel(
          id: 'std-1002',
          userId: 'usr-1002',
          admissionNumber: 'ADM-2026-0043',
          rollNumber: '14',
          currentClassId: 'cls-10b',
          className: 'Class 10',
          section: 'B',
          admissionDate: DateTime(2026, 7, 1),
          academicYear: '2026-2027',
          bloodGroup: 'A+',
          height: '5.3',
          weight: '50kg',
          emergencyContactPhone: '+91 94451 99887',
          currentAddress: 'Plot 18, 4th Cross, Gandhi Nagar, Adyar, Chennai, Tamil Nadu 600020',
          residentialAddress: 'Plot 18, 4th Cross, Gandhi Nagar, Adyar, Chennai, Tamil Nadu 600020',
          permanentAddress: 'Plot 18, 4th Cross, Gandhi Nagar, Adyar, Chennai, Tamil Nadu 600020',
          enrollmentStatus: EnrollmentStatus.enrolled,
          dobCertificate: 'BirthCertificate_Ananya.pdf',
          mediumOfInstruction: 'English',
          houseGroup: 'Tagore House',
          secondLanguage: 'Sanskrit',
          bankAccountNumber: '501002345678',
          bankName: 'HDFC Bank',
          ifscCode: 'HDFC0001024',
          nationalIdNumber: '6541 2398 7412',
          previousSchoolName: 'Padma Seshadri Bala Bhavan (PSBB)',
          previousSchoolAddress: 'Nungambakkam, Chennai',
          additionalDetails: 'Carnatic classical music vocalist, school mathematics champion, and exemplary student.',
        ),
        father: ParentProfileModel(
          id: 'par-2003',
          userId: 'usr-2003',
          fullName: 'Karthik Iyer',
          relationship: 'Father',
          phoneNumber: '+91 94451 99887',
          email: 'karthik.iyer@example.com',
          occupation: 'Chartered Accountant',
          residentialAddress: 'Plot 18, 4th Cross, Gandhi Nagar, Adyar, Chennai, Tamil Nadu 600020',
        ),
        mother: ParentProfileModel(
          id: 'par-2004',
          userId: 'usr-2004',
          fullName: 'Meenakshi Iyer',
          relationship: 'Mother',
          phoneNumber: '+91 94451 99888',
          email: 'meenakshi.iyer@example.com',
          occupation: 'Professor of Chemistry',
          residentialAddress: 'Plot 18, 4th Cross, Gandhi Nagar, Adyar, Chennai, Tamil Nadu 600020',
        ),
        guardian: ParentProfileModel(
          id: 'par-2003',
          userId: 'usr-2003',
          fullName: 'Karthik Iyer',
          relationship: 'Guardian (Father)',
          phoneNumber: '+91 94451 99887',
          email: 'karthik.iyer@example.com',
          residentialAddress: 'Plot 18, 4th Cross, Gandhi Nagar, Adyar, Chennai, Tamil Nadu 600020',
        ),
        selectedGuardianType: 'Father',
        documents: [
          AdmissionDocumentModel(
            id: 'doc-04',
            title: 'Birth Certificate',
            fileName: 'BirthCertificate_Ananya.pdf',
            fileSize: '1.1 MB',
            fileType: 'pdf',
            isVerified: true,
            uploadedAt: DateTime(2026, 7, 1),
          ),
        ],
        loginEmail: 'ananya.iyer@example.com',
        loginPassword: '••••••••',
      ),
    ];
  }

  static StudentAdmissionModel get defaultStudent => _buildDefaultIndianAdmissions().first;
  static List<StudentAdmissionModel> get defaultAdmissions => _buildDefaultIndianAdmissions();

  @override
  Future<List<StudentAdmissionModel>> getAdmissions() async {
    if (!_isAdmissionsJsonLoaded) {
      _ensureLoaded();
    }
    return List.unmodifiable(_cachedAdmissions ?? defaultAdmissions);
  }

  @override
  Future<StudentAdmissionModel?> getAdmissionById(String id) async {
    if (id.isEmpty) return null;
    if (!_isAdmissionsJsonLoaded) {
      _ensureLoaded();
    }
    final list = _cachedAdmissions ?? defaultAdmissions;
    try {
      return list.firstWhere(
        (a) => a.student.id == id || a.student.admissionNumber.toLowerCase() == id.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<StudentAdmissionModel> saveAdmission(StudentAdmissionModel admission) async {
    await _ensureLoaded();
    final index = _cachedAdmissions!.indexWhere(
      (a) => a.student.id == admission.student.id,
    );
    if (index >= 0) {
      _cachedAdmissions![index] = admission;
    } else {
      _cachedAdmissions!.insert(0, admission);
    }
    // Simulate API delay
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return admission;
  }

  @override
  Future<bool> suspendAdmission(String studentId) async {
    await _ensureLoaded();
    final index = _cachedAdmissions!.indexWhere((a) => a.student.id == studentId);
    if (index >= 0) {
      final current = _cachedAdmissions![index];
      _cachedAdmissions![index] = current.copyWith(
        student: current.student.copyWith(enrollmentStatus: EnrollmentStatus.discontinued),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return true;
    }
    return false;
  }

  Future<void> _ensureRequestsLoaded() async {
    if (_isRequestsJsonLoaded) return;
    _isRequestsJsonLoaded = true;
    try {
      final List<dynamic> list = await _assetLoader.loadJsonList(_mockRequestsPath, delayMs: 0);
      final loaded = list
          .map((item) => AdmissionRequestModel.fromJson(item as Map<String, dynamic>))
          .toList();
      if (loaded.isNotEmpty) {
        _cachedRequests = loaded;
      }
    } catch (_) {
      // Retain pre-seeded default mock requests
    }

    if (_cachedRequests == null || _cachedRequests!.isEmpty) {
      _cachedRequests = _buildDefaultMockRequests();
    }
  }

  static List<AdmissionRequestModel> _buildDefaultMockRequests() {
    return [
      AdmissionRequestModel(
        id: 'req-201',
        applicantFirstName: 'Reyansh',
        applicantLastName: 'Patel',
        gender: 'MALE',
        dateOfBirth: DateTime(2015, 4, 18),
        bloodGroup: 'O+',
        gradeApplied: 'Class 6',
        academicYear: '2026-2027',
        source: AdmissionRequestSource.parentPortal,
        status: AdmissionRequestStatus.pending,
        appliedAt: DateTime.now().subtract(const Duration(hours: 4)),
        parentFullName: 'Bhavin Patel',
        parentRelationship: 'Father',
        parentPhone: '+91 98234 11223',
        parentEmail: 'bhavin.patel@example.com',
        parentOccupation: 'Software Architect',
        currentAddress: 'Villa 14, Palm Meadows, Whitefield, Bengaluru, Karnataka 560066',
        permanentAddress: 'Villa 14, Palm Meadows, Whitefield, Bengaluru, Karnataka 560066',
        previousSchoolName: 'Greenwood High International School',
        emergencyContactPhone: '+91 98234 11223',
        documents: const [
          'Reyansh_Birth_Certificate.pdf',
          'Transfer_Certificate_Greenwood.pdf',
        ],
        notes: 'Relocating from East Bengaluru. Prefers Science and Robotics clubs.',
      ),
      AdmissionRequestModel(
        id: 'req-202',
        applicantFirstName: 'Ananya',
        applicantLastName: 'Verma',
        gender: 'FEMALE',
        dateOfBirth: DateTime(2020, 8, 25),
        bloodGroup: 'A+',
        gradeApplied: 'Class 1',
        academicYear: '2026-2027',
        source: AdmissionRequestSource.frontDesk,
        status: AdmissionRequestStatus.pending,
        appliedAt: DateTime.now().subtract(const Duration(hours: 2)),
        parentFullName: 'Sunita Verma',
        parentRelationship: 'Mother',
        parentPhone: '+91 97412 88990',
        parentEmail: 'sunita.verma@example.com',
        parentOccupation: 'Chartered Accountant',
        currentAddress: 'Apt 301, Silver Crest, HSR Layout Sector 2, Bengaluru 560102',
        permanentAddress: 'Apt 301, Silver Crest, HSR Layout Sector 2, Bengaluru 560102',
        previousSchoolName: 'EuroKids Preschool HSR',
        emergencyContactPhone: '+91 97412 88990',
        documents: const [
          'Ananya_Birth_Certificate.pdf',
          'Medical_Immunization_Record.pdf',
        ],
        notes: 'Walk-in registration filled at Frontdesk reception by officer Mrs. Radhika.',
      ),
      AdmissionRequestModel(
        id: 'req-203',
        applicantFirstName: 'Kavya',
        applicantLastName: 'Reddy',
        gender: 'FEMALE',
        dateOfBirth: DateTime(2013, 2, 14),
        bloodGroup: 'B+',
        gradeApplied: 'Class 8',
        academicYear: '2026-2027',
        source: AdmissionRequestSource.parentPortal,
        status: AdmissionRequestStatus.pending,
        appliedAt: DateTime.now().subtract(const Duration(days: 1)),
        parentFullName: 'Venkat Reddy',
        parentRelationship: 'Father',
        parentPhone: '+91 99001 54321',
        parentEmail: 'venkat.reddy@example.com',
        parentOccupation: 'Civil Engineer',
        currentAddress: 'House No. 88, 14th Main, Indiranagar, Bengaluru 560038',
        permanentAddress: 'House No. 88, 14th Main, Indiranagar, Bengaluru 560038',
        previousSchoolName: 'National Public School (NPS)',
        emergencyContactPhone: '+91 99001 54321',
        documents: const [
          'Kavya_Birth_Certificate.pdf',
          'NPS_Transfer_Certificate.pdf',
        ],
        notes: 'Transfer request due to change of residence. State-level badminton player.',
      ),
      AdmissionRequestModel(
        id: 'req-204',
        applicantFirstName: 'Kabir',
        applicantLastName: 'Mehta',
        gender: 'MALE',
        dateOfBirth: DateTime(2017, 11, 5),
        bloodGroup: 'AB+',
        gradeApplied: 'Class 4',
        academicYear: '2026-2027',
        source: AdmissionRequestSource.frontDesk,
        status: AdmissionRequestStatus.pending,
        appliedAt: DateTime.now().subtract(const Duration(hours: 6)),
        parentFullName: 'Deepak Mehta',
        parentRelationship: 'Father',
        parentPhone: '+91 98450 77123',
        parentEmail: 'deepak.mehta@example.com',
        parentOccupation: 'Product Manager',
        currentAddress: 'Tower C, Flat 1204, Prestige Lakeside, Varthur, Bengaluru 560087',
        permanentAddress: 'Tower C, Flat 1204, Prestige Lakeside, Varthur, Bengaluru 560087',
        previousSchoolName: 'Oakridge International School',
        emergencyContactPhone: '+91 98450 77123',
        documents: const [
          'Kabir_Birth_Certificate.pdf',
        ],
        notes: 'Frontdesk intake verified by Admission Desk.',
      ),
      AdmissionRequestModel(
        id: 'req-205',
        applicantFirstName: 'Isha',
        applicantLastName: 'Chopra',
        gender: 'FEMALE',
        dateOfBirth: DateTime(2011, 7, 19),
        bloodGroup: 'O-',
        gradeApplied: 'Class 10',
        academicYear: '2026-2027',
        source: AdmissionRequestSource.parentPortal,
        status: AdmissionRequestStatus.approved,
        appliedAt: DateTime.now().subtract(const Duration(days: 4)),
        reviewedAt: DateTime.now().subtract(const Duration(days: 3)),
        parentFullName: 'Rohan Chopra',
        parentRelationship: 'Father',
        parentPhone: '+91 98860 33445',
        parentEmail: 'rohan.chopra@example.com',
        parentOccupation: 'Architect',
        currentAddress: 'Flat 502, Orchid Woods, Hennur Main Road, Bengaluru 560043',
        permanentAddress: 'Flat 502, Orchid Woods, Hennur Main Road, Bengaluru 560043',
        previousSchoolName: 'Delhi Public School Bangalore North',
        emergencyContactPhone: '+91 98860 33445',
        documents: const [
          'Isha_Birth_Certificate.pdf',
          'TC_DPS_North.pdf',
        ],
        notes: 'Approved by Admin. Enrolled into Class 10-A.',
      ),
      AdmissionRequestModel(
        id: 'req-206',
        applicantFirstName: 'Rohan',
        applicantLastName: 'Nair',
        gender: 'MALE',
        dateOfBirth: DateTime(2018, 9, 30),
        bloodGroup: 'B+',
        gradeApplied: 'Class 3',
        academicYear: '2026-2027',
        source: AdmissionRequestSource.frontDesk,
        status: AdmissionRequestStatus.approved,
        appliedAt: DateTime.now().subtract(const Duration(days: 5)),
        reviewedAt: DateTime.now().subtract(const Duration(days: 4)),
        parentFullName: 'Priya Nair',
        parentRelationship: 'Mother',
        parentPhone: '+91 98200 44556',
        parentEmail: 'priya.nair@example.com',
        parentOccupation: 'Dentist',
        currentAddress: 'No 45, 7th Cross, Koramangala 4th Block, Bengaluru 560034',
        permanentAddress: 'No 45, 7th Cross, Koramangala 4th Block, Bengaluru 560034',
        previousSchoolName: 'Bethany High School',
        emergencyContactPhone: '+91 98200 44556',
        documents: const [
          'Rohan_Birth_Certificate.pdf',
        ],
        notes: 'Approved by Principal. Fee structure assigned.',
      ),
      AdmissionRequestModel(
        id: 'req-207',
        applicantFirstName: 'Manav',
        applicantLastName: 'Singhania',
        gender: 'MALE',
        dateOfBirth: DateTime(2014, 6, 12),
        bloodGroup: 'A-',
        gradeApplied: 'Class 7',
        academicYear: '2026-2027',
        source: AdmissionRequestSource.parentPortal,
        status: AdmissionRequestStatus.rejected,
        appliedAt: DateTime.now().subtract(const Duration(days: 6)),
        reviewedAt: DateTime.now().subtract(const Duration(days: 5)),
        rejectionReason: 'Class capacity full - No vacant seats in Class 7 for 2026-2027',
        parentFullName: 'Vikram Singhania',
        parentRelationship: 'Father',
        parentPhone: '+91 99450 12890',
        parentEmail: 'vikram.singhania@example.com',
        parentOccupation: 'Industrialist',
        currentAddress: 'Penthouse 12, Sobha Iris, Outer Ring Road, Bengaluru 560103',
        permanentAddress: 'Penthouse 12, Sobha Iris, Outer Ring Road, Bengaluru 560103',
        previousSchoolName: 'Bishop Cotton Boys School',
        emergencyContactPhone: '+91 99450 12890',
        documents: const [
          'Manav_Birth_Certificate.pdf',
        ],
        notes: 'Class 7 quota full across all sections A, B, C.',
      ),
      AdmissionRequestModel(
        id: 'req-208',
        applicantFirstName: 'Tanya',
        applicantLastName: 'Sengupta',
        gender: 'FEMALE',
        dateOfBirth: DateTime(2022, 1, 10),
        bloodGroup: 'O+',
        gradeApplied: 'Class 1',
        academicYear: '2026-2027',
        source: AdmissionRequestSource.frontDesk,
        status: AdmissionRequestStatus.rejected,
        appliedAt: DateTime.now().subtract(const Duration(days: 7)),
        reviewedAt: DateTime.now().subtract(const Duration(days: 6)),
        rejectionReason: 'Age criteria not met for Class 1 (Minimum age required: 5.5 years)',
        parentFullName: 'Debashis Sengupta',
        parentRelationship: 'Father',
        parentPhone: '+91 98100 88221',
        parentEmail: 'debashis.sengupta@example.com',
        parentOccupation: 'Journalist',
        currentAddress: 'Flat 204, Sobha Quartz, Bellandur, Bengaluru 560103',
        permanentAddress: 'Flat 204, Sobha Quartz, Bellandur, Bengaluru 560103',
        previousSchoolName: 'First Steps Montessori',
        emergencyContactPhone: '+91 98100 88221',
        documents: const [
          'Tanya_Birth_Certificate.pdf',
        ],
        notes: 'Advised parent to apply for UKG / Pre-primary intake.',
      ),
    ];
  }

  @override
  Future<List<AdmissionRequestModel>> getAdmissionRequests() async {
    await _ensureRequestsLoaded();
    return List.unmodifiable(_cachedRequests!);
  }

  @override
  Future<AdmissionRequestModel> updateRequestStatus(
    String requestId,
    AdmissionRequestStatus status, {
    String? rejectionReason,
  }) async {
    await _ensureRequestsLoaded();
    final index = _cachedRequests!.indexWhere((r) => r.id == requestId);
    if (index >= 0) {
      final current = _cachedRequests![index];
      final updated = current.copyWith(
        status: status,
        reviewedAt: DateTime.now(),
        rejectionReason: rejectionReason ?? current.rejectionReason,
      );
      _cachedRequests![index] = updated;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return updated;
    }
    throw Exception('Admission request not found: $requestId');
  }

  @override
  Future<AdmissionRequestModel> createAdmissionRequest(AdmissionRequestModel request) async {
    await _ensureRequestsLoaded();
    _cachedRequests!.insert(0, request);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return request;
  }
}
