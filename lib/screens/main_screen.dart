import 'package:flutter/material.dart';
import 'product_list_screen.dart';
import 'wishlist_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ValueNotifier<int> _tabIndexVN = ValueNotifier<int>(0);

  void _onItemTapped(int index) {
    _tabIndexVN.value = index;
  }

  void _showCatalogue() {
    _tabIndexVN.value = 0;
  }

  @override
  void dispose() {
    _tabIndexVN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _tabIndexVN,
      builder: (BuildContext context, int tabIndex, Widget? child) {
        return Scaffold(
          body: IndexedStack(
            index: tabIndex,
            children: <Widget>[
              const ProductListScreen(),
              WishlistScreen(onBrowseProducts: _showCatalogue),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tabIndex,
            onDestinationSelected: _onItemTapped,
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: 'Catalogue',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: 'Wishlist',
              ),
            ],
          ),
        );
      },
    );
  }
}
