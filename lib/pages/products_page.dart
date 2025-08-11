// lib/pages/products_page.dart
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

  // فلاتر
  String _query = '';
  String? _city;

  @override
  void initState() {
    super.initState();
    _future = OdooApi.fetchProducts();
  }

  // فلترة حسب (الأب/الابن) + الاسم + المدينة
  List<ProductItem> _applyFilters(List<ProductItem> all) {
    final base = all.where((p) {
      final sameParent = p.parent == widget.parentName;
      if (widget.childName == null) return sameParent;
      return sameParent && (p.child == widget.childName);
    });

    return base.where((p) {
      final byName = _query.isEmpty ||
          p.name.toLowerCase().contains(_query.toLowerCase());
      final byCity = _city == null || _city!.isEmpty || p.city == _city;
      return byName && byCity;
    }).toList();
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

            // مدن متاحة لهذا التصنيف فقط
            final baseForCities = all.where((p) {
              final sameParent = p.parent == widget.parentName;
              if (widget.childName == null) return sameParent;
              return sameParent && (p.child == widget.childName);
            }).toList();

            final cities = <String>{
              for (final p in baseForCities)
                if ((p.city ?? '').isNotEmpty) p.city!,
            }.toList()
              ..sort();

            final items = _applyFilters(all);

            final w = MediaQuery.sizeOf(context).width;
            int cols = 1;
            if (w >= 1200) cols = 4;
            else if (w >= 900) cols = 3;
            else if (w >= 600) cols = 2;

            return Column(
              children: [
                // شريط فلاتر كومباكت
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // بحث بالاسم
                        SizedBox(
                          width: 240,
                          child: TextField(
                            onChanged: (v) => setState(() => _query = v.trim()),
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'ابحث باسم الطبيب',
                              hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
                              prefixIcon: const Icon(Icons.search, size: 18),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // فلتر المدينة
                        SizedBox(
                          width: 180,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              prefixIcon: const Icon(Icons.location_city_outlined, size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isDense: true,
                                isExpanded: true,
                                iconSize: 18,
                                value: (_city != null && cities.contains(_city)) ? _city : null,
                                hint: const Text('المدينة', style: TextStyle(fontSize: 13)),
                                items: [
                                  const DropdownMenuItem(
                                    value: '',
                                    child: Text('الكل', style: TextStyle(fontSize: 13)),
                                  ),
                                  ...cities.map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c, style: const TextStyle(fontSize: 13)),
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  setState(() => _city = (val ?? '').isEmpty ? null : val);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // الشبكة
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('لا توجد نتائج مطابقة'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(14),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.86,
                          ),
                          itemCount: items.length,
                          itemBuilder: (_, i) {
                            final m = items[i];

                            // معالجة رابط صورة أودوو
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
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.person_outline,
                                                    size: 72, color: Colors.grey),
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
                                        if ((m.city ?? '').isNotEmpty)
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.place, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                m.city!,
                                                style: const TextStyle(
                                                    color: Colors.black54, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        const SizedBox(height: 4),
                                        if (m.categoryPath.isNotEmpty)
                                          Text(
                                            m.categoryPath,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                color: Colors.black45, fontSize: 12),
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
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
