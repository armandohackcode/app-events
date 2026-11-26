import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Bottom institutional GDG Sucre branding and dynamic application version.
class SignInFooter extends StatefulWidget {
  const SignInFooter({super.key});

  @override
  State<SignInFooter> createState() => _SignInFooterState();
}

class _SignInFooterState extends State<SignInFooter> {
  late final Future<String?> _versionFuture;

  @override
  void initState() {
    super.initState();
    _versionFuture = _loadVersion();
  }

  Future<String?> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      return version.isEmpty ? null : version;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(AppAssetsPath.gdgIcon, height: 18),
        const SizedBox(height: 8),
        const Text(
          AppStrings.signInCommunityName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppStyles.fontColor,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          AppStrings.signInCommunityCity,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppStyles.fontSecondaryColor,
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<String?>(
          future: _versionFuture,
          builder: (context, snapshot) {
            final version = snapshot.data;
            if (version == null || version.isEmpty) {
              return const SizedBox.shrink();
            }
            return Text(
              AppStrings.signInVersionLabel(version),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppStyles.monospaceFontFamily,
                fontFamilyFallback: ['monospace'],
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppStyles.fontSecondaryColor,
              ),
            );
          },
        ),
      ],
    );
  }
}
