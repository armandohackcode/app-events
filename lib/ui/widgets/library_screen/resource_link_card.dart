import 'package:any_link_preview/any_link_preview.dart';
import 'package:app_events/domain/models/resource_library.dart';
import 'package:app_events/ui/widgets/library_screen/resource_card.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';

/// [ResourceCard] of [resource] that fills its image and description from the
/// preview of the link, the same source the library already used. While the
/// preview loads, or if it fails, the card shows only what the resource has.
class ResourceLinkCard extends StatelessWidget {
  final ResourceLibrary resource;
  const ResourceLinkCard({super.key, required this.resource});

  @override
  Widget build(BuildContext context) {
    final plain = ResourceCard(
      title: resource.title,
      link: resource.link,
      type: resource.type,
      onTap: () => launcherUrlInfo(resource.link),
    );
    return AnyLinkPreview.builder(
      link: resource.link,
      cache: const Duration(days: 1),
      placeholderWidget: plain,
      errorWidget: plain,
      itemBuilder: (context, metadata, image, svg) {
        final description = metadata.desc;
        return ResourceCard(
          title: resource.title,
          link: resource.link,
          type: resource.type,
          description: description == resource.link ? null : description,
          image: image,
          onTap: () => launcherUrlInfo(resource.link),
        );
      },
    );
  }
}
