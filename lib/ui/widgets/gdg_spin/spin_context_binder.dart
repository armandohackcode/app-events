import 'dart:async';

import 'package:app_events/ui/providers/event_provider.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/providers/sign_in_social_network.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/widgets.dart';

/// Resolves `(eventId, uid)` from optional ancestor providers.
({String? eventId, String? uid}) resolveSpinContextIds(
  BuildContext context, {
  String? eventIdOverride,
  String? uidOverride,
  bool listen = true,
}) {
  final eventProvider = maybeProvider<EventProvider>(context, listen: listen);
  final userProvider = maybeProvider<UserProvider>(context, listen: listen);
  final authProvider = maybeProvider<SignInSocialNetworkProvider>(
    context,
    listen: listen,
  );

  final eventId = _firstNonEmpty([
    eventIdOverride,
    eventProvider?.activeEvent?.id,
    userProvider?.userCompetitor?.currentEventId,
  ]);

  final authUid = (authProvider != null && authProvider.isAuth)
      ? authProvider.userInfo.uid
      : null;
  final uid = _firstNonEmpty([
    uidOverride,
    authUid,
    userProvider?.userCompetitor?.uuid,
  ]);
  return (eventId: eventId, uid: uid);
}

final Expando<bool> _boundByContext = Expando<bool>('spinBoundByContext');

/// Schedules lazy `EventProvider.loadEvents()` (once) and binds or unbinds
/// [GdgSpinProvider] after the current frame when `(eventId, uid)` changes.
bool scheduleSpinContextBinding(
  BuildContext context, {
  required GdgSpinProvider spinProvider,
  required bool alreadyRequestedEvents,
  String? eventIdOverride,
  String? uidOverride,
}) {
  var requestedEvents = alreadyRequestedEvents;
  final eventProvider = maybeProvider<EventProvider>(context, listen: false);
  final authProvider = maybeProvider<SignInSocialNetworkProvider>(
    context,
    listen: false,
  );
  final needsEventsLoad =
      !requestedEvents &&
      eventProvider != null &&
      eventProvider.events.isEmpty &&
      !eventProvider.loading;
  if (needsEventsLoad) {
    requestedEvents = true;
  }

  final ids = resolveSpinContextIds(
    context,
    eventIdOverride: eventIdOverride,
    uidOverride: uidOverride,
    listen: false,
  );
  final hasFullContext = ids.eventId != null && ids.uid != null;
  if (hasFullContext) {
    _boundByContext[spinProvider] = true;
  }

  final hasExplicitContext =
      eventProvider != null ||
      authProvider != null ||
      eventIdOverride != null ||
      uidOverride != null;
  final shouldUnbind =
      !hasFullContext &&
      spinProvider.isBound &&
      (hasExplicitContext || (_boundByContext[spinProvider] ?? false));

  final shouldBind =
      hasFullContext &&
      (spinProvider.boundEventId != ids.eventId ||
          spinProvider.boundUid != ids.uid);

  if (needsEventsLoad || shouldBind || shouldUnbind) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (needsEventsLoad &&
          eventProvider.events.isEmpty &&
          !eventProvider.loading) {
        unawaited(eventProvider.loadEvents().catchError((_) {}));
      }
      if (shouldUnbind) {
        _boundByContext[spinProvider] = false;
        spinProvider.unbind();
      } else if (shouldBind) {
        unawaited(spinProvider.bind(eventId: ids.eventId!, uid: ids.uid!));
      }
    });
  }

  return requestedEvents;
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}
