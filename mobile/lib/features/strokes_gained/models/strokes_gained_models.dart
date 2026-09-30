class StrokesGainedCategoryModel {
  final String category;
  final int shotsCount;
  final double? strokesGained;
  final String status;

  const StrokesGainedCategoryModel({
    required this.category,
    required this.shotsCount,
    this.strokesGained,
    required this.status,
  });

  factory StrokesGainedCategoryModel.fromJson(Map<String, dynamic> json) {
    return StrokesGainedCategoryModel(
      category: json['category'] as String? ?? 'UNKNOWN',
      shotsCount: json['shotsCount'] as int? ?? 0,
      strokesGained: (json['strokesGained'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'UNAVAILABLE',
    );
  }
}

class StrokesGainedSummaryModel {
  final String status;
  final double? totalStrokesGained;
  final Map<String, StrokesGainedCategoryModel> categories;
  final String message;

  const StrokesGainedSummaryModel({
    required this.status,
    this.totalStrokesGained,
    required this.categories,
    required this.message,
  });

  bool get isAvailable => status == 'AVAILABLE' && totalStrokesGained != null;

  factory StrokesGainedSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categories'] as Map<String, dynamic>? ?? {};
    final parsedCats = <String, StrokesGainedCategoryModel>{};

    for (final entry in rawCats.entries) {
      if (entry.value is Map<String, dynamic>) {
        parsedCats[entry.key] = StrokesGainedCategoryModel.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }

    return StrokesGainedSummaryModel(
      status: json['status'] as String? ?? 'UNAVAILABLE',
      totalStrokesGained: (json['totalStrokesGained'] as num?)?.toDouble(),
      categories: parsedCats,
      message: json['message'] as String? ?? 'Strokes Gained data unavailable',
    );
  }
}
