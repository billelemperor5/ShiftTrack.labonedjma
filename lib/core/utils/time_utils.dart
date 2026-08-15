String formatDuration(double hours) {
  int h = hours.floor();
  int m = ((hours - h) * 60).round();

  // Handle case where rounding might result in 60 minutes
  if (m == 60) {
    h += 1;
    m = 0;
  }

  String hh = h.toString().padLeft(2, '0');
  String mm = m.toString().padLeft(2, '0');

  return '$hh:$mm h';
}
