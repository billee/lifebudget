import '../constants/app_strings.dart';

String getStatusLine(double percentageUsed) {
  if (percentageUsed <= 0.7) return AppStrings.statusOnTrack;
  if (percentageUsed <= 0.9) return AppStrings.statusTight;
  return AppStrings.statusCritical;
}

String getJarStatusLabel(double percentageUsed) {
  if (percentageUsed <= 0.5) return AppStrings.jarOK;
  if (percentageUsed <= 0.75) return AppStrings.jarCovered;
  if (percentageUsed <= 0.9) return AppStrings.jarWatch;
  return AppStrings.jarLow;
}
