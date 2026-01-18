import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/trip.dart';
import '../controller/trip_detail_controller.dart';

// DATE RANGE DIALOG
Future<bool?> showDateRangeDialog(
  BuildContext context,
  Trip trip,
  TripDetailController controller,
) {
  List<DateTime?> selectedDates = [trip.startDate, trip.endDate];

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,

        // ===== TITLE =====
        title: const Text(
          'Select Date',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppTheme.largeFontSize,
          ),
        ),

        insetPadding: AppTheme.largePadding,

        // ===== CALENDAR =====
        content: SizedBox(
          height: 250,
          width: 350,
          child: CalendarDatePicker2(
            config: CalendarDatePicker2Config(
              calendarType: CalendarDatePicker2Type.range,
              selectedDayHighlightColor: AppTheme.primaryColor,
              centerAlignModePicker: true,
              dayTextStyle: const TextStyle(fontSize: AppTheme.defaultFontSize),
              weekdayLabelTextStyle: const TextStyle(
                fontSize: AppTheme.defaultFontSize,
                fontWeight: FontWeight.bold,
              ),
              controlsHeight: 50,
              useAbbrLabelForMonthModePicker: true,
              daySplashColor: Colors.transparent,
              disabledDayTextStyle: const TextStyle(color: AppTheme.hintColor),
              modePickersGap: 8,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            ),
            value: selectedDates,
            onValueChanged: (dates) {
              selectedDates = dates;
            },
          ),
        ),

        // ===== ACTIONS =====
        actions: [
          AppTheme.dialogCancelButton(dialogContext),

          AppTheme.dialogPrimaryButton(
            context: dialogContext,
            label: 'Save',
            onPressed: () async {
              if (selectedDates.length == 2 &&
                  selectedDates[0] != null &&
                  selectedDates[1] != null) {
                final start = DateTime(
                  selectedDates[0]!.year,
                  selectedDates[0]!.month,
                  selectedDates[0]!.day,
                );

                final end = DateTime(
                  selectedDates[1]!.year,
                  selectedDates[1]!.month,
                  selectedDates[1]!.day,
                  23,
                  59,
                );

                final ok = await controller.changeDateRange(start, end);
                Navigator.pop(dialogContext, ok);
              } else {
                Navigator.pop(dialogContext, false);
              }
            },
          ),
        ],
      );
    },
  );
}
