import 'package:flutter/material.dart';

import '../models/super_admin_panel_config.dart';

class SuperAdminScope extends InheritedWidget {
  final SuperAdminPanelConfig config;

  const SuperAdminScope({
    required this.config,
    required super.child,
    super.key,
  });

  static SuperAdminPanelConfig? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SuperAdminScope>()?.config;
  }

  static SuperAdminPanelConfig of(BuildContext context) {
    final config = maybeOf(context);
    assert(config != null, 'SuperAdminScope not found in widget tree');
    return config!;
  }

  @override
  bool updateShouldNotify(SuperAdminScope oldWidget) {
    return oldWidget.config != config;
  }
}
