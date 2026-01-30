import 'package:flutter/material.dart';
import 'profile_summary_screen.dart';
import 'swipe_screen.dart';
import 'matches_screen.dart';
import 'chat_list_screen.dart';

class AppShell extends StatefulWidget {
  final String userId;

  const AppShell({super.key, required this.userId});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _tabs = [
    ('Profile', Icons.person),
    ('Swipe', Icons.favorite),
    ('Matches', Icons.people),
    ('Chat', Icons.chat),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      ProfileSummaryScreen(userId: widget.userId),
      SwipeScreen(userId: widget.userId),
      MatchesScreen(userId: widget.userId),
      ChatListScreen(userId: widget.userId),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF111316),
        selectedItemColor: const Color(0xFFFF4458),
        unselectedItemColor: Colors.white54,
        items: _tabs
            .map((t) => BottomNavigationBarItem(
                  icon: Icon(t.$2),
                  label: t.$1,
                ))
            .toList(),
      ),
    );
  }
}
