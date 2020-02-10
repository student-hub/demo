import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:preferences/preferences.dart';

import 'package:acs_upb_mobile/generated/l10n.dart';
import 'package:acs_upb_mobile/widget/drawer.dart';
import 'package:acs_upb_mobile/routes/routes.dart';

class SettingsPage extends StatelessWidget {
  static const String routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).drawerItemSettings),
        ),
        drawer: AppDrawer(),
        body: PreferencePage([
          PreferenceTitle(S.of(context).settingsTitlePersonalization),
          SwitchPreference(
            S.of(context).settingsItemDarkMode,
            "dark_mode",
            onEnable: () {
              DynamicTheme.of(context).setBrightness(Brightness.dark);
            },
            onDisable: () {
              DynamicTheme.of(context).setBrightness(Brightness.light);
            },
            defaultVal: true,
          ),
          PreferenceTitle(S.of(context).settingsTitleLocalization),
          PreferenceDialogLink(S.of(context).settingsItemLanguage,
              desc: getLanguagePrefString(context, PrefService.get('language')),
              dialog: PreferenceDialog(
                [
                  getLanguageRadioPreference(context, 'ro'),
                  getLanguageRadioPreference(context, 'en'),
                  getLanguageRadioPreference(context, 'auto'),
                ],
                onlySaveOnSubmit: false,
              ))
        ]));
  }

  RadioPreference getLanguageRadioPreference(
      BuildContext context, String preference) {
    return RadioPreference(
      getLanguagePrefString(context, preference),
      preference,
      'language',
      onSelect: () {
        S.load(getLocale(context, preference));
        // Reload settings page
        Navigator.pushReplacementNamed(context, Routes.settings);
      },
    );
  }

  String getLanguagePrefString(BuildContext context, String preference) {
    switch (preference) {
      case 'en':
        return S.of(context).settingsItemLanguageEnglish;
      case 'ro':
        return S.of(context).settingsItemLanguageRomanian;
      case 'auto':
        return S.of(context).settingsItemLanguageAuto;
    }
  }

  Locale getLocale(BuildContext context, String preference) {
    switch (preference) {
      case 'en':
        return Locale('en', 'US');
      case 'ro':
        return Locale('ro', 'RO');
      case 'auto':
        return getLocale(context, S.of(context).localeName);
    }
  }
}
