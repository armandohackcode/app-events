import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Small calendar sheet: the month in a red band and the day number below.
class CalendarBadge extends StatelessWidget {
  final DateTime date;
  const CalendarBadge({super.key, required this.date});

  static const double _width = 46;
  static const double _height = 52;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      height: _height,
      decoration: BoxDecoration(
        color: AppStyles.cardColor,
        border: Border.all(color: AppStyles.borderColor, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppStyles.colorBaseRed,
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                DateFormat.MMM('es').format(date).toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppStyles.onAccentColor,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${date.day}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: AppStyles.fontColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
