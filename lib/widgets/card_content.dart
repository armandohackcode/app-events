import 'package:flutter/material.dart';

class CardContent extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  const CardContent({super.key, required this.child, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: const Alignment(-0.95, -0.85),
      children: [
        Container(
          decoration: BoxDecoration(
              border: Border.all(width: 1.5),
              borderRadius: BorderRadius.circular(10)),
          height: height,
          width: width,
          child: child,
        ),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 10),
            SizedBox(width: 3),
            Icon(Icons.circle, size: 10)
          ],
        )
      ],
    );
  }
}
