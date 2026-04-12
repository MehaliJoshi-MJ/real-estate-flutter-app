import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:real_estate_flutter_app/providers/property_provider.dart';
import 'package:real_estate_flutter_app/services/property_api_service.dart';
import 'package:real_estate_flutter_app/ui/screens/home_screen.dart';

void main() {
  testWidgets('Home screen shows Properties title', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        '{"properties":[{"id":"p1","title":"Test Loft","address":"1 Test St","description":"Nice place to stay","price":123,"status":"forSale","isUserAdded":false}]}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PropertyProvider(
          apiService: PropertyApiService(httpClient: mockClient),
        ),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('Properties'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Test Loft'), findsWidgets);
  });
}
