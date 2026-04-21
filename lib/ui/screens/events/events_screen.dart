import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/event.dart';
import 'package:app_events/ui/providers/event_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/widgets/events/add_event.dart';
import 'package:app_events/ui/widgets/events/card_event.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<UserProvider>(context).isAdmin;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.eventsTitle),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.of(
                  context,
                ).push(CupertinoPageRoute(builder: (_) => const AddEvent()));
              },
            ),
        ],
      ),
      body: StreamBuilder<List<Event>>(
        stream: Provider.of<EventProvider>(context, listen: false).eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.twistingDots(
                leftDotColor: AppStyles.colorBaseBlue,
                rightDotColor: AppStyles.colorBaseYellow,
                size: 40,
              ),
            );
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(
              child: Text(
                AppStrings.eventsNoData,
                style: TextStyle(color: AppStyles.fontSecondaryColor),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: events.length,
            itemBuilder: (_, index) => CardEvent(event: events[index]),
          );
        },
      ),
    );
  }
}
