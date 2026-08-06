import 'package:get/get.dart';
import 'package:nwt_app/controllers/user_controller.dart';

/// Central place for Account Aggregator (AA) branding assets.
/// Use these getters wherever we show AA provider logo or illustrations so that
/// Finarkein users see Finarkein assets and Saafe users see Saafe assets.
/// When moving fully to Finarkein, remove Saafe branches here and in call sites
/// without impacting Finarkein flows.
class AaBranding {
  AaBranding._();

  static bool get _isFinarkein =>
      Get.isRegistered<UserController>()
          ? (Get.find<UserController>().userData?.isFinarkeinAa ?? false)
          : false;

  /// Asset path for the AA provider logo (e.g. connection/redirection screens).
  /// Finarkein: assets/finarkein/logo_finarkein.png
  /// Saafe: assets/svgs/saafe/saafe_logo.png
  static String get logoAssetPath =>
      _isFinarkein
          ? 'assets/finarkein/logo_finarkein.png'
          : 'assets/svgs/saafe/saafe_logo.png';

  /// Asset path for the redirection/connection screen center icon (arrow between logos).
  /// Saafe has saafe_redirection.svg; Finarkein reuses it for consistency.
  static String get redirectionCenterSvgPath =>
      'assets/svgs/saafe/saafe_redirection.svg';

  /// Asset path for the data fetch status screen illustration.
  /// Finarkein: logo (PNG). Saafe: saafe_data_fetch.svg.
  static String get dataFetchIllustrationPath =>
      _isFinarkein
          ? 'assets/finarkein/logo_finarkein.png'
          : 'assets/svgs/saafe/saafe_data_fetch.svg';

  /// True if [dataFetchIllustrationPath] is SVG (use SvgPicture.asset), false if PNG (use Image.asset).
  static bool get dataFetchIllustrationIsSvg => !_isFinarkein;

  /// Display name for the AA provider (e.g. "Finarkein" or "Saafe").
  static String get providerName => _isFinarkein ? 'Finarkein' : 'Saafe';
}
