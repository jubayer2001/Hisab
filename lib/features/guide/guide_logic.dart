/// What the app shows on top of Home when it opens.
enum GuideAction {
  /// Nothing: the normal case.
  none,

  /// A brand-new user has just finished the welcome steps: offer the quick tour.
  tour,

  /// The app was updated since the last "what's new" was shown.
  whatsNew,
}

/// Decides what to show at start-up.
///
/// [tourPending] is set when the welcome steps were just finished. [lastSeen] is the version
/// whose "what's new" was shown last, as `2.0.0+15`; it is missing on a phone that was updated
/// from a version that did not have this feature, which also counts as "updated".
GuideAction decideGuideAction({required bool tourPending, required String? lastSeen, required String current}) {
  if (tourPending) return GuideAction.tour;
  if (lastSeen != current) return GuideAction.whatsNew;
  return GuideAction.none;
}
