import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/app_dropdown.dart';

class RelationSelector extends StatelessWidget {
  final List<String> relations;
  final String selectedRelation;
  final ValueChanged<String> onRelationChanged;

  const RelationSelector({
    super.key,
    required this.relations,
    required this.selectedRelation,
    required this.onRelationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppDropdown(
      labelText: 'Relation',
      showLabel: false, // Assuming label is handled by parent, matching existing chips layout
      value: selectedRelation.isNotEmpty ? selectedRelation : null,
      items: relations,
      hintText: 'Select Relation',
      onChanged: (value) {
        if (value != null) {
          onRelationChanged(value);
        }
      },
      fillColor: Colors.transparent,
    );
  }
}
