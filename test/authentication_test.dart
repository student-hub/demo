import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:preferences/preferences.dart';
import 'package:provider/provider.dart';
import 'package:student_hub_demo/authentication/model/user.dart';
import 'package:student_hub_demo/authentication/service/auth_provider.dart';
import 'package:student_hub_demo/authentication/view/login_view.dart';
import 'package:student_hub_demo/authentication/view/sign_up_view.dart';
import 'package:student_hub_demo/main.dart';
import 'package:student_hub_demo/pages/faq/model/question.dart';
import 'package:student_hub_demo/pages/faq/service/question_provider.dart';
import 'package:student_hub_demo/pages/filter/model/filter.dart';
import 'package:student_hub_demo/pages/filter/service/filter_provider.dart';
import 'package:student_hub_demo/pages/home/home_page.dart';
import 'package:student_hub_demo/pages/news_feed/model/news_feed_item.dart';
import 'package:student_hub_demo/pages/news_feed/service/news_provider.dart';
import 'package:student_hub_demo/pages/people/service/person_provider.dart';
import 'package:student_hub_demo/pages/portal/service/website_provider.dart';
import 'package:student_hub_demo/resources/locale_provider.dart';

import 'test_utils.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class MockFilterProvider extends Mock implements FilterProvider {}

class MockWebsiteProvider extends Mock implements WebsiteProvider {}

class MockPersonProvider extends Mock implements PersonProvider {}

class MockQuestionProvider extends Mock implements QuestionProvider {}

class MockNewsProvider extends Mock implements NewsProvider {}

