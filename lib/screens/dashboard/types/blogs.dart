class BlogResponse {
  int statusCode;
  String message;
  BlogData data;
  bool get success => statusCode == 200 || statusCode == 201;

  BlogResponse({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory BlogResponse.fromJson(Map<String, dynamic> json) => BlogResponse(
    statusCode: json["statusCode"],
    message: json["message"],
    data: BlogData.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data.toJson(),
  };
}

class BlogData {
  List<BlogItem> blogs;

  BlogData({required this.blogs});

  factory BlogData.fromJson(Map<String, dynamic> json) => BlogData(
    blogs: List<BlogItem>.from(json["blogs"].map((x) => BlogItem.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "blogs": List<dynamic>.from(blogs.map((x) => x.toJson())),
  };
}

class BlogItem {
  int id;
  String slug;
  String title;
  String summary;
  String imageUrl;
  List<String> tags;
  String redirectUrl;

  BlogItem({
    required this.id,
    required this.slug,
    required this.title,
    required this.summary,
    required this.imageUrl,
    required this.tags,
    required this.redirectUrl,
  });

  factory BlogItem.fromJson(Map<String, dynamic> json) => BlogItem(
    id: json["id"] ?? 0,
    slug: json["slug"] ?? "",
    title: json["title"] ?? "",
    summary: json["summary"] ?? "",
    imageUrl: json["image_url"] ?? "",
    tags: List<String>.from(json["tags"]?.map((x) => x) ?? []),
    redirectUrl: json["redirect_url"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "slug": slug,
    "title": title,
    "summary": summary,
    "image_url": imageUrl,
    "tags": List<dynamic>.from(tags.map((x) => x)),
    "redirect_url": redirectUrl,
  };
}
