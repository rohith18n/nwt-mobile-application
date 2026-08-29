import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/app_dropdown.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/services/bse_star/nominee_relation.dart';
import 'package:nwt_app/screens/bse_star/types/nominee_relation.dart';

class DynamicRelationSelector extends StatefulWidget {
  final String selectedRelationName;
  final String? selectedRelationId;
  final ValueChanged<String> onRelationNameChanged;
  final ValueChanged<String> onRelationIdChanged;
  final String? errorText;
  final bool enabled;

  const DynamicRelationSelector({
    super.key,
    required this.selectedRelationName,
    this.selectedRelationId,
    required this.onRelationNameChanged,
    required this.onRelationIdChanged,
    this.errorText,
    this.enabled = true,
  });

  @override
  State<DynamicRelationSelector> createState() =>
      _DynamicRelationSelectorState();
}

class _DynamicRelationSelectorState extends State<DynamicRelationSelector> {
  List<Datum>? _relations;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRelations();
  }

  Future<void> _loadRelations() async {
    try {
      // Don't show loading state initially, load silently in background
      if (_relations == null) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final relations =
          await BseNomineeRelationService.getNomineeRelationsList();

      if (relations != null && relations.isNotEmpty) {
        setState(() {
          _relations = relations;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'No relations found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load relations: $e';
        _isLoading = false;
      });
    }
  }

  void _handleRelationSelection(Datum relation) {
    // Update both name and ID
    widget.onRelationNameChanged(relation.name);
    widget.onRelationIdChanged(relation.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              'Loading relations...',
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.gray,
            ),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: AppText(
                _error!,
                variant: AppTextVariant.bodySmall,
                colorType: AppTextColorType.error,
              ),
            ),
            GestureDetector(
              onTap: _loadRelations,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: AppText(
                  'Retry',
                  variant: AppTextVariant.bodySmall,
                  colorType: AppTextColorType.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_relations == null || _relations!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: AppText(
          'No relations available',
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.gray,
        ),
      );
    }

    final List<String> relationNames = _relations!.map((r) => r.name).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppDropdown(
          labelText: 'Relation',
          showLabel: false,
          value:
              widget.selectedRelationName.isNotEmpty
                  ? widget.selectedRelationName
                  : null,
          items: relationNames,
          hintText: 'Select Relation',
          enabled: widget.enabled,
          onChanged: (value) {
            if (value != null) {
              final selectedRelation = _relations!.firstWhere(
                (r) => r.name == value,
              );
              _handleRelationSelection(selectedRelation);
            }
          },
          fillColor: Colors.transparent,
        ),
        if (widget.errorText != null && widget.errorText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          AppText(
            widget.errorText!,
            variant: AppTextVariant.bodySmall,
            customColor: Colors.redAccent,
            weight: AppTextWeight.medium,
          ),
        ],
      ],
    );
  }
}
