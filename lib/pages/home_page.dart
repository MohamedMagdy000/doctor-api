import 'package:flutter/material.dart';
import '../models.dart';
import '../services/odoo_api.dart';
import '../widgets/top_nav.dart';
import 'products_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<CatParent>> _catsFuture;

  @override
  void initState() {
    super.initState();
    _catsFuture = OdooApi.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // منيو علوي من Odoo
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0.8,
              toolbarHeight: 46,
              titleSpacing: 0,
              title: FutureBuilder<List<CatParent>>(
                future: _catsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const _NavLoading();
                  }
                  if (snap.hasError) {
                    return _NavError(msg: snap.error.toString());
                  }
                  final parents = snap.data!;
                  return TopNavBar(
                    parents: parents,
                    selectedParent: null,
                    // هنا التنقّل لصفحة جديدة
                    onSelect: (parentName, childName) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductsPage(
                            parentName: parentName,
                            childName: childName,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // الهيدر الأزرق – نفس الشكل اللي عايزه
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A365D), Color(0xFF2C5282), Color(0xFF2D3748)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: const [
                    SizedBox(height: 6),
                    Text('⚕', style: TextStyle(fontSize: 56, color: Colors.white)),
                    SizedBox(height: 10),
                    Text('دليل الأطباء',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 30)),
                    SizedBox(height: 8),
                    Text('منصتك الطبية الموثوقة', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    SizedBox(height: 10),
                    Text(
                      'نحن تطبيق الدليل الطبي الرائد الذي يقدم خدمات طبية متكاملة ويسهل التواصل مع أفضل الأطباء في جميع التخصصات',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

/* لودر وخطأ للمنيو */
class _NavLoading extends StatelessWidget {
  const _NavLoading();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          5,
          (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            width: 90,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFE6ECF3),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavError extends StatelessWidget {
  const _NavError({required this.msg});
  final String msg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text('خطأ: $msg', style: const TextStyle(color: Colors.red)),
    );
  }
}
