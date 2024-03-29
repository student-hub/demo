import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oktoast/oktoast.dart';
import 'package:preferences/preferences.dart';
import 'package:provider/provider.dart';
import 'package:rrule/rrule.dart';
import 'package:student_hub_demo/authentication/service/auth_provider.dart';
import 'package:student_hub_demo/authentication/view/login_view.dart';
import 'package:student_hub_demo/authentication/view/sign_up_view.dart';
import 'package:student_hub_demo/generated/l10n.dart';
import 'package:student_hub_demo/navigation/bottom_navigation_bar.dart';
import 'package:student_hub_demo/navigation/routes.dart';
import 'package:student_hub_demo/pages/classes/service/class_provider.dart';
import 'package:student_hub_demo/pages/faq/service/question_provider.dart';
import 'package:student_hub_demo/pages/faq/view/faq_page.dart';
import 'package:student_hub_demo/pages/filter/service/filter_provider.dart';
import 'package:student_hub_demo/pages/filter/view/filter_page.dart';
import 'package:student_hub_demo/pages/news_feed/service/news_provider.dart';
import 'package:student_hub_demo/pages/news_feed/view/news_feed_page.dart';
import 'package:student_hub_demo/pages/people/service/person_provider.dart';
import 'package:student_hub_demo/pages/portal/service/website_provider.dart';
import 'package:student_hub_demo/pages/settings/service/request_provider.dart';
import 'package:student_hub_demo/pages/settings/view/request_permissions.dart';
import 'package:student_hub_demo/pages/settings/view/settings_page.dart';
import 'package:student_hub_demo/pages/timetable/service/uni_event_provider.dart';
import 'package:student_hub_demo/resources/locale_provider.dart';
import 'package:student_hub_demo/resources/utils.dart';
import 'package:student_hub_demo/widgets/loading_screen.dart';
import 'package:time_machine/time_machine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  final authProvider = AuthProvider();
  final classProvider = ClassProvider();
  final personProvider = PersonProvider();

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<AuthProvider>(create: (_) => authProvider),
    ChangeNotifierProvider<WebsiteProvider>(create: (_) => WebsiteProvider()),
    Provider<RequestProvider>(create: (_) => RequestProvider()),
    ChangeNotifierProvider<ClassProvider>(create: (_) => classProvider),
    ChangeNotifierProvider<PersonProvider>(create: (_) => personProvider),
    ChangeNotifierProvider<QuestionProvider>(create: (_) => QuestionProvider()),
    ChangeNotifierProvider<NewsProvider>(create: (_) => NewsProvider()),
    ChangeNotifierProxyProvider<AuthProvider, FilterProvider>(
      create: (_) => FilterProvider(global: true),
      update: (context, authProvider, filterProvider) {
        return filterProvider..updateAuth(authProvider);
      },
    ),
    ChangeNotifierProxyProvider2<ClassProvider, FilterProvider,
        UniEventProvider>(
      create: (_) => UniEventProvider(
        authProvider: authProvider,
        personProvider: personProvider,
      ),
      update: (context, classProvider, filterProvider, uniEventProvider) {
        return uniEventProvider
          ..updateClasses(classProvider)
          ..updateFilter(filterProvider);
      },
    ),
  ], child: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({this.navigationObservers});

  final List<NavigatorObserver> navigationObservers;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Color _accentColor = const Color(0xFF43ACCD);

  Widget buildApp(BuildContext context, ThemeData theme) {
    return MaterialApp(
      title: 'StudentHub DEMO',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        S.delegate
      ],
      supportedLocales: S.delegate.supportedLocales,
      theme: theme,
      initialRoute: Routes.root,
      routes: {
        Routes.root: (_) => AppLoadingScreen(),
        Routes.home: (_) => const AppBottomNavigationBar(),
        Routes.settings: (_) => SettingsPage(),
        Routes.login: (_) => LoginView(),
        Routes.signUp: (_) => SignUpView(),
        Routes.faq: (_) => FaqPage(),
        Routes.filter: (_) => const FilterPage(),
        Routes.newsFeed: (_) => NewsFeedPage(),
        Routes.requestPermissions: (_) => RequestPermissionsPage(),
      },
      navigatorObservers: widget.navigationObservers ?? [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicTheme(
      defaultBrightness: SchedulerBinding.instance.window.platformBrightness,
      data: (brightness) => ThemeData(
        brightness: brightness,
        accentColor: _accentColor,
        // The following two lines are meant to remove the splash effect
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        accentTextTheme: ThemeData().accentTextTheme.apply(
            fontFamily: 'Montserrat',
            bodyColor: _accentColor,
            displayColor: _accentColor),
        toggleableActiveColor: _accentColor,
        fontFamily: 'Montserrat',
        primaryColor: const Color(0xFF4DB5E4),
      ),
      themedWidgetBuilder: (context, theme) {
        return OKToast(
          textStyle: theme.textTheme.button,
          backgroundColor: theme.accentColor.withOpacity(.8),
          position: ToastPosition.bottom,
          child: GestureDetector(
            onTap: () {
              // Remove current focus on tap
              final currentFocus = FocusScope.of(context);
              if (!currentFocus.hasPrimaryFocus) {
                currentFocus.unfocus();
              }
            },
            child: buildApp(context, theme),
          ),
        );
      },
    );
  }
}

class AppLoadingScreen extends StatelessWidget {
  Future<String> _setUpAndChooseStartScreen(BuildContext context) async {
    // Make initializations if this is not a test
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      await TimeMachine.initialize({'rootBundle': rootBundle});
      await PrefService.init(prefix: 'pref_');
      PrefService.setDefaultValues(
          {'language': 'auto', 'relevance_filter': true});

      if (kDebugMode || kProfileMode) {
        await FirebaseAnalytics().setAnalyticsCollectionEnabled(false);
      } else if (kReleaseMode) {
        await FirebaseAnalytics().setAnalyticsCollectionEnabled(true);
      }

      LocaleProvider.cultures ??= {
        'ro': await Cultures.getCulture('ro'),
        'en': await Cultures.getCulture('en')
      };

      // TODO(IoanaAlexandru): Make `rrule` package support Romanian
      LocaleProvider.rruleL10ns ??= {'en': await RruleL10nEn.create()};

      Culture.current = LocaleProvider.cultures[LocaleProvider.localeString];
    }

    // Load locale from settings
    await S.load(LocaleProvider.locale);

    // Choose start screen
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.isAuthenticated ? Routes.home : Routes.login;
  }

  @override
  Widget build(BuildContext context) {
    return LoadingScreen(
      navigateAfterFuture: _setUpAndChooseStartScreen(context),
      image: Image.asset('assets/icons/demo_uni_logo.png'),
      loaderColor: Theme.of(context).accentColor,
    );
  }
}
