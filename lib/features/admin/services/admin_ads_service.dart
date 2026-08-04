import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_constants.dart';
import 'admin_action_logger.dart';

class AdminAdModel {
  final String id;
  final String title;
  final String body;
  final String imageUrl;
  final String ctaLabel;
  final String ctaUrl;
  final bool isActive;
  final int priority;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime updatedAt;

  const AdminAdModel({
    required this.id,
    required this.title,
    this.body = '',
    this.imageUrl = '',
    this.ctaLabel = 'Learn more',
    this.ctaUrl = '',
    this.isActive = true,
    this.priority = 0,
    this.startsAt,
    this.endsAt,
    required this.updatedAt,
  });

  factory AdminAdModel.fromJson(Map<String, dynamic> json, {required String id}) {
    return AdminAdModel(
      id: id,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      ctaLabel: json['ctaLabel']?.toString() ?? 'Learn more',
      ctaUrl: json['ctaUrl']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? true,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      startsAt: DateTime.tryParse(json['startsAt']?.toString() ?? ''),
      endsAt: DateTime.tryParse(json['endsAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'ctaLabel': ctaLabel,
        'ctaUrl': ctaUrl,
        'isActive': isActive,
        'priority': priority,
        if (startsAt != null) 'startsAt': startsAt!.toIso8601String(),
        if (endsAt != null) 'endsAt': endsAt!.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  bool get isCurrentlyLive {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (endsAt != null && now.isAfter(endsAt!)) return false;
    return true;
  }
}

class AdminAdsService {
  AdminAdsService({
    FirebaseFirestore? firestore,
    AdminActionLogger? logger,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _logger = logger ?? AdminActionLogger();

  final FirebaseFirestore _firestore;
  final AdminActionLogger _logger;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _ads =>
      _firestore.collection(FirestoreConstants.adminAdsCollection);

  Future<List<AdminAdModel>> listAds() async {
    final snap = await _ads.orderBy('priority', descending: true).get();
    return snap.docs
        .map((d) => AdminAdModel.fromJson(d.data(), id: d.id))
        .toList();
  }

  Future<List<AdminAdModel>> listActiveAds() async {
    final all = await listAds();
    return all.where((a) => a.isCurrentlyLive).toList();
  }

  Future<void> upsertAd(AdminAdModel ad) async {
    final id = ad.id.isEmpty ? _uuid.v4() : ad.id;
    final payload = ad.copyWith(id: id, updatedAt: DateTime.now());
    await _ads.doc(id).set(payload.toJson(), SetOptions(merge: true));
    await _logger.log(
      action: 'ad.upsert',
      targetId: id,
      targetType: 'admin_ad',
      metadata: {'title': payload.title, 'isActive': payload.isActive},
    );
  }

  Future<void> deleteAd(String id) async {
    await _ads.doc(id).delete();
    await _logger.log(
      action: 'ad.delete',
      targetId: id,
      targetType: 'admin_ad',
    );
  }
}

extension on AdminAdModel {
  AdminAdModel copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    String? ctaLabel,
    String? ctaUrl,
    bool? isActive,
    int? priority,
    DateTime? startsAt,
    DateTime? endsAt,
    DateTime? updatedAt,
  }) {
    return AdminAdModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      ctaLabel: ctaLabel ?? this.ctaLabel,
      ctaUrl: ctaUrl ?? this.ctaUrl,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

final adminAdsServiceProvider = Provider<AdminAdsService>((ref) {
  return AdminAdsService(logger: ref.watch(adminActionLoggerProvider));
});

final adminAdsProvider = FutureProvider<List<AdminAdModel>>((ref) async {
  return ref.watch(adminAdsServiceProvider).listAds();
});

final activeHomeAdsProvider = FutureProvider<List<AdminAdModel>>((ref) async {
  try {
    return await ref.watch(adminAdsServiceProvider).listActiveAds();
  } catch (_) {
    return const [];
  }
});
