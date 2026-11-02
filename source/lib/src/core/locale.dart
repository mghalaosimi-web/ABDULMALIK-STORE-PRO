import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'session.dart';

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final locale = Locale(ref.read(appConfigProvider).language);
    Intl.defaultLocale = locale.languageCode;
    return locale;
  }

  Future<void> setLanguage(String language) async {
    if (language != 'ar' && language != 'en') {
      throw ArgumentError.value(language, 'language', 'Only ar and en are supported');
    }
    await ref.read(appConfigProvider).setLanguage(language);
    Intl.defaultLocale = language;
    state = Locale(language);
  }
}
