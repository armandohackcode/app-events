import 'package:animate_do/animate_do.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:app_events/bloc/data_center.dart';
import 'package:app_events/constants.dart';
import 'package:app_events/widgets/library_screen/add_resource.dart';
import 'package:app_events/widgets/utils/utils_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
      final data = Provider.of<DataCenter>(context, listen: false);
      if (data.resources.isEmpty) {
        data.getResources();
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
    final dataCenter = Provider.of<DataCenter>(context);
    return Scaffold(
      appBar: AppBar(title: SvgPicture.asset('assets/img/logo.svg')),
      body: RefreshIndicator(
        onRefresh: () async {
          await dataCenter.getResources();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 15, left: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'Biblioteca de recursos',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    controller: _paramSearch,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar contenido',
                      suffixIcon: (_paramSearch.text.isNotEmpty)
                          ? IconButton(
                              onPressed: () {
                                dataCenter.getResources();
                                _paramSearch.clear();
                              },
                              icon: const Icon(Icons.clear))
                          : const Icon(
                              Icons.search,
                              size: 32,
                            ),
                    ),
                    onFieldSubmitted: (value) async {
                      await dataCenter.searchResource(param: value);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ButtonLibrary(
                        color: AppStyles.colorBaseBlue,
                        active: dataCenter.activeWeb,
                        text: 'Web',
                        onPressed: () async {
                          dataCenter.activeWeb = !dataCenter.activeWeb;

                          await dataCenter.searchResource(
                              param: _paramSearch.text);
                        },
                      ),
                      ButtonLibrary(
                        active: dataCenter.activeMobile,
                        color: AppStyles.colorBaseGreen,
                        text: 'Mobile',
                        onPressed: () async {
                          dataCenter.activeMobile = !dataCenter.activeMobile;

                          await dataCenter.searchResource(
                              param: _paramSearch.text);
                        },
                      ),
                      ButtonLibrary(
                        active: dataCenter.activeCloud,
                        color: AppStyles.colorBaseRed,
                        text: 'Cloud',
                        onPressed: () async {
                          dataCenter.activeCloud = !dataCenter.activeCloud;

                          await dataCenter.searchResource(
                              param: _paramSearch.text);
                        },
                      ),
                      ButtonLibrary(
                        active: dataCenter.activeIA,
                        color: AppStyles.colorBaseYellow,
                        text: 'IA',
                        onPressed: () async {
                          dataCenter.activeIA = !dataCenter.activeIA;
                          await dataCenter.searchResource(
                              param: _paramSearch.text);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (dataCenter.loadingResource)
              Container(
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
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: dataCenter.resources.length,
                  itemBuilder: (BuildContext context, int index) {
                    var item = dataCenter.resources[index];
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
              )
          ],
        ),
      ),
      floatingActionButton: (dataCenter.isAdmin)
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(context,
                    CupertinoPageRoute(builder: (_) => const AddResource()));
              },
              child: const Icon(
                Icons.note_add_outlined,
                size: 32,
              ),
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
      default:
        return AppStyles.colorBaseBlue;
    }
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
    return Stack(
      alignment: const Alignment(0, -0.96),
      children: [
        InkWell(
          onTap: () async {
            await laucherUrlInfo(link);
          },
          child: Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: AppStyles.fontColor),
              borderRadius: BorderRadius.circular(10),
            ),
            width: width ?? MediaQuery.of(context).size.width * 0.45,
            child: Column(
              children: [
                Container(
                    padding: const EdgeInsets.all(10),
                    width: width,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    )),
                Container(
                  padding: const EdgeInsets.all(1),
                  height: 60,
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
                    displayDirection: UIDirection.uiDirectionHorizontal,
                    showMultimedia: true,
                    bodyMaxLines: 5,
                    bodyTextOverflow: TextOverflow.ellipsis,
                    titleStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    bodyStyle: const TextStyle(color: Colors.grey, fontSize: 9),
                    errorBody: 'Show my custom error body',
                    errorTitle: 'Show my custom error title',

                    errorWidget: Row(
                      children: [
                        Image.network(
                          'https://img.icons8.com/?size=512&id=92941&format=png',
                          width: 60,
                          height: 60,
                        ),
                        Container(
                          color: Colors.grey[100],
                          child: Text(title),
                        ),
                      ],
                    ),
                    errorImage:
                        "https://img.icons8.com/?size=512&id=92941&format=png",
                    cache: const Duration(days: 1),
                    backgroundColor: Colors.grey[100],
                    borderRadius: 6,
                    removeElevation: true,
                    // This disables tap event
                  ),
                ),
              ],
            ),
          ),
        ),
        Stack(
          alignment: const Alignment(-0.9, 0),
          children: [
            Container(
              height: 12,
              width: width ?? MediaQuery.of(context).size.width * 0.445,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: AppStyles.backgroundColor,
                ),
                SizedBox(width: 3),
                Icon(Icons.circle, size: 8, color: AppStyles.backgroundColor)
              ],
            )
          ],
        ),
      ],
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
        backgroundColor:
            widget.active ? widget.color : AppStyles.backgroundColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(
              color: widget.active ? AppStyles.fontColor : widget.color,
              width: 1.2),
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
