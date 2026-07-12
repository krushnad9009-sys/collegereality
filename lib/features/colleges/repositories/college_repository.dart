import '../models/college_model.dart';
import '../services/firestore_college_service.dart';
import '../../../core/constants/college_constants.dart';

abstract class CollegeRepository {
  Future<List<CollegeModel>> getFeaturedColleges({int limit});
  Future<CollegeModel?> getCollegeById(String id);
  Future<List<CollegeModel>> getCollegesByIds(List<String> ids);
  Future<CollegeSearchPage> searchColleges({
    String? query,
    String? state,
    String? city,
    String? course,
    String? startAfterDocumentId,
    int limit,
    bool includeInactive,
  });
  Future<List<CollegeModel>> autocomplete(String query);
  Future<CollegeDirectoryMeta> getDirectoryMeta();
  Future<int> getCollegeCount({bool activeOnly});
  Future<void> createCollege(CollegeModel college);
  Future<void> updateCollege(CollegeModel college, {String? updatedBy});
  Future<void> setCollegeActive(String id, {required bool isActive});
}

class CollegeRepositoryImpl implements CollegeRepository {
  final FirestoreCollegeService _service;

  CollegeRepositoryImpl(this._service);

  @override
  Future<List<CollegeModel>> getFeaturedColleges({int limit = CollegeConstants.featuredLimit}) =>
      _service.getFeaturedColleges(limit: limit);

  @override
  Future<CollegeModel?> getCollegeById(String id) =>
      _service.getCollegeById(id);

  @override
  Future<List<CollegeModel>> getCollegesByIds(List<String> ids) =>
      _service.getCollegesByIds(ids);

  @override
  Future<CollegeSearchPage> searchColleges({
    String? query,
    String? state,
    String? city,
    String? course,
    String? startAfterDocumentId,
    int limit = 24,
    bool includeInactive = false,
  }) {
    return _service.searchColleges(
      query: query,
      state: state,
      city: city,
      course: course,
      startAfterDocumentId: startAfterDocumentId,
      limit: limit,
      includeInactive: includeInactive,
    );
  }

  @override
  Future<List<CollegeModel>> autocomplete(String query) =>
      _service.autocompleteColleges(query);

  @override
  Future<CollegeDirectoryMeta> getDirectoryMeta() =>
      _service.getDirectoryMeta();

  @override
  Future<int> getCollegeCount({bool activeOnly = true}) =>
      _service.getCollegeCount(activeOnly: activeOnly);

  @override
  Future<void> createCollege(CollegeModel college) =>
      _service.createCollege(college);

  @override
  Future<void> updateCollege(CollegeModel college, {String? updatedBy}) =>
      _service.updateCollege(college, updatedBy: updatedBy);

  @override
  Future<void> setCollegeActive(String id, {required bool isActive}) =>
      _service.setCollegeActive(id, isActive: isActive);
}
