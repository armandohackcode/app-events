import 'package:app_events/domain/bloc/data_center.dart';
import 'package:app_events/domain/bloc/sign_in_social_network.dart';
import 'package:app_events/ui/widgets/utils/modal_confirm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeleteAccount extends StatelessWidget {
  const DeleteAccount({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<SignInSocialNetworkProvider>(context);
    final data = Provider.of<DataCenter>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Eliminar cuenta"),
      ),
      body: Column(children: [
        const Padding(
          padding: EdgeInsets.all(15.0),
          child: Text(
              " La aplicación no utiliza ninguna información del usuario, los datos solicitados tienen el único proposito de brindar una mejor experiencia del usuario. \n\n El usuario es libre de eliminar la información generada en la aplicación en todo momento, con efecto inmmediato. y de forma irreversible."),
        ),
        Center(
            child: ElevatedButton(
                onPressed: () async {
                  var res = await showDialog<bool?>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const ModalConfirm(
                      text:
                          "⚠️ Esta seguro de Elimiar su cuenta? \n\n esta acción es irreversible",
                    ),
                  );
                  // print(res);
                  if (res == true) {
                    data.userCompetitor = null;
                    auth.isAuth = false;
                    await auth.logOut();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
                child: const Text("Eliminar cuenta")))
      ]),
    );
  }
}
