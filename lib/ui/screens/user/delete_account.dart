import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/providers/sign_in_social_network.dart';
import 'package:app_events/ui/providers/spin_admin_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/widgets/utils/modal_confirm.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeleteAccount extends StatelessWidget {
  const DeleteAccount({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<SignInSocialNetworkProvider>(context);
    final data = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.deleteAccount)),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: Text(AppStrings.deleteAccountDescription),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                final spinProvider = maybeProvider<GdgSpinProvider>(
                  context,
                  listen: false,
                );
                final spinAdminProvider = maybeProvider<SpinAdminProvider>(
                  context,
                  listen: false,
                );
                var res = await showDialog<bool?>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const ModalConfirm(text: AppStrings.deleteAccountConfirm),
                );
                if (res == true) {
                  data.clearSession();
                  spinProvider?.unbind();
                  spinAdminProvider?.unbind();
                  auth.isAuth = false;
                  await auth.logOut();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text(AppStrings.deleteAccount),
            ),
          ),
        ],
      ),
    );
  }
}
