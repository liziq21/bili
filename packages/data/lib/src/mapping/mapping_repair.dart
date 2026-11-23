import 'package:meta/meta.dart';

import 'mapping_conformance.dart';

/// A deterministic brief for a build-time repair agent.
///
/// The request contains no model output and no credentials: it is the input a
/// human or external agent uses to propose a descriptor change. The proposed
/// change still has to pass the validator, conformance, and task-level tests.
@immutable
final class const MappingRepairRequest({
  required final String feedId,
  required final String fixturePath,
  required final String goldenPath,
  required final String descriptorFile,
  required final List<MappingDifference> differences,
  required final Set<String> requiredFields,
  required final int schemaVersion,
  final String? promptPath,
  final String? notes,
}) {
  bool get hasDifferences => differences.isNotEmpty;

  Map<String, Object?> toJson() => {
    'feedId': feedId,
    'fixturePath': fixturePath,
    'goldenPath': goldenPath,
    'descriptorFile': descriptorFile,
    'promptPath': promptPath,
    'schemaVersion': schemaVersion,
    'requiredFields': requiredFields.toList()..sort(),
    'differenceCount': differences.length,
    'differences': [for (final difference in differences) difference.toJson()],
    if (notes != null) 'notes': notes,
  };
}

/// Builds a repair request from a conformance diff.
MappingRepairRequest buildMappingRepairRequest({
  required String feedId,
  required String fixturePath,
  required String goldenPath,
  required String descriptorFile,
  required List<MappingDifference> differences,
  required Set<String> requiredFields,
  required int schemaVersion,
  String? promptPath = 'tool/mapping_scaffold_prompt.md',
  String? notes,
}) => MappingRepairRequest(
  feedId: feedId,
  fixturePath: fixturePath,
  goldenPath: goldenPath,
  descriptorFile: descriptorFile,
  differences: differences,
  requiredFields: requiredFields,
  schemaVersion: schemaVersion,
  promptPath: promptPath,
  notes: notes,
);
