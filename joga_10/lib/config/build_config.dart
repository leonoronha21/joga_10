class BuildConfig {
  BuildConfig._();

  static const bool isRelease = bool.fromEnvironment('dart.vm.product');

  static const bool allowLocalAuthInRelease = bool.fromEnvironment(
    'JOGA10_ALLOW_LOCAL_AUTH',
    defaultValue: false,
  );

  static const bool allowDemoPaymentsInRelease = bool.fromEnvironment(
    'JOGA10_ALLOW_DEMO_PAYMENTS',
    defaultValue: false,
  );

  static const bool localAuthEnabled = !isRelease || allowLocalAuthInRelease;
  static const bool demoPaymentsEnabled =
      !isRelease || allowDemoPaymentsInRelease;
  static const bool manualCardsEnabled = demoPaymentsEnabled;
}
