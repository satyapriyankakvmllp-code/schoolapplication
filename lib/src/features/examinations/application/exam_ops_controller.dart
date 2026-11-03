import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/exam_ops_repository.dart';

final examOpsRepositoryProvider =
    Provider<ExamOpsRepository>((ref) => ExamOpsRepository());
