import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/screens/bse_star/types/occupation_option.dart';
import 'package:nwt_app/services/bse_star/occupation_options.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class OccupationDropdown extends StatefulWidget {
  final String? selectedOccupationId;
  final Function(Datum) onOccupationSelected;
  final String label;
  final String hintText;
  final bool enabled;
  final String? errorText;

  const OccupationDropdown({
    super.key,
    this.selectedOccupationId,
    required this.onOccupationSelected,
    this.label = 'Occupation',
    this.hintText = 'Select Occupation',
    this.enabled = true,
    this.errorText,
  });

  @override
  State<OccupationDropdown> createState() => _OccupationDropdownState();
}

class _OccupationDropdownState extends State<OccupationDropdown> {
  List<Datum> _occupations = [];
  List<Datum> _filteredOccupations = [];
  Datum? _selectedOccupation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOccupations();
  }

  Future<void> _loadOccupations() async {
    try {
      final data = await BseOccupationOptionsService.getOccupationOptionsList();

      if (data != null && data.isNotEmpty) {
        _occupations = data;
        _filteredOccupations = List.from(_occupations);

        // Set selected occupation if provided
        if (widget.selectedOccupationId != null) {
          _selectedOccupation = _occupations.firstWhere(
            (occupation) => occupation.id == widget.selectedOccupationId,
            orElse: () => _occupations.first,
          );
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showOccupationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCardBG,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Handle bar
                  ExcludeSemantics(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.darkTextGray,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Semantics(
                    header: true,
                    child: AppText(
                      'Select Occupation',
                      variant: AppTextVariant.headline4,
                      weight: AppTextWeight.bold,
                      colorType: AppTextColorType.primary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search field
                  Semantics(
                    label: 'Search occupations',
                    textField: true,
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search occupations...',
                        hintStyle: TextStyle(color: AppColors.darkTextGray),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.darkTextGray,
                        ),
                        filled: true,
                        fillColor: AppColors.darkInputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          if (value.isEmpty) {
                            _filteredOccupations = List.from(_occupations);
                          } else {
                            _filteredOccupations =
                                _occupations
                                    .where(
                                      (occupation) => occupation.name
                                          .toLowerCase()
                                          .contains(value.toLowerCase()),
                                    )
                                    .toList();
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Occupations list
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredOccupations.length,
                      itemBuilder: (context, index) {
                        final occupation = _filteredOccupations[index];
                        final isSelected =
                            _selectedOccupation?.id == occupation.id;

                        return Semantics(
                          selected: isSelected,
                          label: occupation.name,
                          onTap: () {
                            setState(() {
                              _selectedOccupation = occupation;
                            });
                            widget.onOccupationSelected(occupation);
                            Navigator.pop(context);
                          },
                          excludeSemantics: true,
                          child: ListTile(
                            onTap: () {
                              setState(() {
                                _selectedOccupation = occupation;
                              });
                              widget.onOccupationSelected(occupation);
                              Navigator.pop(context);
                            },
                            title: AppText(
                              occupation.name,
                              variant: AppTextVariant.bodyMedium,
                              colorType: AppTextColorType.primary,
                            ),
                            trailing:
                                isSelected
                                    ? Icon(
                                      Icons.check_circle,
                                      color: AppColors.success,
                                    )
                                    : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void didUpdateWidget(OccupationDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedOccupationId != oldWidget.selectedOccupationId) {
      if (widget.selectedOccupationId == null) {
        setState(() {
          _selectedOccupation = null;
        });
      } else if (_occupations.isNotEmpty) {
        setState(() {
          _selectedOccupation = _occupations.firstWhere(
            (o) => o.id == widget.selectedOccupationId,
            orElse: () => _selectedOccupation ?? _occupations.first,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            widget.label,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.medium,
            colorType: AppTextColorType.primary,
          ),
          const SizedBox(height: 8),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.darkInputBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          widget.label,
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
          colorType: AppTextColorType.primary,
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Select ${widget.label}',
          hint: 'Opens occupation selection sheet',
          value: _selectedOccupation?.name ?? 'Not selected',
          child: GestureDetector(
            onTap: widget.enabled ? _showOccupationPicker : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.darkInputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.errorText != null
                      ? AppColors.error
                      : widget.enabled
                          ? AppColors.darkInputBorder
                          : AppColors.darkInputBorder.withOpacity(0.5),
                  width: widget.errorText != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppText(
                      _selectedOccupation?.name ?? widget.hintText,
                      variant: AppTextVariant.bodyMedium,
                      colorType:
                          _selectedOccupation != null
                              ? AppTextColorType.primary
                              : AppTextColorType.gray,
                      customColor: widget.enabled ? null : Colors.grey,
                    ),
                  ),
                  if (widget.enabled)
                    ExcludeSemantics(
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.darkTextGray,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          AppText(
            widget.errorText!,
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.error,
          ),
        ],
      ],
    );
  }
}
