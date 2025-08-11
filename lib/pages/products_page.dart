import 'package:flutter/material.dart';
import '../models.dart';
import '../services/odoo_api.dart';

class ProductsPage extends StatefulWidget {
  final String parentName;
  final String? childName;

  const ProductsPage({
    super.key,
    required this.parentName,
    this.childName,
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<List<ProductItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = OdooApi.fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.childName ?? widget.parentName;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        backgroundColor: const Color(0xFFF6F8FB),
        body: FutureBuilder<List<ProductItem>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('فشل التحميل: ${snap.error}'));
            }

            final all = snap.data ?? [];
            final filtered = all.where((p) {
              final sameParent = p.parent == widget.parentName;
              if (widget.childName == null) return sameParent;
              return sameParent && (p.child == widget.childName);
            }).toList();

            if (filtered.isEmpty) {
              return const Center(child: Text('لا توجد عناصر لهذا التصنيف'));
            }

            final w = MediaQuery.sizeOf(context).width;
            int cols = 1;
            if (w >= 1200) cols = 4;
            else if (w >= 900) cols = 3;
            else if (w >= 600) cols = 2;

            return GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.86,
              ),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final m = filtered[i];

                // حل الصورة: لو راجعة من Odoo كباث يبدأ بـ "/" نضيف الدومين
                final raw = m.image;
                final img = (raw != null && raw.startsWith('/'))
                    ? '${OdooApi.baseUrl}$raw'
                    : raw;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Expanded(
                        child: (img == null || img.isEmpty)
                            ? const Icon(Icons.person_outline,
                                size: 72, color: Colors.grey)
                            : Image.network(
                                img,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_outline,
                                  size: 72,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(
                              m.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            if (m.categoryPath.isNotEmpty)
                              Text(
                                m.categoryPath,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('تفاصيل: ${m.name}')),
                                );
                              },
                              icon: const Icon(Icons.info_outline),
                              label: const Text('التفاصيل'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
