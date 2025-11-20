import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SidebarNav extends StatelessWidget {
  const SidebarNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _DrawerHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  onTap: () => context.go('/'),
                ),
                _NavItem(
                  icon: Icons.analytics_outlined,
                  title: 'Quick Analysis',
                  onTap: () => context.go('/quick-analysis'),
                ),
                _NavItem(
                  icon: Icons.signal_cellular_alt,
                  title: 'Daily Signals',
                  onTap: () => context.go('/daily-signals'),
                ),
                _NavItem(
                  icon: Icons.schedule_outlined,
                  title: 'Market Sessions',
                  onTap: () => context.go('/market-sessions'),
                ),
                _NavItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'Trading Calendar',
                  onTap: () => context.go('/trading-calendar'),
                ),
                _NavItem(
                  icon: Icons.chat_outlined,
                  title: 'AI Chat Bot',
                  onTap: () => context.go('/chat-bot'),
                ),
                const Divider(),
                _NavItem(
                  icon: Icons.payment_outlined,
                  title: 'Pricing',
                  onTap: () => context.go('/pricing'),
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),
          const Divider(),
          _ThemeToggle(),
          _LogoutButton(),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return UserAccountsDrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          accountName: Text(
            authProvider.currentUser?.name ?? 'Trader',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          accountEmail: Text(
            authProvider.currentUser?.email ?? 'trader@example.com',
          ),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.white,
            child: Text(
              (authProvider.currentUser?.name ?? 'T')[0].toUpperCase(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return SwitchListTile(
          secondary: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          ),
          title: const Text('Dark Mode'),
          value: themeProvider.isDarkMode,
          onChanged: (value) {
            themeProvider.toggleTheme();
          },
        );
      },
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () {
            Navigator.pop(context);
            authProvider.logout();
            context.go('/auth/login');
          },
        );
      },
    );
  }
}