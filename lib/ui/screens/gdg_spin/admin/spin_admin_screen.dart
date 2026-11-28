import 'dart:async';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/providers/spin_admin_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/gdg_spin/admin/spin_admin_control_tab.dart';
import 'package:app_events/ui/screens/gdg_spin/admin/spin_admin_missions_tab.dart';
import 'package:app_events/ui/screens/gdg_spin/admin/spin_admin_prizes_tab.dart';
import 'package:app_events/ui/screens/gdg_spin/admin/spin_admin_redeem_tab.dart';
import 'package:app_events/ui/screens/gdg_spin/admin/spin_admin_tickets_tab.dart';
import 'package:app_events/ui/screens/gdg_spin/admin/spin_admin_widgets.dart';
import 'package:app_events/ui/widgets/home/home_backdrop.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Five-tab administrative console for managing GDG SPIN during live events.
class SpinAdminScreen extends StatefulWidget {
  final String eventId;
  final String? eventTitle;

  const SpinAdminScreen({super.key, required this.eventId, this.eventTitle});

  @override
  State<SpinAdminScreen> createState() => _SpinAdminScreenState();
}

class _SpinAdminScreenState extends State<SpinAdminScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleBindIfNeeded();
  }

  @override
  void didUpdateWidget(covariant SpinAdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventId != widget.eventId) {
      _scheduleBindIfNeeded();
    }
  }

  void _scheduleBindIfNeeded() {
    final userProvider = maybeProvider<UserProvider>(context, listen: false);
    final adminProvider = maybeProvider<SpinAdminProvider>(
      context,
      listen: false,
    );
    if (adminProvider == null) return;

    final isAdmin = userProvider?.isAdmin ?? false;
    final hasEventId = widget.eventId.trim().isNotEmpty;
    if (!isAdmin || !hasEventId) {
      if (adminProvider.isBound) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final stillAdmin =
              maybeProvider<UserProvider>(context, listen: false)?.isAdmin ??
              false;
          if ((!stillAdmin || widget.eventId.trim().isEmpty) &&
              adminProvider.isBound) {
            adminProvider.unbind();
          }
        });
      }
      return;
    }

    if (adminProvider.boundEventId == widget.eventId) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final stillAdmin =
          maybeProvider<UserProvider>(context, listen: false)?.isAdmin ?? false;
      if (stillAdmin &&
          widget.eventId.trim().isNotEmpty &&
          adminProvider.boundEventId != widget.eventId) {
        unawaited(adminProvider.bind(widget.eventId));
      }
    });
  }

  Future<void> _handleRefresh(SpinAdminProvider provider) async {
    try {
      await provider.refreshDashboard();
    } catch (e) {
      if (!mounted) return;
      showSpinAdminFeedback(context, mapSpinAdminError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = maybeProvider<UserProvider>(context);
    final isAdmin = userProvider?.isAdmin ?? false;

    if (!isAdmin) {
      return _buildAccessDenied(context);
    }

    final adminProvider = context.watch<SpinAdminProvider>();
    final isBusy =
        adminProvider.isLoadingDashboard || adminProvider.isSubmitting;

    return DefaultTabController(
      length: 5,
      child: HomeBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leadingWidth: 44,
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: AppStyles.fontColor,
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.spinAdminTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: AppStyles.fontColor,
                  ),
                ),
                if (widget.eventTitle != null &&
                    widget.eventTitle!.trim().isNotEmpty)
                  Text(
                    widget.eventTitle!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppStyles.fontSecondaryColor,
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: AppStrings.spinAdminRefreshTooltip,
                onPressed: isBusy ? null : () => _handleRefresh(adminProvider),
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppStyles.fontColor,
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                decoration: BoxDecoration(
                  color: AppStyles.cardColor,
                  border: Border.all(color: AppStyles.borderColor, width: 2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppStyles.colorBaseYellow,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: AppStyles.borderColor,
                      width: 1.5,
                    ),
                  ),
                  labelColor: AppStyles.fontColor,
                  unselectedLabelColor: AppStyles.fontSecondaryColor,
                  labelStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: const [
                    Tab(text: AppStrings.spinAdminTabControl),
                    Tab(text: AppStrings.spinAdminTabPrizes),
                    Tab(text: AppStrings.spinAdminTabMissions),
                    Tab(text: AppStrings.spinAdminTabTickets),
                    Tab(text: AppStrings.spinAdminTabRedeem),
                  ],
                ),
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                if (isBusy)
                  const LinearProgressIndicator(
                    minHeight: 3,
                    color: AppStyles.colorBaseBlue,
                    backgroundColor: AppStyles.spinAdminProgressTrackColor,
                  ),
                if (adminProvider.lastError != null &&
                    adminProvider.config == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: HardShadowBox(
                      color: AppStyles.spinAdminDangerSurfaceColor,
                      radius: 14,
                      shadowOffset: 3,
                      borderWidth: 2,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppStyles.fontColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mapSpinAdminError(adminProvider.lastError!),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppStyles.fontColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChunkyButton(
                            label: AppStrings.spinRetryAction,
                            color: AppStyles.colorBaseYellow,
                            minHeight: 36,
                            fontSize: 12,
                            onPressed: () => _handleRefresh(adminProvider),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    children: [
                      SpinAdminControlTab(eventId: widget.eventId),
                      SpinAdminPrizesTab(eventId: widget.eventId),
                      SpinAdminMissionsTab(eventId: widget.eventId),
                      SpinAdminTicketsTab(eventId: widget.eventId),
                      SpinAdminRedeemTab(eventId: widget.eventId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return HomeBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: AppStyles.fontColor,
            ),
          ),
          title: const Text(
            AppStrings.spinAdminTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppStyles.fontColor,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: HardShadowBox(
                  color: AppStyles.spinWarnColor,
                  radius: 20,
                  shadowOffset: 5,
                  borderWidth: 2.5,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppStyles.cardColor,
                          border: Border.all(
                            color: AppStyles.borderColor,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 28,
                          color: AppStyles.fontColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        AppStrings.spinAdminAccessDenied,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppStyles.fontColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        AppStrings.spinAdminAccessDeniedBody,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppStyles.fontColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ChunkyButton(
                        label: AppStrings.spinAdminGoBack,
                        color: AppStyles.cardColor,
                        expand: true,
                        minHeight: 44,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
