class JobFilters {
  final String? categoryId;
  final String? q;
  final double? minPrice;
  final double? maxPrice;
  final String sort;

  const JobFilters({
    this.categoryId,
    this.q,
    this.minPrice,
    this.maxPrice,
    this.sort = 'date_desc',
  });

  JobFilters copyWith({
    String? categoryId,
    String? q,
    double? minPrice,
    double? maxPrice,
    String? sort,
    bool clearCategory = false,
    bool clearSearch = false,
  }) {
    return JobFilters(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      q: clearSearch ? null : (q ?? this.q),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sort: sort ?? this.sort,
    );
  }

  Map<String, dynamic> toQueryParams() {
    return {
      if (categoryId != null) 'categoryId': categoryId,
      if (q != null && q!.isNotEmpty) 'q': q,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      'sort': sort,
    };
  }

  bool get hasActiveFilters =>
      categoryId != null || (q != null && q!.isNotEmpty) || minPrice != null || maxPrice != null;
}
