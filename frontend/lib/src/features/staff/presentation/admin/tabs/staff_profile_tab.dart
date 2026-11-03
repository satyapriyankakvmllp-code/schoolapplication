import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/staff_member_model.dart';

/// Tab 1: Profile Details (matching Screenshot 1)
/// Contains Profile Detail, Previous School Details, Address, Bank Details,
/// Medical Details, Documents, Social Media, and Description cards.
class StaffProfileTab extends StatelessWidget {
  final StaffMemberModel staff;
  final bool isDark;

  const StaffProfileTab({
    super.key,
    required this.staff,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final dobStr = staff.dateOfBirth != null
        ? DateFormat('d MMM yyyy').format(staff.dateOfBirth!)
        : '10 Nov 1995';

    final expYears = DateTime.now().year - staff.joiningDate.year + 3;

    final maritalStr = staff.maritalStatus ?? 'Married';
    final expStr = '${staff.experienceYears ?? expYears} Years';
    final fatherStr = staff.fatherName ?? 'Ralph Edwards';
    final motherStr = staff.motherName ?? 'Floyd Miles';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 850;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Detail Card (Full Width)
            _buildSectionCard(
              title: 'Profile Detail',
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              child: isNarrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldItem('Date of Birth', dobStr, textColor, subColor),
                        const SizedBox(height: 12),
                        _buildFieldItem('Marital Status', maritalStr, textColor, subColor),
                        const SizedBox(height: 12),
                        _buildFieldItem('Qualification', staff.qualification, textColor, subColor),
                        const SizedBox(height: 12),
                        _buildFieldItem('Experience', expStr, textColor, subColor),
                        const SizedBox(height: 12),
                        _buildFieldItem('Father Name', fatherStr, textColor, subColor),
                        const SizedBox(height: 12),
                        _buildFieldItem('Mother Name', motherStr, textColor, subColor),
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildFieldItem('Date of Birth', dobStr, textColor, subColor)),
                            Expanded(child: _buildFieldItem('Marital Status', maritalStr, textColor, subColor)),
                            Expanded(child: _buildFieldItem('Qualification', staff.qualification, textColor, subColor)),
                            Expanded(child: _buildFieldItem('Experience', expStr, textColor, subColor)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildFieldItem('Father Name', fatherStr, textColor, subColor)),
                            Expanded(child: _buildFieldItem('Mother Name', motherStr, textColor, subColor)),
                            const Expanded(child: SizedBox.shrink()),
                            const Expanded(child: SizedBox.shrink()),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // 2. Previous School Details & Address
            if (isNarrow) ...[
              _buildPreviousSchoolCard(cardBg, borderColor, textColor, subColor),
              const SizedBox(height: 16),
              _buildAddressCard(cardBg, borderColor, textColor, subColor),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildPreviousSchoolCard(cardBg, borderColor, textColor, subColor)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildAddressCard(cardBg, borderColor, textColor, subColor)),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // 3. Bank Details & Medical Details
            if (isNarrow) ...[
              _buildBankCard(cardBg, borderColor, textColor, subColor),
              const SizedBox(height: 16),
              _buildMedicalCard(cardBg, borderColor, textColor, subColor),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildBankCard(cardBg, borderColor, textColor, subColor)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMedicalCard(cardBg, borderColor, textColor, subColor)),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // 4. Documents & Social Media
            if (isNarrow) ...[
              _buildDocumentsCard(context, cardBg, borderColor, textColor, subColor),
              const SizedBox(height: 16),
              _buildSocialCard(cardBg, borderColor, textColor, subColor),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildDocumentsCard(context, cardBg, borderColor, textColor, subColor)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSocialCard(cardBg, borderColor, textColor, subColor)),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // 5. Description Card (Full Width)
            _buildSectionCard(
              title: 'Description',
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              child: Text(
                'Known for their punctuality and positive attitude, ${staff.fullName} consistently demonstrates a strong commitment to academic excellence and co-curricular participation. They maintain good professional decorum, foster collaborative relationships with faculty and students, and actively lead departmental innovation and student mentoring programs.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: subColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviousSchoolCard(Color cardBg, Color borderColor, Color textColor, Color subColor) {
    return _buildSectionCard(
      title: 'Previous School Details',
      cardBg: cardBg,
      borderColor: borderColor,
      textColor: textColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldItem('Previous School Name', staff.previousSchool ?? 'Stuyvesant High School', textColor, subColor),
          const SizedBox(height: 16),
          _buildFieldItem('Current School Name', staff.currentSchool ?? 'EduPulse Global Academy (Bronx Campus)', textColor, subColor),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Color cardBg, Color borderColor, Color textColor, Color subColor) {
    return _buildSectionCard(
      title: 'Address',
      cardBg: cardBg,
      borderColor: borderColor,
      textColor: textColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldItem('Current Address', staff.currentAddress, textColor, subColor),
          const SizedBox(height: 16),
          _buildFieldItem('Permanent Address', staff.permanentAddress, textColor, subColor),
        ],
      ),
    );
  }

  Widget _buildBankCard(Color cardBg, Color borderColor, Color textColor, Color subColor) {
    return _buildSectionCard(
      title: 'Bank Details',
      cardBg: cardBg,
      borderColor: borderColor,
      textColor: textColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildFieldItem('Bank Name', staff.compensation.bankName, textColor, subColor),
          ),
          Expanded(
            child: _buildFieldItem('Branch', staff.bankBranch ?? 'Main Central Branch', textColor, subColor),
          ),
          Expanded(
            child: _buildFieldItem('IFSC Code', staff.compensation.ifscCode, textColor, subColor),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalCard(Color cardBg, Color borderColor, Color textColor, Color subColor) {
    return _buildSectionCard(
      title: 'Medical Details',
      cardBg: cardBg,
      borderColor: borderColor,
      textColor: textColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildFieldItem('Blood Group', staff.bloodGroup ?? 'O+', textColor, subColor),
          ),
          Expanded(
            child: _buildFieldItem('Height', staff.height ?? '5.8 ft', textColor, subColor),
          ),
          Expanded(
            child: _buildFieldItem('Weight', staff.weight ?? '68 kg', textColor, subColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsCard(BuildContext context, Color cardBg, Color borderColor, Color textColor, Color subColor) {
    final docs = staff.documents ?? [
      {'name': 'DegreeCertificate.pdf', 'size': '2.4 MB'},
      {'name': 'BirthCertificate.pdf', 'size': '1.1 MB'},
      {'name': 'EmploymentContract.pdf', 'size': '3.5 MB'},
    ];

    return _buildSectionCard(
      title: 'Documents',
      cardBg: cardBg,
      borderColor: borderColor,
      textColor: textColor,
      child: Column(
        children: docs.map((doc) {
          final docName = doc['name']?.toString() ?? 'Document.pdf';
          final docSize = doc['size']?.toString() ?? '1.5 MB';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFEF4444), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        docName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        docSize,
                        style: TextStyle(fontSize: 11, color: subColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download_outlined, color: Color(0xFF109F83), size: 20),
                  tooltip: 'Download $docName',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading $docName...'),
                        backgroundColor: const Color(0xFF109F83),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSocialCard(Color cardBg, Color borderColor, Color textColor, Color subColor) {
    final fb = staff.socialMedia?['facebook']?.toString() ?? 'www.facebook.com/faculty';
    final li = staff.socialMedia?['linkedin']?.toString() ?? 'www.linkedin.com/in/faculty';
    final ig = staff.socialMedia?['instagram']?.toString() ?? 'www.instagram.com/faculty';

    return _buildSectionCard(
      title: 'Social Media',
      cardBg: cardBg,
      borderColor: borderColor,
      textColor: textColor,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFieldItem('Facebook', fb, textColor, subColor),
              ),
              Expanded(
                child: _buildFieldItem('LinkedIn', li, textColor, subColor),
              ),
              Expanded(
                child: _buildFieldItem('Instagram', ig, textColor, subColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldItem(String label, String value, Color textColor, Color subColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: subColor,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
