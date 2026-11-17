import 'bn_guide.dart';
import 'bn_part1.dart';
import 'bn_part2.dart';
import 'bn_part3.dart';

export 'bn_part4.dart' show bnTemplates;

/// Every Bengali translation of a whole text, by its English original.
final Map<String, String> bnExact = {...bnPart1, ...bnPart2, ...bnPart3, ...bnGuideStrings};
