import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'home/home_screen.dart';
import 'home/add_transaction_screen.dart';
import 'activity/activity_screen.dart';
import 'calendar/calendar_screen.dart';
import 'more/more_screen.dart';

class MainScreen extends StatefulWidget {
  final int userId;

  const MainScreen({super.key, required this.userId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _refreshVersion = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _buildScreens();
  }

  void _buildScreens() {
    _screens = [
      HomeScreen(key: ValueKey('home_$_refreshVersion'), userId: widget.userId),
      ActivityScreen(
        key: ValueKey('activity_$_refreshVersion'),
        userId: widget.userId,
      ),
      CalendarScreen(
        key: ValueKey('calendar_$_refreshVersion'),
        userId: widget.userId,
      ),
      MoreScreen(userId: widget.userId),
    ];
  }

  void _onNavigationItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _openAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(userId: widget.userId),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _refreshVersion++;
        _buildScreens();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildAddButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      color: AppColors.surface,
      elevation: 10,
      padding: EdgeInsets.zero,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 66,
        child: Row(
          children: [
            _buildNavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
            _buildNavItem(
              icon: Icons.receipt_long_rounded,
              label: 'Activity',
              index: 1,
            ),
            const SizedBox(width: 58),
            _buildNavItem(
              icon: Icons.calendar_month_rounded,
              label: 'Calendar',
              index: 2,
            ),
            _buildNavItem(
              icon: Icons.more_horiz_rounded,
              label: 'More',
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool selected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onNavigationItemTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textMuted,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: 58,
      height: 58,
      child: FloatingActionButton(
        onPressed: _openAddTransaction,
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: AppColors.white, size: 30),
      ),
    );
  }
}
