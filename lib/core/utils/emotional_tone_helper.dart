import '../constants/app_strings.dart';

String getStatusLine(double percentageUsed) {
  if (percentageUsed <= 0.7) return AppStrings.statusOnTrack;
  if (percentageUsed <= 0.9) return AppStrings.statusTight;
  return AppStrings.statusCritical;
}

String getJarStatusLabel(double percentageUsed) {
  if (percentageUsed >= 1.0) return 'Covered';
  if (percentageUsed > 0.9) return 'Low';
  if (percentageUsed > 0.75) return 'Watch this';
  if (percentageUsed > 0.5) return 'OK';
  return 'Good';
}
