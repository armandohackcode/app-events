import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/repositories/other_repository.dart';
import 'package:app_events/domain/repositories/user_repository.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/widgets/home/sponsors_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockOtherRepository extends Mock implements OtherRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  testWidgets('shows the section with the design tiles when there are no '
      'sponsors', (tester) async {
    final other = _MockOtherRepository();
    when(() => other.getSponsors()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => OtherProvider(other)),
          ChangeNotifierProvider(
            create: (_) => UserProvider(_MockUserRepository()),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: SponsorsContent())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.homeSponsorsTitle), findsOneWidget);
    expect(find.text(AppStrings.homeSponsorsThanks), findsOneWidget);
    expect(find.text(AppStrings.homeSponsorPlaceholderOne), findsOneWidget);
    expect(find.text(AppStrings.homeSponsorPlaceholderTwo), findsOneWidget);
  });
}
