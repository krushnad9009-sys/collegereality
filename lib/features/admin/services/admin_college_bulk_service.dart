import '../../../core/constants/admin_constants.dart';
import '../../colleges/models/college_model.dart';
import '../../colleges/utils/college_search_utils.dart';

class AdminCollegeBulkService {
  List<Map<String, String>> parseCsv(String raw) {
    final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return [];

    final headers = _splitCsvLine(lines.first).map((h) => h.trim().toLowerCase()).toList();
    final rows = <Map<String, String>>[];

    for (var i = 1; i < lines.length; i++) {
      final values = _splitCsvLine(lines[i]);
      final row = <String, String>{};
      for (var j = 0; j < headers.length && j < values.length; j++) {
        row[headers[j]] = values[j].trim();
      }
      rows.add(row);
    }
    return rows;
  }

  List<String> parseImageUrls(String raw) {
    return raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.startsWith('http'))
        .toList();
  }

  CollegeModel collegeFromCsvRow(Map<String, String> row, {String? id}) {
    final name = row['name']?.trim() ?? '';
    final city = row['city']?.trim() ?? '';
    final state = row['state']?.trim() ?? '';
    final collegeId = id ?? row['id']?.trim() ?? DateTime.now().microsecondsSinceEpoch.toString();

    return CollegeModel(
      id: collegeId,
      name: name,
      nameLower: CollegeSearchUtils.normalizeName(name),
      slug: CollegeSearchUtils.buildSlug(name, city),
      city: city,
      state: state,
      address: row['address']?.trim() ?? '',
      type: row['type']?.trim() ?? 'private',
      courses: (row['courses'] ?? '')
          .split(';')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      website: row['website']?.trim(),
      logoUrl: row['logourl']?.trim() ?? row['logo_url']?.trim(),
      coverPhotoUrl: row['coverphotourl']?.trim() ?? row['cover_photo_url']?.trim(),
      fees: CollegeFees(
        tuitionMin: int.tryParse(row['tuitionmin'] ?? row['tuition_min'] ?? '') ?? 0,
        tuitionMax: int.tryParse(row['tuitionmax'] ?? row['tuition_max'] ?? '') ?? 0,
        hostelAnnual: int.tryParse(row['hostelfee'] ?? row['hostel_fee'] ?? '') ?? 0,
      ),
      placements: const CollegePlacements(
        highestPackageLpa: 0,
        averagePackageLpa: 0,
        placementPercentage: 0,
      ),
      aggregatedRatings: const CollegeRatings(
        overall: 0,
        faculty: 0,
        infrastructure: 0,
        placements: 0,
        campusLife: 0,
      ),
      isActive: row['isactive']?.trim().toLowerCase() != 'false',
      adminNotes: row['approvalstatus']?.trim() == 'pending'
          ? AdminConstants.reportStatusOpen
          : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }
}
