/// Centralized configurable grade scale and performance tier definitions.
class GradeTier {
  final double minPercentage;
  final String grade;
  final double gpa;
  final String performance; // Outstanding, Excellent, Very Good, Good, Average, Needs Improvement
  final String description;

  const GradeTier({
    required this.minPercentage,
    required this.grade,
    required this.gpa,
    required this.performance,
    required this.description,
  });
}

class GradeScaleConfig {
  static const List<GradeTier> tiers = [
    GradeTier(
      minPercentage: 90.0,
      grade: 'A+',
      gpa: 4.0,
      performance: 'Outstanding',
      description: 'Exceptional mastery of subject concepts and coursework.',
    ),
    GradeTier(
      minPercentage: 80.0,
      grade: 'A',
      gpa: 3.7,
      performance: 'Excellent',
      description: 'High level of achievement exceeding course objectives.',
    ),
    GradeTier(
      minPercentage: 70.0,
      grade: 'B+',
      gpa: 3.3,
      performance: 'Very Good',
      description: 'Sound understanding with consistent academic rigor.',
    ),
    GradeTier(
      minPercentage: 60.0,
      grade: 'B',
      gpa: 3.0,
      performance: 'Good',
      description: 'Competent understanding meeting grade standards.',
    ),
    GradeTier(
      minPercentage: 50.0,
      grade: 'C',
      gpa: 2.0,
      performance: 'Average',
      description: 'Satisfactory performance with scope for improvement.',
    ),
    GradeTier(
      minPercentage: 40.0,
      grade: 'D',
      gpa: 1.0,
      performance: 'Needs Improvement',
      description: 'Minimum passing threshold; remediation advised.',
    ),
    GradeTier(
      minPercentage: 0.0,
      grade: 'F',
      gpa: 0.0,
      performance: 'Needs Improvement',
      description: 'Did not meet passing criteria.',
    ),
  ];

  static GradeTier evaluate(double percentage, {bool passed = true}) {
    if (!passed) {
      return tiers.last;
    }
    for (final tier in tiers) {
      if (percentage >= tier.minPercentage) {
        return tier;
      }
    }
    return tiers.last;
  }

  static String gradeFor(double percentage, {bool passed = true}) =>
      evaluate(percentage, passed: passed).grade;

  static double gpaFor(double percentage, {bool passed = true}) =>
      evaluate(percentage, passed: passed).gpa;

  static String performanceFor(double percentage, {bool passed = true}) =>
      evaluate(percentage, passed: passed).performance;
}

