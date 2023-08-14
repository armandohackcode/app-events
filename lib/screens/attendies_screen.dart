import 'package:app_events/bloc/data_center.dart';
import 'package:app_events/constants.dart';
import 'package:app_events/models/user_competitor.dart';
import 'package:app_events/widgets/utils/modal_confirm.dart';
import 'package:app_events/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class AttendiesScrren extends StatefulWidget {
  const AttendiesScrren({super.key});

  @override
  State<AttendiesScrren> createState() => _AttendiesScrrenState();
}

class _AttendiesScrrenState extends State<AttendiesScrren> {
  final _paramSearch = TextEditingController();
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final data = Provider.of<DataCenter>(context, listen: false);

      data.getAttendies();
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
    final dataCenter = Provider.of<DataCenter>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Lista de participantes")),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: TextFormField(
            controller: _paramSearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar contenido',
              suffixIcon: (_paramSearch.text.isNotEmpty)
                  ? IconButton(
                      onPressed: () {
                        dataCenter.getAttendies();
                      },
                      icon: const Icon(Icons.clear))
                  : const Icon(
                      Icons.search,
                      size: 32,
                    ),
            ),
            onFieldSubmitted: (value) async {
              await dataCenter.searchAttendies(param: value);
            },
          ),
        ),
        (dataCenter.loadingAttendies)
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
                  itemCount: dataCenter.attendies.length,
                  padding: const EdgeInsets.all(15),
                  itemBuilder: (BuildContext context, int index) {
                    var item = dataCenter.attendies[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(10)),
                      child: CardAttendies(item: item),
                    );
                  },
                ),
              )
      ]),
    );
  }
}

class CardAttendies extends StatefulWidget {
  const CardAttendies({
    super.key,
    required this.item,
  });

  final UserCompetitor item;

  @override
  State<CardAttendies> createState() => _CardAttendiesState();
}

class _CardAttendiesState extends State<CardAttendies> {
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataCenter>(context, listen: false);
    return ListTile(
      title: Text(widget.item.name),
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
                        "Esta seguro de añadir 10 puntos a \n ${widget.item.name}",
                  ),
                );

                if (res == true) {
                  await data.addScoreAdmin(widget.item.uuid);
                  if (context.mounted) {
                    customSnackbar(context,
                        "Regalaste 10 puntos a \n ${widget.item.name}");
                  }
                }
                setState(() {
                  loading = false;
                });
              },
              child: const Icon(
                Icons.plus_one,
              ),
            ),
    );
  }
}