void main() {
  AuthProvider mockAuthProvider;
  WebsiteProvider mockWebsiteProvider;
  FilterProvider mockFilterProvider;
  PersonProvider mockPersonProvider;
  MockQuestionProvider mockQuestionProvider;
  MockNewsProvider mockNewsProvider;

  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    PrefService.enableCaching();
    PrefService.cache = {};
    PrefService.setString('language', 'en');

    LocaleProvider.cultures = testCultures;
    LocaleProvider.rruleL10ns = {'en': await RruleL10nTest.create()};

    // Mock the behaviour of the auth provider
    mockAuthProvider = MockAuthProvider();
    // ignore: invalid_use_of_protected_member
    when(mockAuthProvider.hasListeners).thenReturn(false);
    when(mockAuthProvider.isAuthenticated).thenReturn(false);
    when(mockAuthProvider.currentUser).thenAnswer((_) => Future.value(null));
    when(mockAuthProvider.isAnonymous).thenReturn(true);
    when(mockAuthProvider.getProfilePictureURL(context: anyNamed('context')))
        .thenAnswer((_) => Future.value(null));

    mockWebsiteProvider = MockWebsiteProvider();
    // ignore: invalid_use_of_protected_member
    when(mockWebsiteProvider.hasListeners).thenReturn(false);
    when(mockWebsiteProvider.deleteWebsite(any, context: anyNamed('context')))
        .thenAnswer((_) => Future.value(true));
    when(mockWebsiteProvider.fetchWebsites(any, context: anyNamed('context')))
        .thenAnswer((_) => Future.value([]));
    when(mockWebsiteProvider.fetchFavouriteWebsites(
            uid: mockAuthProvider.uid, context: anyNamed('context')))
        .thenAnswer((_) => Future.value(null));

    mockFilterProvider = MockFilterProvider();
    // ignore: invalid_use_of_protected_member
    when(mockFilterProvider.hasListeners).thenReturn(false);
    when(mockFilterProvider.filterEnabled).thenReturn(true);
    when(mockFilterProvider.fetchFilter(context: anyNamed('context')))
        .thenAnswer((_) => Future.value(Filter(localizedLevelNames: [
              {'en': 'Level', 'ro': 'Nivel'}
            ], root: FilterNode(name: 'root'))));

    mockPersonProvider = MockPersonProvider();
    // ignore: invalid_use_of_protected_member
    when(mockPersonProvider.hasListeners).thenReturn(false);
    when(mockPersonProvider.fetchPeople(context: anyNamed('context')))
        .thenAnswer((_) => Future.value([]));

    mockQuestionProvider = MockQuestionProvider();
    // ignore: invalid_use_of_protected_member
    when(mockQuestionProvider.hasListeners).thenReturn(false);
    when(mockQuestionProvider.fetchQuestions(context: anyNamed('context')))
        .thenAnswer((_) => Future.value(<Question>[]));
    when(mockQuestionProvider.fetchQuestions(limit: anyNamed('limit')))
        .thenAnswer((_) => Future.value(<Question>[]));

    mockNewsProvider = MockNewsProvider();
    // ignore: invalid_use_of_protected_member
    when(mockNewsProvider.hasListeners).thenReturn(false);
    when(mockNewsProvider.fetchNewsFeedItems(context: anyNamed('context')))
        .thenAnswer((_) => Future.value(<NewsFeedItem>[]));
    when(mockNewsProvider.fetchNewsFeedItems(limit: anyNamed('limit')))
        .thenAnswer((_) => Future.value(<NewsFeedItem>[]));
  });

  group('Login', () {
    testWidgets('Anonymous login', (WidgetTester tester) async {
      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => mockAuthProvider),
        ChangeNotifierProvider<WebsiteProvider>(
            create: (_) => mockWebsiteProvider),
        ChangeNotifierProvider<QuestionProvider>(
            create: (_) => mockQuestionProvider),
        ChangeNotifierProvider<NewsProvider>(create: (_) => mockNewsProvider),
      ], child: const MyApp()));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        expect(find.byType(LoginView), findsOneWidget);

        when(mockAuthProvider.signInAnonymously(context: anyNamed('context')))
            .thenAnswer((_) => Future.value(true));

        // Log in anonymously
        await tester
            .tap(find.byKey(const ValueKey('log_in_anonymously_button')));
        await tester.pumpAndSettle();

        verify(
            mockAuthProvider.signInAnonymously(context: anyNamed('context')));
        expect(find.byType(HomePage), findsOneWidget);

        // Easy way to check that the login page can't be navigated back to
        expect(find.byIcon(Icons.arrow_back), findsNothing);
      });
    });

    testWidgets('Credential login', (WidgetTester tester) async {
      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => mockAuthProvider),
        ChangeNotifierProvider<WebsiteProvider>(
            create: (_) => mockWebsiteProvider),
        ChangeNotifierProvider<QuestionProvider>(
            create: (_) => mockQuestionProvider),
        ChangeNotifierProvider<NewsProvider>(create: (_) => mockNewsProvider),
      ], child: const MyApp()));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        expect(find.byType(LoginView), findsOneWidget);

        when(mockAuthProvider.signIn(
                email: anyNamed('email'),
                password: anyNamed('password'),
                context: anyNamed('context')))
            .thenAnswer((_) => Future.value(true));

        // Enter credentials
        await tester.enterText(find.byKey(const ValueKey('email_text_field')),
            'test@studenthub.com');
        await tester.enterText(
            find.byKey(const ValueKey('password_text_field')), 'password');

        await tester.tap(find.byKey(const ValueKey('log_in_button')));
        await tester.pumpAndSettle();

        verify(mockAuthProvider.signIn(
            email: argThat(equals('test@studenthub.com'), named: 'email'),
            password: argThat(equals('password'), named: 'password'),
            context: anyNamed('context')));
        expect(find.byType(HomePage), findsOneWidget);

        // Easy way to check that the login page can't be navigated back to
        expect(find.byIcon(Icons.arrow_back), findsNothing);
      });
    });
  });

  group('Recover password', () {
    testWidgets('Send email', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>(
          create: (_) => mockAuthProvider, child: const MyApp()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginView), findsOneWidget);

      when(mockAuthProvider.sendPasswordResetEmail(
              email: anyNamed('email'), context: anyNamed('context')))
          .thenAnswer((_) => Future.value(true));

      expect(find.byType(AlertDialog), findsNothing);

      // Reset password
      await tester.tap(find.text('Reset password'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Send email
      await tester.enterText(
          find.byKey(const ValueKey('reset_password_email_text_field')),
          'test@studenthub.com');

      await tester.tap(find.byKey(const ValueKey('send_email_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);

      verify(mockAuthProvider.sendPasswordResetEmail(
          email: argThat(equals('test@studenthub.com'), named: 'email'),
          context: anyNamed('context')));
    });

    testWidgets('Cancel', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>(
          create: (_) => mockAuthProvider, child: const MyApp()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginView), findsOneWidget);

      when(mockAuthProvider.sendPasswordResetEmail(
              email: anyNamed('email'), context: anyNamed('context')))
          .thenAnswer((_) => Future.value(true));

      expect(find.byType(AlertDialog), findsNothing);

      // Reset password
      await tester.tap(find.text('Reset password'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Close dialog
      await tester.tap(find.byKey(const ValueKey('cancel_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);

      verifyNever(
          mockAuthProvider.sendPasswordResetEmail(email: anyNamed('email')));
    });
  });

  group('Sign up', () {
    final MockNavigatorObserver mockObserver = MockNavigatorObserver();
    FilterProvider mockFilterProvider = MockFilterProvider();

    setUp(() {
      mockFilterProvider = MockFilterProvider();
      // ignore: invalid_use_of_protected_member
      when(mockFilterProvider.hasListeners).thenReturn(false);
      when(mockFilterProvider.filterEnabled).thenReturn(true);
      when(mockFilterProvider.fetchFilter(context: anyNamed('context')))
          .thenAnswer((_) => Future.value(Filter(
                  localizedLevelNames: [
                    {'en': 'Degree', 'ro': 'Nivel de studiu'},
                    {'en': 'Major', 'ro': 'Specializare'},
                    {'en': 'Year', 'ro': 'An'},
                    {'en': 'Series', 'ro': 'Serie'},
                    {'en': 'Group', 'ro': 'Group'},
                    {'en': 'Subgroup', 'ro': 'Semigrupă'}
                  ],
                  root: FilterNode(name: 'All', value: true, children: [
                    FilterNode(name: 'BSc', value: true, children: [
                      FilterNode(name: 'CTI', value: true, children: [
                        FilterNode(
                          name: 'CTI-1',
                          value: true,
                          children: [
                            FilterNode(name: '1-CA'),
                            FilterNode(
                              name: '1-CB',
                              value: true,
                              children: [
                                FilterNode(
                                  name: '311CB',
                                  value: true,
                                  children: [
                                    FilterNode(name: '311CBa'),
                                    FilterNode(name: '311CBb'),
                                  ],
                                ),
                                FilterNode(
                                  name: '312CB',
                                  value: true,
                                  children: [
                                    FilterNode(name: '312CBa'),
                                    FilterNode(name: '312CBb'),
                                  ],
                                ),
                                FilterNode(
                                  name: '313CB',
                                  value: true,
                                  children: [
                                    FilterNode(name: '313CBa'),
                                    FilterNode(name: '313CBb'),
                                  ],
                                ),
                                FilterNode(
                                  name: '314CB',
                                  value: true,
                                  children: [
                                    FilterNode(name: '314CBa'),
                                    FilterNode(name: '314CBb'),
                                  ],
                                ),
                              ],
                            ),
                            FilterNode(name: '1-CC'),
                            FilterNode(name: '1-CD', children: [
                              FilterNode(
                                name: '311CD',
                                value: true,
                                children: [
                                  FilterNode(name: '311CDa'),
                                  FilterNode(name: '311CDb'),
                                ],
                              ),
                              FilterNode(
                                name: '312CD',
                                value: true,
                                children: [
                                  FilterNode(name: '312CDa'),
                                  FilterNode(name: '312CDb'),
                                ],
                              ),
                              FilterNode(
                                name: '313CD',
                                value: true,
                                children: [
                                  FilterNode(name: '313CDa'),
                                  FilterNode(name: '313CDb'),
                                ],
                              ),
                              FilterNode(
                                name: '314CD',
                                value: true,
                                children: [
                                  FilterNode(name: '314CDa'),
                                  FilterNode(name: '314CDb'),
                                ],
                              ),
                            ]),
                          ],
                        ),
                        FilterNode(
                          name: 'CTI-2',
                        ),
                        FilterNode(
                          name: 'CTI-3',
                        ),
                        FilterNode(
                          name: 'CTI-4',
                        ),
                      ]),
                      FilterNode(name: 'IS')
                    ]),
                    FilterNode(name: 'MSc', children: [
                      FilterNode(
                        name: 'IA',
                      ),
                      FilterNode(name: 'SPRC'),
                    ])
                  ]))));
    });

    testWidgets('Sign up', (WidgetTester tester) async {
      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => mockAuthProvider),
        ChangeNotifierProvider<FilterProvider>(
            create: (_) => mockFilterProvider),
        ChangeNotifierProvider<WebsiteProvider>(
            create: (_) => mockWebsiteProvider),
        ChangeNotifierProvider<QuestionProvider>(
            create: (_) => mockQuestionProvider),
        ChangeNotifierProvider<NewsProvider>(create: (_) => mockNewsProvider),
      ], child: MyApp(navigationObservers: [mockObserver])));
      await tester.pumpAndSettle();

      verify(mockObserver.didPush(any, any));
      expect(find.byType(LoginView), findsOneWidget);

      // Scroll sign up button into view and tap
      await tester.ensureVisible(find.text('Sign up'));
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      verify(mockObserver.didPush(any, any));
      expect(find.byType(SignUpView), findsOneWidget);

      when(mockAuthProvider.signUp(
              info: anyNamed('info'), context: anyNamed('context')))
          .thenAnswer((_) => Future.value(true));
      when(mockAuthProvider.canSignUpWithEmail(email: anyNamed('email')))
          .thenAnswer((_) => Future.value(true));

      // Test parser from email
      final Finder email = find.byKey(const ValueKey('email_text_field'));
      final TextField firstName = tester.widget<TextField>(
          find.byKey(const ValueKey('first_name_text_field')));
      final TextField lastName = tester.widget<TextField>(
          find.byKey(const ValueKey('last_name_text_field')));

      await tester.enterText(email, 'john_alexander.doe123');
      expect(firstName.controller.text, equals('John Alexander'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(email, 'john_alexander.doe123');
      expect(firstName.controller.text, equals('John Alexander'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(email, 'john.doe@studenthub.com');
      expect(firstName.controller.text, equals('John'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(email, 'john_alexander.doe1234@studenthub.com');

      ///////////////////////

      await tester.enterText(
          find.byKey(const ValueKey('password_text_field')), 'password');
      await tester.enterText(
          find.byKey(const ValueKey('confirm_password_text_field')),
          'password');
      await tester.enterText(
          find.byKey(const ValueKey('first_name_text_field')),
          'John Alexander');
      await tester.enterText(
          find.byKey(const ValueKey('last_name_text_field')), 'Doe');

      // TODO(AdrianMargineanu): Test dropdown buttons

      // Scroll sign up button into view
      await tester.ensureVisible(find.byKey(const ValueKey('sign_up_button')));

      // Check Privacy Policy
      await tester.tap(find.byType(Checkbox));

      // Press sign up
      await tester.tap(find.byKey(const ValueKey('sign_up_button')));
      await tester.pumpAndSettle();

      verify(mockAuthProvider.signUp(
          info: argThat(
              equals({
                'Email': 'john_alexander.doe1234@studenthub.com',
                'Password': 'password',
                'Confirm password': 'password',
                'First name': 'John Alexander',
                'Last name': 'Doe',
              }),
              named: 'info'),
          context: anyNamed('context')));
      expect(find.byType(HomePage), findsOneWidget);
      verify(mockObserver.didPush(any, any));
    });

    testWidgets('Cancel', (WidgetTester tester) async {
      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => mockAuthProvider),
        ChangeNotifierProvider<FilterProvider>(
            create: (_) => mockFilterProvider)
      ], child: MyApp(navigationObservers: [mockObserver])));
      await tester.pumpAndSettle();

      verify(mockObserver.didPush(any, any));
      expect(find.byType(LoginView), findsOneWidget);

      // Scroll sign up button into view and tap
      await tester.ensureVisible(find.text('Sign up'));
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      verify(mockObserver.didPush(any, any));
      expect(find.byType(SignUpView), findsOneWidget);

      when(mockAuthProvider.signUp(
              info: anyNamed('info'), context: anyNamed('context')))
          .thenAnswer((_) => Future.value(true));

      // Scroll cancel button into view and tap
      await tester.ensureVisible(find.byKey(const ValueKey('cancel_button')));
      await tester.tap(find.byKey(const ValueKey('cancel_button')));
      await tester.pumpAndSettle();

      verifyNever(mockAuthProvider.signUp(
          info: anyNamed('info'), context: anyNamed('context')));
      expect(find.byType(LoginView), findsOneWidget);
      expect(find.byType(SignUpView), findsNothing);
      verify(mockObserver.didPop(any, any));
    });
  });

  group('Sign out', () {
    final MockNavigatorObserver mockObserver = MockNavigatorObserver();

    setUp(() {
      // Mock an anonymous user already being logged in
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockAuthProvider.isVerified).thenAnswer((_) => Future.value(false));
    });

    testWidgets('Sign out anonymous', (WidgetTester tester) async {
      when(mockAuthProvider.currentUser).thenAnswer((_) => Future.value(null));
      when(mockAuthProvider.currentUserFromCache).thenReturn(null);
      when(mockAuthProvider.isAnonymous).thenReturn(true);

      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => mockAuthProvider),
        ChangeNotifierProvider<FilterProvider>(
            create: (_) => mockFilterProvider),
        ChangeNotifierProvider<WebsiteProvider>(
            create: (_) => mockWebsiteProvider),
        ChangeNotifierProvider<PersonProvider>(
            create: (_) => mockPersonProvider),
        ChangeNotifierProvider<QuestionProvider>(
            create: (_) => mockQuestionProvider),
        ChangeNotifierProvider<NewsProvider>(create: (_) => mockNewsProvider),
      ], child: MyApp(navigationObservers: [mockObserver])));
      await tester.pumpAndSettle();

      verify(mockObserver.didPush(any, any));
      expect(find.byType(HomePage), findsOneWidget);

      expect(find.text('Anonymous'), findsOneWidget);

      // Press log in button
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      verify(mockAuthProvider.signOut());
      expect(find.byType(LoginView), findsOneWidget);
    });

    testWidgets('Sign out authenticated', (WidgetTester tester) async {
      when(mockAuthProvider.currentUser).thenAnswer((_) =>
          Future.value(User(uid: '0', firstName: 'John', lastName: 'Doe')));
      when(mockAuthProvider.currentUserFromCache)
          .thenReturn(User(uid: '0', firstName: 'John', lastName: 'Doe'));
      when(mockAuthProvider.isAnonymous).thenReturn(false);

      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => mockAuthProvider),
        ChangeNotifierProvider<FilterProvider>(
            create: (_) => mockFilterProvider),
        ChangeNotifierProvider<WebsiteProvider>(
            create: (_) => mockWebsiteProvider),
        ChangeNotifierProvider<PersonProvider>(
            create: (_) => mockPersonProvider),
        ChangeNotifierProvider<QuestionProvider>(
            create: (_) => mockQuestionProvider),
        ChangeNotifierProvider<NewsProvider>(create: (_) => mockNewsProvider),
      ], child: MyApp(navigationObservers: [mockObserver])));
      await tester.pumpAndSettle();

      verify(mockObserver.didPush(any, any));
      expect(find.byType(HomePage), findsOneWidget);

      expect(find.text('John Doe'), findsOneWidget);

      // Press log out button
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      verify(mockAuthProvider.signOut());
      expect(find.byType(LoginView), findsOneWidget);
    });
  });
}
