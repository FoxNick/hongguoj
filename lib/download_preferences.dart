class DownloadPreferences {
  const DownloadPreferences({
    this.quality = 0,
    this.includeVip = false,
    this.mergeH264 = true,
  });
  static const qualities = [0, 1080, 720, 480];
  final int quality;
  final bool includeVip;
  final bool mergeH264;
  String get qualityLabel => quality == 0 ? '自动 · 优先高清' : '${quality}P';

  DownloadPreferences copyWith({
    int? quality,
    bool? includeVip,
    bool? mergeH264,
  }) => DownloadPreferences(
    quality: quality ?? this.quality,
    includeVip: includeVip ?? this.includeVip,
    mergeH264: mergeH264 ?? this.mergeH264,
  );

  factory DownloadPreferences.fromJson(Map<String, dynamic> json) {
    final quality = json['quality'] ?? 0;
    final includeVip = json['includeVip'] ?? false;
    final mergeH264 = json['mergeH264'] ?? true;
    if (quality is! int ||
        !qualities.contains(quality) ||
        includeVip is! bool ||
        mergeH264 is! bool) {
      throw const FormatException('下载偏好无效');
    }
    return DownloadPreferences(
      quality: quality,
      includeVip: includeVip,
      mergeH264: mergeH264,
    );
  }

  Map<String, dynamic> toJson() => {
    'quality': quality,
    'includeVip': includeVip,
    'mergeH264': mergeH264,
  };
}
