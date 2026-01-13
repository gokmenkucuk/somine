import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';

import 'package:somine_app/core/design/app_colors_extension.dart';
// import 'package:somine_app/core/design/app_colors.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/screens/item_feed_screen.dart';
import 'package:somine_app/screens/search_screen.dart';
import 'package:somine_app/screens/profile_screen.dart';
import 'package:somine_app/screens/catalog_screen.dart';
import 'package:somine_app/screens/add_content_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  // Sharing Subscription
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _setupSharingIntent();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _setupSharingIntent() {
     _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> value) {
            if (value.isNotEmpty && value.first.path.isNotEmpty) {
              if (mounted) _openAddContentScreen(initialText: value.first.path);
            }
          }, onError: (err) => debugPrint("getMediaStream error: $err"));

    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty && value.first.path.isNotEmpty) {
        if (mounted) _openAddContentScreen(initialText: value.first.path);
      }
    });
  }

  void _openAddContentScreen({String? initialText}) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      useSafeArea: false, 
      backgroundColor: Colors.transparent, 
      barrierColor: Colors.black.withOpacity(0.5),
      enableDrag: true,
      builder: (context) => AddContentScreen(initialText: initialText),
    );

    if (result == true) {
      // Refresh feed content
      ref.invalidate(paginatedFeedProvider); 
      ref.invalidate(itemCountProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine active color for tabs
    Color getIconColor(int index) {
      return _selectedIndex == index ? context.colors.primary : context.colors.iconInactive; 
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true, // Important for floating dock style

      // FAB for Adding Content
      floatingActionButton: Container(
        width: 64, 
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [context.colors.primary, context.colors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: context.colors.surfaceWhite.withOpacity(0.2), // Subtle midnight-like border
            width: 1.5,
          ),
          boxShadow: [
             BoxShadow(
              color: context.colors.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openAddContentScreen(),
            customBorder: const CircleBorder(),
            splashColor: Colors.white.withOpacity(0.3),
            child: const Icon(PhosphorIconsLight.plus, color: Colors.white, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom Navigation Bar
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: context.colors.surfaceWhite, 
        elevation: 0,
        height: 60, // Slight height increase for touch target
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Feed
            IconButton(
              alignment: Alignment.topCenter,
              onPressed: () => _onItemTapped(0), 
              icon: Icon(
                _selectedIndex == 0 ? PhosphorIconsFill.house : PhosphorIconsLight.house, 
                color: getIconColor(0), 
                size: 26
              ),
            ),
            
            // Search
            IconButton(
              alignment: Alignment.topCenter,
              onPressed: () => _onItemTapped(1),
              icon: Icon(
                 _selectedIndex == 1 ? PhosphorIconsFill.magnifyingGlass : PhosphorIconsLight.magnifyingGlass,
                 color: getIconColor(1), 
                 size: 26
              ),
            ),
            
            const SizedBox(width: 48), // Spacer for FAB

            // Catalog (Squares)
            IconButton(
              alignment: Alignment.topCenter,
              onPressed: () => _onItemTapped(2),
              icon: Icon(
                _selectedIndex == 2 ? PhosphorIconsFill.squaresFour : PhosphorIconsLight.squaresFour,
                color: getIconColor(2), 
                size: 26
              ),
            ),

            // Profile
            IconButton(
              alignment: Alignment.topCenter,
              onPressed: () => _onItemTapped(3),
              icon: Icon(
                _selectedIndex == 3 ? PhosphorIconsFill.user : PhosphorIconsLight.user,
                color: getIconColor(3), 
                size: 26
              ),
            ),
          ],
        ),
      ),

      // Main Content Switching
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // 0: Feed
          ItemFeedScreen(
            onSearchTap: () => _onItemTapped(1), // Switch to Search Tab
          ),
          
          // 1: Search
          const SearchScreen(),

          // 2: Catalog
          const CatalogScreen(),

          // 3: Profile
          const ProfileScreen(),
        ],
      ),
    );
  }
}
