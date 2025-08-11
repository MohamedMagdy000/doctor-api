class CatChild {
  final int id;
  final String name;
  final String completeName;

  CatChild({
    required this.id,
    required this.name,
    required this.completeName,
  });

  factory CatChild.fromMap(Map<String, dynamic> m) => CatChild(
        id: (m['id'] as num).toInt(),
        name: (m['name'] ?? '').toString(),
        completeName: (m['complete_name'] ?? '').toString(),
      );
}

class CatParent {
  final int id;
  final String name;
  final String completeName;
  final List<CatChild> children;

  CatParent({
    required this.id,
    required this.name,
    required this.completeName,
    required this.children,
  });

  factory CatParent.fromMap(Map<String, dynamic> m) => CatParent(
        id: (m['id'] as num).toInt(),
        name: (m['name'] ?? '').toString(),
        completeName: (m['complete_name'] ?? '').toString(),
        children: ((m['children'] ?? []) as List)
            .map((e) => CatChild.fromMap((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class ProductItem {
  final int id;
  final String name;
  final String parent;       // اسم الأب
  final String? child;       // اسم الابن (قد يكون null)
  final String categoryPath; // المسار الكامل "All / Doctor"
  final String? image;       // رابط الصورة

  ProductItem({
    required this.id,
    required this.name,
    required this.parent,
    required this.child,
    required this.categoryPath,
    required this.image,
  });

  factory ProductItem.fromMap(Map<String, dynamic> m) {
    // fallback لو الـ API ما رجعش parent/child
    String path = (m['category_path'] ?? m['category'] ?? '').toString();
    String parent = (m['parent'] ?? '').toString();
    String? child = m['child']?.toString();

    if (parent.isEmpty) {
      final parts = path
          .split('/')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) parent = parts.first;
      if (parts.length >= 2) child ??= parts[1];
    }

    return ProductItem(
      id: (m['id'] as num?)?.toInt() ?? 0,
      name: (m['name'] ?? '').toString(),
      parent: parent,
      child: child,
      categoryPath: path,
      image: (m['image'] ?? m['image_url'] ?? m['image_1920_url'])?.toString(),
    );
  }
}
