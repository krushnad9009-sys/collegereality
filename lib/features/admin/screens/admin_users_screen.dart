import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/router/route_names.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(RouteNames.admin),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'User management will be expanded in Phase 3. '
            'Admins can currently manage colleges and reviews.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
