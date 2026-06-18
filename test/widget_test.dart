import 'package:cope_x_studio/app.dart';
import 'package:cope_x_studio/providers/security_provider.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/services/security_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App loads with browser tab', (WidgetTester tester) async {
    final workspace = WorkspaceProvider();
    final security = SecurityProvider(
      securityService: SecurityService(inMemory: true),
    );
    workspace.attachSecurity(security);
    await workspace.initPermissions();
    await security.init();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: workspace),
          ChangeNotifierProvider.value(value: security),
        ],
        child: const CopeXStudioApp(),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
