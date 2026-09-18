import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/lead_activity_service.dart';

final leadActivityServiceProvider = Provider<LeadActivityService>((ref) {
  return LeadActivityService();
});
