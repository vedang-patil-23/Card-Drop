import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'leads_screen.dart';
import 'settings_screen.dart';
import 'share_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab        = 0;
  int _leadsEpoch = 0;

  void _onTab(int i) {
    HapticFeedback.selectionClick();
    if (i == 1) setState(() => _leadsEpoch++);
    setState(() => _tab = i);
  }

  void _openShare() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(_slideUp(const ShareScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _tab,
        children: [
          const HomeScreen(),
          LeadsScreen(key: ValueKey('leads-$_leadsEpoch')),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _NavBar(
        current: _tab,
        onTab: _onTab,
        onShare: _openShare,
      ),
    );
  }
}

Route<dynamic> _slideUp(Widget page) => PageRouteBuilder(
  fullscreenDialog: true,
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, a, __, child) => SlideTransition(
    position: Tween(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
    child: child,
  ),
);

// ── Nav bar ──────────────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTab;
  final VoidCallback onShare;
  const _NavBar({required this.current, required this.onTab, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 0.5, thickness: 0.5, color: Color(0xFF2C2C2C)),
          SizedBox(
            height: 56 + bottom,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottom),
              child: Row(
                children: [
                  _Tab(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Cards',
                    active: current == 0,
                    onTap: () => onTab(0),
                  ),
                  _Tab(
                    icon: Icons.people_outline_rounded,
                    activeIcon: Icons.people_alt_rounded,
                    label: 'Contacts',
                    active: current == 1,
                    onTap: () => onTab(1),
                  ),
                  _Tab(
                    icon: Icons.ios_share_outlined,
                    activeIcon: Icons.ios_share,
                    label: 'Share',
                    active: false,
                    onTap: onShare,
                  ),
                  _Tab(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    label: 'Settings',
                    active: current == 2,
                    onTap: () => onTab(2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab item ─────────────────────────────────────────────────────────────────

class _Tab extends StatefulWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.icon, required this.activeIcon,
      required this.label, required this.active, required this.onTap});
  @override State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _p = false;
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown:   (_) => setState(() => _p = true),
      onTapUp:     (_) { setState(() => _p = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _p = false),
      child: AnimatedScale(
        scale: _p ? 0.82 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.active ? widget.activeIcon : widget.icon,
              size: 24,
              color: widget.active ? Colors.white : const Color(0xFF555555),
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: widget.active ? Colors.white : const Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
