import 'package:intl/intl.dart';

String formatTimestampToTime(String timestamp) {
  DateTime dateTime = DateTime.parse(timestamp);
  String formattedTime = DateFormat.Hm()
      .format(dateTime); // Hm for 24-hour format, 'h:mm a' for 12-hour format
  return formattedTime;
}
