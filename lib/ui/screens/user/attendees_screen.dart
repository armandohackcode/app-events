import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/widgets/utils/modal_confirm.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class AttendeesScreen extends StatefulWidget {
  const AttendeesScreen({super.key});

  @override
  State<AttendeesScreen> createState() => _AttendeesScreenState();
}

class _AttendeesScreenState extends State<AttendeesScreen> {
  final _paramSearch = TextEditingController();
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final data = Provider.of<UserProvider>(context, listen: false);

      data.getAttendees();
    });
    super.initState();
  }

  @override
  void dispose() {
    _paramSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataCenter = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.attendeesList)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextFormField(
              controller: _paramSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: AppStrings.attendeesSearchHint,
                suffixIcon: (_paramSearch.text.isNotEmpty)
                    ? IconButton(
                        onPressed: () {
                          dataCenter.getAttendees();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : const Icon(
                        Icons.search,
                        color: AppStyles.fontColor,
                        size: 32,
                      ),
              ),
              onFieldSubmitted: (value) async {
                await dataCenter.searchAttendees(param: value);
              },
            ),
          ),
          (dataCenter.loadingAttendees)
              ? Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  alignment: Alignment.center,
                  child: Center(
                    child: LoadingAnimationWidget.twistingDots(
                      leftDotColor: AppStyles.colorBaseBlue,
                      rightDotColor: AppStyles.colorBaseYellow,
                      size: 40,
                    ),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: dataCenter.attendees.length,
                    padding: const EdgeInsets.all(15),
                    itemBuilder: (BuildContext context, int index) {
                      var item = dataCenter.attendees[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CardAttendees(item: item),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}

class CardAttendees extends StatefulWidget {
  const CardAttendees({super.key, required this.item});

  final UserCompetitor item;

  @override
  State<CardAttendees> createState() => _CardAttendeesState();
}

class _CardAttendeesState extends State<CardAttendees> {
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    final data = Provider.of<UserProvider>(context, listen: false);
    return ListTile(
      title: Text(
        widget.item.name,
        style: TextStyle(color: AppStyles.fontColor),
      ),
      trailing: (loading)
          ? const CircularProgressIndicator()
          : ElevatedButton(
              onPressed: () async {
                setState(() {
                  loading = true;
                });
                var res = await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => ModalConfirm(
                    text:
                        "${AppStrings.attendeesMsConfirmAddPoints}\n ${widget.item.name}?",
                  ),
                );

                if (res == true) {
                  await data.addScoreAdmin(widget.item.uuid);
                  if (context.mounted) {
                    customSnackbar(
                      context,
                      "${AppStrings.attendeeMsConfirmAddPointsSuccess} \n ${widget.item.name}",
                    );
                  }
                }
                setState(() {
                  loading = false;
                });
              },
              child: const Icon(Icons.add_chart),
            ),
    );
  }
}
