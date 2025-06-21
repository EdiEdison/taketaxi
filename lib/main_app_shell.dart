import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taketaxi/core/constants/colors.dart';

class MainAppShell extends StatefulWidget {
  final Widget child;
  const MainAppShell({super.key, required this.child});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _getPageIndex(GoRouterState state) {
    final location = state.uri.toString();
    if (location.startsWith('/main/home')) {
      return 0;
    }
    if (location.startsWith('/main/activity')) {
      return 1;
    }
    if (location.startsWith('/main/profile')) {
      return 2;
    }
    return 0; // Default to home if no match
  }

  @override
  Widget build(BuildContext context) {
    final GoRouterState routerState = GoRouterState.of(context);
    final int currentIndex = _getPageIndex(routerState);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: currentIndex,
        selectedItemColor: AppColors.selectedTabColor,
        unselectedItemColor: AppColors.black,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/main/home');
              break;
            case 1:
              context.go('/main/activity');
              break;
            case 2:
              context.go('/main/profile');
              break;
          }
        },
      ),
    );
  }
}
