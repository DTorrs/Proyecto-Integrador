class PaginatedData<T> {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final List<T> data;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginatedData({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
    required this.data,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
  });

  factory PaginatedData.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    final List<dynamic> dataList = json['data'] ?? [];
    
    return PaginatedData(
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
      data: dataList.map((item) => fromJson(item)).toList(),
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
    );
  }
}