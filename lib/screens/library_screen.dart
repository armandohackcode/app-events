import 'package:any_link_preview/any_link_preview.dart';
import 'package:app_events/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: SvgPicture.asset('assets/img/logo.svg')),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          const Text(
            'Biblioteca de recursos',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'Buscar contenido',
              suffixIcon: Icon(
                Icons.search,
                size: 32,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ButtonLibrary(
                color: AppStyles.colorBaseBlue,
                text: 'Web',
                onPressed: () {},
              ),
              ButtonLibrary(
                color: AppStyles.colorBaseGreen,
                text: 'Mobile',
                onPressed: () {},
              ),
              ButtonLibrary(
                color: AppStyles.colorBaseRed,
                text: 'Cloud',
                onPressed: () {},
              ),
              ButtonLibrary(
                color: AppStyles.colorBaseYellow,
                text: 'IA',
                onPressed: () {},
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: CardLibrary(
              width: MediaQuery.of(context).size.width,
              link: 'https://www.youtube.com/watch?v=6FoKDYDJ4V8',
              title: "Mongo con node JS",
              color: AppStyles.colorBaseRed,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: CardLibrary(
              width: MediaQuery.of(context).size.width,
              link: 'https://flutter.dev/',
              title: "Documentación Oficial de Flutter",
              color: AppStyles.colorBaseGreen,
            ),
          ),
        ],
      ),
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
    return Stack(
      alignment: const Alignment(0, -0.96),
      children: [
        Container(
          padding: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: AppStyles.fontColor),
            borderRadius: BorderRadius.circular(10),
          ),
          width: width ?? MediaQuery.of(context).size.width * 0.45,
          child: Column(
            children: [
              // Container(
              //     padding: const EdgeInsets.all(10),
              //     width: width,
              //     child: Text(
              //       title,
              //       textAlign: TextAlign.center,
              //       style: const TextStyle(fontWeight: FontWeight.w500),
              //     )),
              Container(
                padding: const EdgeInsets.all(1),
                height: 80,
                child: AnyLinkPreview(
                  link: link,
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
                  errorWidget: Container(
                    color: Colors.grey[100],
                    child: const Text('Oops!'),
                  ),
                  errorImage: "https://gdg.community.dev/gdg-sucre/",
                  cache: const Duration(days: 7),
                  backgroundColor: Colors.grey[100],
                  borderRadius: 6,
                  removeElevation: true,
                  // This disables tap event
                ),
              ),
            ],
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
  const ButtonLibrary({
    super.key,
    required this.color,
    required this.text,
    required this.onPressed,
  });

  @override
  State<ButtonLibrary> createState() => _ButtonLibraryState();
}

class _ButtonLibraryState extends State<ButtonLibrary> {
  bool _active = false;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: _active ? AppStyles.backgroundColor : widget.color,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppStyles.fontColor, width: 1),
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Text(
        widget.text,
        style: TextStyle(
          color: _active ? AppStyles.fontColor : AppStyles.backgroundColor,
        ),
      ),
      onPressed: () {
        setState(() {
          _active = !_active;
        });
        widget.onPressed;
      },
    );
  }
}
