import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';

class MainScaffold extends StatelessWidget {
  final Widget body;
  final int? currentIndex;
  final bool showAppBar;
  final bool hideNavigationBar;

  const MainScaffold({
    super.key,
    required this.body,
    this.currentIndex,
    this.showAppBar = true,
    this.hideNavigationBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
          showAppBar
              ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: AppBar(
                  backgroundColor: AppTheme.accentColor,
                  automaticallyImplyLeading: false,
                  elevation: 2,
                  title: const Text(
                    'ItinerMe',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTheme.titleFontSize,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  centerTitle: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                ),
              )
              : null,
      body: SafeArea(child: body),
      bottomNavigationBar:
          hideNavigationBar
              ? null
              : SizedBox(
                height: 85,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [AppTheme.defaultShadow],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: BottomNavigationBar(
                      currentIndex: currentIndex ?? 0,
                      type: BottomNavigationBarType.fixed,
                      backgroundColor: Colors.white,
                      selectedItemColor: AppTheme.primaryColor,
                      unselectedItemColor: AppTheme.hintColor,
                      selectedLabelStyle: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: theme.textTheme.labelSmall,
                      elevation: 2,
                      iconSize: 24,
                      items: [
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Icon(Icons.grid_view_rounded),
                          ),
                          label: 'Home',
                        ),
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Icon(Icons.travel_explore_rounded),
                          ),
                          label: 'Trips',
                        ),
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Icon(Icons.add_rounded),
                          ),
                          label: 'Create',
                        ),
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Icon(Icons.person_rounded),
                          ),
                          label: 'Profile',
                        ),
                      ],
                      onTap: (index) {
                        switch (index) {
                          case 0:
                            Navigator.pushNamed(context, AppRoutes.dashboard);
                            break;
                          case 1:
                            Navigator.pushNamed(
                              context,
                              AppRoutes.myCollection,
                            );
                            break;
                          case 2:
                            Navigator.pushNamed(context, AppRoutes.createTrip);
                            break;
                          case 3:
                            Navigator.pushNamed(context, AppRoutes.account);
                            break;
                        }
                      },
                    ),
                  ),
                ),
              ),
    );
  }
}
