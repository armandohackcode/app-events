import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speed_run_challenge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final SpeedRunChallenge challenge;
  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  static const double _expandedHeight = 280.0;
  static const double _collapseThreshold = _expandedHeight - kToolbarHeight;

  late final ScrollController _scrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset.clamp(0.0, _collapseThreshold);
    if (offset != _scrollOffset) setState(() => _scrollOffset = offset);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    final hasImage = challenge.imageUrl.isNotEmpty;

    final t = hasImage
        ? (_scrollOffset / _collapseThreshold).clamp(0.0, 1.0)
        : 1.0;

    final appBarBg = Color.lerp(Colors.transparent, AppStyles.colorAppbar, t)!;
    final fgColor = Color.lerp(Colors.white, AppStyles.fontColor, t)!;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: hasImage ? _expandedHeight : null,
            pinned: true,
            backgroundColor: appBarBg,
            foregroundColor: fgColor,
            titleTextStyle: TextStyle(
              color: fgColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),

            title: Opacity(
              opacity: ((t - 0.4) / 0.6).clamp(0.0, 1.0),
              child: Text(challenge.title),
            ),
            flexibleSpace: hasImage
                ? FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'challenge_image_${challenge.id}',
                          child: CachedNetworkImage(
                            imageUrl: challenge.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (ctx, url) => ColoredBox(
                              color: AppStyles.borderColor,
                              child: Center(
                                child: LoadingAnimationWidget.twistingDots(
                                  leftDotColor: AppStyles.colorBaseBlue,
                                  rightDotColor: AppStyles.colorBaseYellow,
                                  size: 36,
                                ),
                              ),
                            ),
                            errorWidget: (ctx, url, err) => const ColoredBox(
                              color: AppStyles.backgroundColor,
                            ),
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment(0, 0.45),
                              colors: [Color(0x99000000), Colors.transparent],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 20, 15, 8),
              child: Opacity(
                opacity: (1 - t / 0.6).clamp(0.0, 1.0),
                child: Text(
                  challenge.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Html(
              data: challenge.challenge,
              style: {
                'body': Style(
                  fontSize: FontSize(15),
                  color: AppStyles.fontColor,
                  margin: Margins.symmetric(horizontal: 15),
                ),
                'h1': Style(
                  fontSize: FontSize(20),
                  fontWeight: FontWeight.bold,
                  color: AppStyles.fontColor,
                ),
                'h2': Style(
                  fontSize: FontSize(18),
                  fontWeight: FontWeight.bold,
                  color: AppStyles.fontColor,
                ),
                'code': Style(
                  backgroundColor: AppStyles.borderColor,
                  fontFamily: 'monospace',
                ),
                'a': Style(color: AppStyles.colorBaseBlue),
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
