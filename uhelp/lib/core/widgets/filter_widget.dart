import 'package:flutter/material.dart';

class FilterOption<T> {
  final String label;
  final T value;

  FilterOption({required this.label, required this.value});
}

class FilterWidget<T> extends StatelessWidget {
  final List<FilterOption<T>> options;
  final T? selectedValue;
  final Function(T?) onChanged;
  final String label;
  final bool includeAllOption;

  const FilterWidget({
    Key? key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    required this.label,
    this.includeAllOption = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (includeAllOption)
                _buildFilterChip(
                  context,
                  label: 'Todo',
                  selected: selectedValue == null,
                  onSelected: (selected) {
                    if (selected) {
                      onChanged(null);
                    }
                  },
                ),
              ...options.map((option) => _buildFilterChip(
                    context,
                    label: option.label,
                    selected: selectedValue == option.value,
                    onSelected: (selected) {
                      if (selected) {
                        onChanged(option.value);
                      } else if (selectedValue == option.value) {
                        onChanged(null);
                      }
                    },
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: selected ? Theme.of(context).primaryColor : Colors.black,
        ),
      ),
    );
  }
}