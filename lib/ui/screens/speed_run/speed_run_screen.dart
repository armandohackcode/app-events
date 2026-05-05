import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/providers/speed_run_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/speed_run/add_challenge_screen.dart';
import 'package:app_events/ui/screens/speed_run/challenge_detail_screen.dart';
import 'package:app_events/ui/widgets/speed_run/card_challenge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class SpeedRunScreen extends StatefulWidget {
  const SpeedRunScreen({super.key});

  @override
  State<SpeedRunScreen> createState() => _SpeedRunScreenState();
}

class _SpeedRunScreenState extends State<SpeedRunScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SpeedRunProvider>(context, listen: false).loadChallenges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SpeedRunProvider>(context);
    final isAdmin = Provider.of<UserProvider>(context).isAdmin;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.speedRunTitle)),
      body: RefreshIndicator(
        onRefresh: () => Provider.of<SpeedRunProvider>(
          context,
          listen: false,
        ).loadChallenges(),
        child: _buildBody(provider),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => const AddChallengeScreen(),
                ),
              ),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(SpeedRunProvider provider) {
    if (provider.loading) {
      return Center(
        child: LoadingAnimationWidget.twistingDots(
          leftDotColor: AppStyles.colorBaseBlue,
          rightDotColor: AppStyles.colorBaseYellow,
          size: 40,
        ),
      );
    }
    if (provider.challenges.isEmpty) {
      return Center(
        child: Text(
          AppStrings.speedRunNoData,
          style: const TextStyle(
            color: AppStyles.fontSecondaryColor,
            fontSize: 15,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: provider.challenges.length,
      itemBuilder: (context, index) {
        final challenge = provider.challenges[index];
        return CardChallenge(
          challenge: challenge,
          onTap: () => Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => ChallengeDetailScreen(challenge: challenge),
            ),
          ),
        );
      },
    );
  }
}
