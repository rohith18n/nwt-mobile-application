import 'package:flutter_test/flutter_test.dart';
import 'package:nwt_app/utils/validators.dart';

void main() {
  test('Phone validation tests', () {
    // Normal 10 digits
    expect(AppValidators.validatePhone('8145000001'), null);

    // With spaces
    expect(AppValidators.validatePhone('8145 000 001'), null);

    // With +91 prefix
    expect(AppValidators.validatePhone('+918145000001'), null);

    // With 91 prefix
    expect(AppValidators.validatePhone('918145000001'), null);

    // Invalid length
    expect(
      AppValidators.validatePhone('814500000'),
      'Phone number must be exactly 10 digits',
    );
    expect(
      AppValidators.validatePhone('81450000012'),
      'Phone number must be exactly 10 digits',
    );

    // Cleaning tests
    expect(AppValidators.cleanPhoneNumber('+918145000001'), '8145000001');
    expect(AppValidators.cleanPhoneNumber('918145000001'), '8145000001');
    expect(AppValidators.cleanPhoneNumber('8145 000 001'), '8145000001');
  });
}
