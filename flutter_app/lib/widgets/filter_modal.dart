import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';

class FilterModal extends StatefulWidget {
  final bool initialLight;
  final bool initialFast;
  final bool initialLong;
  final Function(bool light, bool fast, bool long) onApply;

  const FilterModal({
    required this.initialLight,
    required this.initialFast,
    required this.initialLong,
    required this.onApply,
    Key? key,
  }) : super(key: key);

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late bool filterLight;
  late bool filterFast;
  late bool filterLong;

  @override
  void initState() {
    super.initState();
    filterLight = widget.initialLight;
    filterFast = widget.initialFast;
    filterLong = widget.initialLong;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.darkBgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardCornerRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              'Filter Recipes',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            SizedBox(height: AppConstants.defaultPadding),
            Divider(color: AppTheme.textMuted, height: 1),
            SizedBox(height: AppConstants.defaultPadding),

            // Calorie filter
            _buildFilterOption(
              context,
              icon: '🔥',
              title: 'Light',
              subtitle: '≤ 500 kcal',
              value: filterLight,
              onChanged: (value) {
                setState(() => filterLight = value);
              },
            ),
            SizedBox(height: AppConstants.defaultPadding),

            // Time filters
            Text(
              'Cooking Time',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.textLight,
                  ),
            ),
            SizedBox(height: AppConstants.smallPadding),

            _buildFilterOption(
              context,
              icon: '⚡',
              title: 'Fast',
              subtitle: '≤ 25 min',
              value: filterFast,
              onChanged: (value) {
                setState(() {
                  filterFast = value;
                  if (value) filterLong = false;
                });
              },
            ),
            SizedBox(height: AppConstants.smallPadding),

            _buildFilterOption(
              context,
              icon: '🍳',
              title: 'Long',
              subtitle: '≥ 60 min',
              value: filterLong,
              onChanged: (value) {
                setState(() {
                  filterLong = value;
                  if (value) filterFast = false;
                });
              },
            ),
            SizedBox(height: AppConstants.defaultPadding * 1.5),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        filterLight = false;
                        filterFast = false;
                        filterLong = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.warning,
                      side: BorderSide(color: AppTheme.warning),
                    ),
                    child: Text('Clear'),
                  ),
                ),
                SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(filterLight, filterFast, filterLong);
                      Navigator.pop(context);
                    },
                    child: Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppConstants.smallPadding,
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (newValue) => onChanged(newValue ?? false),
            ),
            SizedBox(width: AppConstants.smallPadding),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(icon, style: TextStyle(fontSize: 16)),
                    SizedBox(width: 4),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}