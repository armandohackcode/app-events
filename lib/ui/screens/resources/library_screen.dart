import 'package:animate_do/animate_do.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/providers/resources_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/widgets/library_screen/add_resource.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _paramSearch = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final data = Provider.of<ResourcesProvider>(context, listen: false);
      if (data.resources.isEmpty) {
        data.loadResources();
      }
      data.cleanTag();
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
    final resource = Provider.of<ResourcesProvider>(context);
    final dataCenter = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Image.asset(AppAssetsPath.titleEvent, height: 50),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await resource.loadResources();
        },
        displacement: 40,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: false,
              floating: false,
              expandedHeight: 75,
              flexibleSpace: FlexibleSpaceBar(
                background: FiltersLibrary(
                  paramSearch: _paramSearch,
                  resourcesProvider: resource,
                ),
              ),
            ),
            // FiltersLibrary(
            //   paramSearch: _paramSearch,
            //   resourcesProvider: resource,
            // ),
            if (resource.loadingResource)
              SliverToBoxAdapter(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  alignment: Alignment.center,
                  child: Center(
                    child: LoadingAnimationWidget.twistingDots(
                      leftDotColor: AppStyles.colorBaseBlue,
                      rightDotColor: AppStyles.colorBaseYellow,
                      size: 40,
                    ),
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: resource.resources.length,
                itemBuilder: (BuildContext context, int index) {
                  var item = resource.resources[index];
                  return ZoomIn(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: CardLibrary(
                        key: UniqueKey(),
                        width: MediaQuery.of(context).size.width,
                        link: item.link,
                        title: item.title,
                        color: _getColor(item.type),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      floatingActionButton: (dataCenter.isAdmin)
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const AddResource()),
                );
              },
              child: const Icon(Icons.note_add_outlined, size: 32),
            )
          : null,
    );
  }

  Color _getColor(String area) {
    switch (area) {
      case "Web":
        return AppStyles.colorBaseBlue;
      case "Mobile":
        return AppStyles.colorBaseGreen;
      case "Cloud":
        return AppStyles.colorBaseRed;
      case "IA":
        return AppStyles.colorBaseYellow;
      case "UI/UX":
        return AppStyles.colorBasePurple;
      default:
        return AppStyles.colorBaseBlue;
    }
  }
}

class FiltersLibrary extends StatelessWidget {
  const FiltersLibrary({
    super.key,
    required TextEditingController paramSearch,
    required this.resourcesProvider,
  }) : _paramSearch = paramSearch;

  final TextEditingController _paramSearch;
  final ResourcesProvider resourcesProvider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            controller: _paramSearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: AppStrings.resourceLibrarySearchHint,
              suffixIcon: (_paramSearch.text.isNotEmpty)
                  ? IconButton(
                      onPressed: () {
                        resourcesProvider.loadResources();
                        _paramSearch.clear();
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
              await resourcesProvider.searchResource(param: value);
            },
          ),
        ),

        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: [
        //     ButtonLibrary(
        //       color: AppStyles.colorBaseBlue,
        //       active: resourcesProvider.activeWeb,
        //       text: 'Web',
        //       onPressed: () async {
        //         resourcesProvider.activeWeb = !resourcesProvider.activeWeb;

        //         await resourcesProvider.searchResource(
        //           param: _paramSearch.text,
        //         );
        //       },
        //     ),
        //     ButtonLibrary(
        //       active: resourcesProvider.activeMobile,
        //       color: AppStyles.colorBaseGreen,
        //       text: 'Mobile',
        //       onPressed: () async {
        //         resourcesProvider.activeMobile =
        //             !resourcesProvider.activeMobile;

        //         await resourcesProvider.searchResource(
        //           param: _paramSearch.text,
        //         );
        //       },
        //     ),
        //     ButtonLibrary(
        //       active: resourcesProvider.activeCloud,
        //       color: AppStyles.colorBaseRed,
        //       text: 'Cloud',
        //       onPressed: () async {
        //         resourcesProvider.activeCloud = !resourcesProvider.activeCloud;

        //         await resourcesProvider.searchResource(
        //           param: _paramSearch.text,
        //         );
        //       },
        //     ),
        //     ButtonLibrary(
        //       active: resourcesProvider.activeIA,
        //       color: AppStyles.colorBaseYellow,
        //       text: 'IA',
        //       onPressed: () async {
        //         resourcesProvider.activeIA = !resourcesProvider.activeIA;
        //         await resourcesProvider.searchResource(
        //           param: _paramSearch.text,
        //         );
        //       },
        //     ),
        //   ],
        // ),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     ButtonLibrary(
        //       active: resourcesProvider.activeUIUX,
        //       color: AppStyles.colorBasePurple,
        //       text: 'UI/UX',
        //       onPressed: () async {
        //         resourcesProvider.activeUIUX = !resourcesProvider.activeUIUX;
        //         await resourcesProvider.searchResource(
        //           param: _paramSearch.text,
        //         );
        //       },
        //     ),
        //   ],
        // ),
      ],
    );
  }
}

class CardLibrary extends StatelessWidget {
  final double? width;
  final double? heightLink;
  final String link;
  final Color color;
  final String title;
  const CardLibrary({
    super.key,
    required this.link,
    required this.color,
    required this.title,
    this.width,
    this.heightLink,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await laucherUrlInfo(link);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            // Container(
            //   padding: const EdgeInsets.all(10),
            //   width: width,
            //   child: Text(
            //     title,
            //     textAlign: TextAlign.center,
            //     style: const TextStyle(fontWeight: FontWeight.w500),
            //   ),
            // ),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.35,
              child: AnyLinkPreview(
                urlLaunchMode: LaunchMode.externalApplication,
                placeholderWidget: Center(
                  child: LoadingAnimationWidget.stretchedDots(
                    color: AppStyles.colorBaseBlue,
                    size: 40,
                  ),
                ),
                link: link,
                previewHeight: 1,
                displayDirection: UIDirection.uiDirectionVertical,
                showMultimedia: true,
                bodyMaxLines: 5,
                bodyTextOverflow: TextOverflow.ellipsis,
                titleStyle: TextStyle(
                  color: AppStyles.fontColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                bodyStyle: const TextStyle(
                  color: AppStyles.fontColor,
                  fontSize: 16,
                ),
                errorBody: 'Show my custom error body',
                errorTitle: 'Show my custom error title',

                errorWidget: Row(
                  children: [
                    Image.network(
                      'https://img.icons8.com/?size=512&id=92941&format=png',
                      width: 60,
                      height: 60,
                    ),
                    Container(color: Colors.grey[100], child: Text(title)),
                  ],
                ),
                errorImage:
                    "https://img.icons8.com/?size=512&id=92941&format=png",
                cache: const Duration(days: 1),
                backgroundColor: AppStyles.backgroundColor,
                borderRadius: 10,
                removeElevation: true,
                // This disables tap event
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ButtonLibrary extends StatefulWidget {
  final Color color;
  final VoidCallback onPressed;
  final String text;
  final bool active;
  const ButtonLibrary({
    super.key,
    required this.color,
    required this.text,
    required this.onPressed,
    required this.active,
  });

  @override
  State<ButtonLibrary> createState() => _ButtonLibraryState();
}

class _ButtonLibraryState extends State<ButtonLibrary> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: widget.active
            ? widget.color
            : AppStyles.backgroundColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: widget.active ? AppStyles.fontColor : widget.color,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      onPressed: widget.onPressed,
      child: Text(
        widget.text,
        style: TextStyle(
          color: widget.active ? AppStyles.backgroundColor : widget.color,
        ),
      ),
    );
  }
}
