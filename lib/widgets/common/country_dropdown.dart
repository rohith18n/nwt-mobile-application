import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/models/country.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class CountryDropdown extends StatefulWidget {
  final String? selectedCountryCode;
  final Function(Country) onCountrySelected;
  final String label;
  final String hintText;
  final Map<String, String>? phoneCodeMap;
  final String? errorText;
  final bool enabled;

  const CountryDropdown({
    super.key,
    this.selectedCountryCode,
    required this.onCountrySelected,
    this.label = 'Country',
    this.hintText = 'Select Country',
    this.phoneCodeMap,
    this.errorText,
    this.enabled = true,
  });

  @override
  State<CountryDropdown> createState() => _CountryDropdownState();
}

class _CountryDropdownState extends State<CountryDropdown> {
  List<Country> _countries = [];
  List<Country> _filteredCountries = [];
  Country? _selectedCountry;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/countries_iso3.json',
      );
      final Map<String, dynamic> data = json.decode(response);

      _countries =
          data.entries
              .map((entry) => Country.fromJson(entry.key, entry.value))
              .toList();

      // Sort countries alphabetically by name
      _countries.sort((a, b) => a.name.compareTo(b.name));
      _filteredCountries = List.from(_countries);

      // Set selected country if provided
      if (widget.selectedCountryCode != null) {
        _selectedCountry = _countries.firstWhere(
          (country) => country.code == widget.selectedCountryCode,
          orElse: () => _countries.first, // Default fallback
        );
      } else if (widget.phoneCodeMap != null) {
        // If phone map is provided, default to IND if possible
        _selectedCountry = _countries.firstWhere(
          (country) => country.code == 'IND',
          orElse: () => _countries.first,
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCountryPicker() {
    setState(() {
      _filteredCountries = List.from(_countries);
    });
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
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.darkTextGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Semantics(
                    header: true,
                    child: AppText(
                      'Select Country',
                      variant: AppTextVariant.headline4,
                      weight: AppTextWeight.bold,
                      colorType: AppTextColorType.primary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search field
                  Semantics(
                    textField: true,
                    label: 'Search countries',
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search countries...',
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
                            _filteredCountries = List.from(_countries);
                          } else {
                            _filteredCountries =
                                _countries
                                    .where(
                                      (country) =>
                                          country.name.toLowerCase().contains(
                                            value.toLowerCase(),
                                          ) ||
                                          country.code.toLowerCase().contains(
                                            value.toLowerCase(),
                                          ),
                                    )
                                    .toList();
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Countries list
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = _filteredCountries[index];
                        final isSelected =
                            _selectedCountry?.code == country.code;

                        return Semantics(
                          selected: isSelected,
                          label: country.name,
                          onTap: () {
                            setState(() {
                              _selectedCountry = country;
                            });
                            widget.onCountrySelected(country);
                            Navigator.pop(context);
                          },
                          excludeSemantics: true,
                          child: ListTile(
                            onTap: () {
                              setState(() {
                                _selectedCountry = country;
                              });
                              widget.onCountrySelected(country);
                              Navigator.pop(context);
                            },
                            title: AppText(
                              country.name,
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

  String _getDisplayValue() {
    if (_selectedCountry == null) return widget.hintText;
    if (widget.phoneCodeMap != null) {
      final phoneCode = widget.phoneCodeMap![_selectedCountry!.code];
      if (phoneCode != null) {
        return "+$phoneCode";
      }
    }
    return _selectedCountry!.name;
  }

  @override
  void didUpdateWidget(CountryDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCountryCode != oldWidget.selectedCountryCode) {
      if (widget.selectedCountryCode == null) {
        setState(() {
          _selectedCountry = null;
        });
      } else if (_countries.isNotEmpty) {
        setState(() {
          _selectedCountry = _countries.firstWhere(
            (c) => c.code == widget.selectedCountryCode,
            orElse: () => _selectedCountry ?? _countries.first,
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
        GestureDetector(
          onTap: widget.enabled ? _showCountryPicker : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.darkInputBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    widget.enabled
                        ? AppColors.darkInputBorder
                        : AppColors.darkInputBorder.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppText(
                    _getDisplayValue(),
                    variant: AppTextVariant.bodyMedium,
                    colorType:
                        _selectedCountry != null
                            ? AppTextColorType.primary
                            : AppTextColorType.gray,
                    customColor: widget.enabled ? null : Colors.grey,
                  ),
                ),
                if (widget.enabled)
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.darkTextGray,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
        if (widget.errorText != null && widget.errorText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: AppText(
              widget.errorText!,
              variant: AppTextVariant.bodySmall,
              customColor: Colors.redAccent,
              weight: AppTextWeight.medium,
            ),
          ),
        ],
      ],
    );
  }
}
