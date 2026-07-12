import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/router/route_names.dart';
import '../../colleges/models/college_model.dart';
import '../../colleges/providers/college_provider.dart';

class AdminCollegesScreen extends ConsumerStatefulWidget {
  const AdminCollegesScreen({super.key});

  @override
  ConsumerState<AdminCollegesScreen> createState() =>
      _AdminCollegesScreenState();
}

class _AdminCollegesScreenState extends ConsumerState<AdminCollegesScreen> {
  final _searchController = TextEditingController();
  String? _cursor;
  List<CollegeModel> _colleges = [];
  bool _hasMore = false;
  bool _loading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search({bool loadMore = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final params = AdminCollegeSearchParams(
        query: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        startAfterDocumentId: loadMore ? _cursor : null,
      );
      if (!loadMore) {
        _colleges = [];
        _cursor = null;
      }
      final page = await ref.read(adminCollegeSearchProvider(params).future);
      if (!mounted) return;
      setState(() {
        _colleges = loadMore ? [..._colleges, ...page.colleges] : page.colleges;
        _cursor = page.lastDocumentId;
        _hasMore = page.hasMore;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Colleges'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.admin),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go(RouteNames.adminCollegeNew),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search colleges to edit...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loading ? null : () => _search(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading && _colleges.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _colleges.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _colleges.length) {
                        return TextButton(
                          onPressed: () => _search(loadMore: true),
                          child: const Text('Load more'),
                        );
                      }
                      final college = _colleges[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            college.name,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${college.city}, ${college.state} · '
                            '${college.isActive ? 'Active' : 'Inactive'}',
                          ),
                          trailing: const Icon(Icons.edit_outlined),
                          onTap: () => context.go(
                            RouteNames.adminCollegeEditPath(college.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(RouteNames.adminCollegeNew),
        icon: const Icon(Icons.add),
        label: const Text('Add College'),
      ),
    );
  }
}
