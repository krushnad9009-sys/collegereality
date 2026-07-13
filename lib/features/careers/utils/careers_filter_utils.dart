import '../models/careers_models.dart';

String buildCareersSearchText(List<String> parts) {
  return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).join(' ').toLowerCase();
}

bool matchesCareersSearch(String searchText, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return searchText.contains(q);
}

List<InternshipModel> filterInternships({
  required List<InternshipModel> items,
  required String searchQuery,
  String? city,
  String? company,
  String? payType,
}) {
  return items.where((i) {
    if (!i.isActive) return false;
    if (!matchesCareersSearch(i.searchText, searchQuery)) return false;
    if (city != null && city.isNotEmpty && i.city.toLowerCase() != city.toLowerCase()) {
      return false;
    }
    if (company != null &&
        company.isNotEmpty &&
        !i.companyName.toLowerCase().contains(company.toLowerCase())) {
      return false;
    }
    if (payType != null && payType.isNotEmpty && i.payType != payType) return false;
    return true;
  }).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

List<JobModel> filterJobs({
  required List<JobModel> items,
  required String searchQuery,
  String? location,
  String? jobLevel,
  String? workType,
  double? minSalaryLpa,
}) {
  return items.where((j) {
    if (!j.isActive) return false;
    if (!matchesCareersSearch(j.searchText, searchQuery)) return false;
    if (location != null &&
        location.isNotEmpty &&
        !j.location.toLowerCase().contains(location.toLowerCase())) {
      return false;
    }
    if (jobLevel != null && jobLevel.isNotEmpty && j.jobLevel != jobLevel) return false;
    if (workType != null && workType.isNotEmpty && j.workType != workType) return false;
    if (minSalaryLpa != null && j.salaryMaxLpa > 0 && j.salaryMaxLpa < minSalaryLpa) {
      return false;
    }
    return true;
  }).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

List<CompanyModel> filterCompanies({
  required List<CompanyModel> items,
  required String searchQuery,
}) {
  return items
      .where((c) => c.isActive && matchesCareersSearch(c.searchText, searchQuery))
      .toList()
    ..sort((a, b) => b.rating.compareTo(a.rating));
}

List<AlumniProfileModel> filterAlumni({
  required List<AlumniProfileModel> items,
  required String searchQuery,
  String? company,
  String? location,
}) {
  return items.where((a) {
    if (!a.isActive) return false;
    if (!matchesCareersSearch(a.searchText, searchQuery)) return false;
    if (company != null &&
        company.isNotEmpty &&
        !a.company.toLowerCase().contains(company.toLowerCase())) {
      return false;
    }
    if (location != null &&
        location.isNotEmpty &&
        !a.location.toLowerCase().contains(location.toLowerCase())) {
      return false;
    }
    return true;
  }).toList()
    ..sort((a, b) => b.batchYear.compareTo(a.batchYear));
}
