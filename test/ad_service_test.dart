import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:myclock/services/ad_service.dart';

void main() {
  test('uses child-directed general audience ad configuration', () {
    final configuration = AdService.childSafeRequestConfiguration;

    expect(
      configuration.tagForChildDirectedTreatment,
      TagForChildDirectedTreatment.yes,
    );
    expect(configuration.maxAdContentRating, MaxAdContentRating.g);
    expect(
      configuration.tagForUnderAgeOfConsent,
      TagForUnderAgeOfConsent.unspecified,
    );
  });
}
