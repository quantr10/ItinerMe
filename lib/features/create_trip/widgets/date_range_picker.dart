import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import '../../../../core/theme/app_theme.dart';

class DateRangePicker extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime, DateTime) onSelect;

  const DateRangePicker({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        List<DateTime?> selectedDates = [startDate, endDate];

        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Select Date',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.largeFontSize,
                ),
              ),
              insetPadding: AppTheme.largePadding,
              content: SizedBox(
                height: 250,
                width: 350,
                child: CalendarDatePicker2(
                  config: CalendarDatePicker2Config(
                    calendarType: CalendarDatePicker2Type.range,
                    selectedDayHighlightColor: AppTheme.primaryColor,
                    centerAlignModePicker: true,
                    dayTextStyle: const TextStyle(
                      fontSize: AppTheme.defaultFontSize,
                    ),
                    weekdayLabelTextStyle: const TextStyle(
                      fontSize: AppTheme.defaultFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    controlsHeight: 50,
                    useAbbrLabelForMonthModePicker: true,
                    daySplashColor: Colors.transparent,
                    disabledDayTextStyle: const TextStyle(
                      color: AppTheme.hintColor,
                    ),
                    modePickersGap: 8,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  ),
                  value: selectedDates,
                  onValueChanged: (dates) {
                    selectedDates = dates;
                  },
                ),
              ),
              actions: [
                TextButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                    ),
                  ),
                  onPressed: () {
                    if (selectedDates.length == 2 &&
                        selectedDates[0] != null &&
                        selectedDates[1] != null) {
                      onSelect(selectedDates[0]!, selectedDates[1]!);
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
      child: AnimatedContainer(
        duration: AppTheme.animationDuration,
        height: AppTheme.fieldHeight,
        child: InputDecorator(
          decoration: AppTheme.inputDecoration(
            'Select Date',
            prefixIcon: const Icon(
              Icons.calendar_month,
              color: AppTheme.primaryColor,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child:
                    (startDate != null && endDate != null)
                        ? Text(
                          '${DateFormat('MMM d, yyyy').format(startDate!)} - '
                          '${DateFormat('MMM d, yyyy').format(endDate!)}',
                          style: const TextStyle(
                            fontSize: AppTheme.defaultFontSize,
                            color: Colors.black,
                          ),
                        )
                        : Text(
                          'Select Date',
                          style: TextStyle(
                            fontSize: AppTheme.defaultFontSize,
                            color: AppTheme.hintColor,
                          ),
                        ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: AppTheme.largeIconFont,
                color: AppTheme.hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
