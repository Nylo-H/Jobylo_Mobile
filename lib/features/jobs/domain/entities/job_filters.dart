class JobFilters {
  final String? categoryId;
  final String? location;
  final String? q;
  final double? minPrice;
  final double? maxPrice;
  final String sort;

  const JobFilters({
    this.categoryId,
    this.location,
    this.q,
    this.minPrice,
    this.maxPrice,
    this.sort = 'date_desc',
  });

  JobFilters copyWith({
    String? categoryId,
    String? location,
    String? q,
    double? minPrice,
    double? maxPrice,
    String? sort,
    bool clearCategory = false,
    bool clearLocation = false,
    bool clearSearch = false,
    bool clearPrice = false,
  }) {
    return JobFilters(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      location: clearLocation ? null : (location ?? this.location),
      q: clearSearch ? null : (q ?? this.q),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      sort: sort ?? this.sort,
    );
  }

  Map<String, dynamic> toQueryParams() {
    return {
      if (categoryId != null) 'categoryId': categoryId,
      if (location != null && location!.isNotEmpty) 'location': location,
      if (q != null && q!.isNotEmpty) 'q': q,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      'sort': sort,
    };
  }

  bool get hasActiveFilters =>
      categoryId != null ||
      (location != null && location!.isNotEmpty) ||
      (q != null && q!.isNotEmpty) ||
      minPrice != null ||
      maxPrice != null;

  int get activeFilterCount {
    int count = 0;
    if (categoryId != null) count++;
    if (location != null && location!.isNotEmpty) count++;
    if (q != null && q!.isNotEmpty) count++;
    if (minPrice != null || maxPrice != null) count++;
    return count;
  }
}
