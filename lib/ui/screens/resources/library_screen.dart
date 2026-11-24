import 'package:animate_do/animate_do.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/resource_library.dart';
import 'package:app_events/ui/providers/resources_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/widgets/home/home_backdrop.dart';
import 'package:app_events/ui/widgets/library_screen/add_resource.dart';
import 'package:app_events/ui/widgets/library_screen/library_search_field.dart';
import 'package:app_events/ui/widgets/library_screen/resource_category_tiles.dart';
import 'package:app_events/ui/widgets/library_screen/resource_count_badge.dart';
import 'package:app_events/ui/widgets/library_screen/resource_link_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _paramSearch = TextEditingController();

  static const double _gutter = 18;

  /// Technology area chosen in the category tiles. Null shows every resource.
  String? _selectedType;

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
    final visible = resource.resources
        .where((item) => _selectedType == null || item.type == _selectedType)
        .toList();
    return Scaffold(
      backgroundColor: AppStyles.homeBackgroundColor,
      body: HomeBackdrop(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await resource.loadResources();
            },
            displacement: 40,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(_gutter, 8, _gutter, 0),
                  sliver: SliverToBoxAdapter(
                    child: HomeHeaderDecoration(child: HomeHeader()),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _LibraryHeader(count: resource.resources.length),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _gutter,
                      14,
                      _gutter,
                      14,
                    ),
                    child: LibrarySearchField(
                      controller: _paramSearch,
                      onSubmitted: (value) =>
                          resource.searchResource(param: value),
                      onClear: () {
                        resource.loadResources();
                        _paramSearch.clear();
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ResourceCategoryTiles(
                    selectedType: _selectedType,
                    onSelected: (type) => setState(() => _selectedType = type),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(_gutter, 4, _gutter, 14),
                    child: Text(
                      _selectedType ?? AppStrings.resourceLibraryAllContent,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppStyles.fontColor,
                      ),
                    ),
                  ),
                ),
                ..._content(context, resource, visible),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
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

  List<Widget> _content(
    BuildContext context,
    ResourcesProvider resource,
    List<ResourceLibrary> visible,
  ) {
    if (resource.loadingResource) {
      return [
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.3,
            child: Center(
              child: LoadingAnimationWidget.twistingDots(
                leftDotColor: AppStyles.colorBaseBlue,
                rightDotColor: AppStyles.colorBaseYellow,
                size: 40,
              ),
            ),
          ),
        ),
      ];
    }
    if (visible.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.3,
            child: const Center(
              child: Text(
                AppStrings.resourceLibraryNoData,
                style: TextStyle(
                  color: AppStyles.fontColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: _gutter),
        sliver: SliverList.separated(
          itemCount: visible.length,
          separatorBuilder: (_, _) => const SizedBox(height: 18),
          itemBuilder: (context, index) {
            final item = visible[index];
            return FadeInUp(
              from: 12,
              duration: const Duration(milliseconds: 380),
              child: ResourceLinkCard(key: ValueKey(item.link), resource: item),
            );
          },
        ),
      ),
    ];
  }
}

class _LibraryHeader extends StatelessWidget {
  final int count;
  const _LibraryHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.navBarLibrary,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppStyles.fontColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  AppStrings.resourceLibraryDescriptionText,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: AppStyles.fontSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ResourceCountBadge(count: count),
        ],
      ),
    );
  }
}
