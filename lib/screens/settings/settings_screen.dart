import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool emailAlerts = true;
  bool pushNotifications = true;
  bool darkMode = false;
  String selectedLanguage = 'English';
  String selectedCurrency = 'USD';

  final List<String> languages = ['English', 'Spanish', 'French', 'German', 'Chinese'];
  final List<String> currencies = ['USD', 'EUR', 'GBP', 'JPY', 'AUD'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.primaryPurple,
          ),
          onPressed: () {
            // Go back to Dashboard using GoRouter
            context.go('/dashboard');
          },
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileSection(),
            const SizedBox(height: 20),
            _buildNotificationSettings(),
            const SizedBox(height: 20),
            _buildPreferencesSection(),
            const SizedBox(height: 20),
            _buildSecuritySection(),
            const SizedBox(height: 20),
            _buildSupportSection(),
            const SizedBox(height: 20),
            _buildAccountSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: AppColors.primaryPurple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'John Trader',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'john.trader@email.com',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: AppColors.primaryPurple),
                  onPressed: () => _editProfile(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'All Notifications',
              'Enable or disable all notifications',
              notificationsEnabled,
              (value) => setState(() => notificationsEnabled = value),
              Icons.notifications,
            ),
            _buildSwitchTile(
              'Email Alerts',
              'Receive trading signals via email',
              emailAlerts,
              (value) => setState(() => emailAlerts = value),
              Icons.email,
            ),
            _buildSwitchTile(
              'Push Notifications',
              'Get instant alerts on your device',
              pushNotifications,
              (value) => setState(() => pushNotifications = value),
              Icons.phone_android,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Dark Mode',
              'Switch to dark theme',
              darkMode,
              (value) => setState(() => darkMode = value),
              Icons.dark_mode,
            ),
            _buildDropdownTile(
              'Language',
              selectedLanguage,
              languages,
              (value) => setState(() => selectedLanguage = value!),
              Icons.language,
            ),
            _buildDropdownTile(
              'Base Currency',
              selectedCurrency,
              currencies,
              (value) => setState(() => selectedCurrency = value!),
              Icons.currency_exchange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              'Change Password',
              'Update your account password',
              Icons.lock,
              () => _changePassword(),
            ),
            _buildSettingsTile(
              'Two-Factor Authentication',
              'Add an extra layer of security',
              Icons.security,
              () => _setupTwoFA(),
            ),
            _buildSettingsTile(
              'Login Activity',
              'View recent login attempts',
              Icons.history,
              () => _viewLoginActivity(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              'Help Center',
              'Find answers to common questions',
              Icons.help,
              () => _openHelpCenter(),
            ),
            _buildSettingsTile(
              'Contact Support',
              'Get help from our team',
              Icons.support_agent,
              () => _contactSupport(),
            ),
            _buildSettingsTile(
              'Report a Bug',
              'Help us improve the app',
              Icons.bug_report,
              () => _reportBug(),
            ),
            _buildSettingsTile(
              'Rate App',
              'Share your feedback',
              Icons.star_rate,
              () => _rateApp(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              'Subscription',
              'Manage your subscription',
              Icons.payment,
              () => _manageSubscription(),
            ),
            _buildSettingsTile(
              'Privacy Policy',
              'Read our privacy policy',
              Icons.privacy_tip,
              () => _viewPrivacyPolicy(),
            ),
            _buildSettingsTile(
              'Terms of Service',
              'Read our terms of service',
              Icons.description,
              () => _viewTerms(),
            ),
            _buildSettingsTile(
              'Delete Account',
              'Permanently delete your account',
              Icons.delete_forever,
              () => _deleteAccount(),
              isDestructive: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _logout(),
                icon: Icon(Icons.logout, color: AppColors.primaryPurple),
                label: Text(
                  'Sign Out',
                  style: TextStyle(color: AppColors.primaryPurple),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primaryPurple),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryPurple),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.primaryNavy,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.textSecondary),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryPurple,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDropdownTile(
    String title,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryPurple),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.primaryNavy,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        underline: Container(),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.primaryPurple : AppColors.primaryPurple,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppColors.primaryPurple : AppColors.primaryNavy,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.textSecondary),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  // Action methods
  void _editProfile() => _showFeatureDialog('Edit Profile');
  void _changePassword() => _showFeatureDialog('Change Password');
  void _setupTwoFA() => _showFeatureDialog('Two-Factor Authentication');
  void _viewLoginActivity() => _showFeatureDialog('Login Activity');
  void _openHelpCenter() => _showFeatureDialog('Help Center');
  void _contactSupport() => _showFeatureDialog('Contact Support');
  void _reportBug() => _showFeatureDialog('Report Bug');
  void _rateApp() => _showFeatureDialog('Rate App');
  void _manageSubscription() => _showFeatureDialog('Subscription Management');
  void _viewPrivacyPolicy() => _showFeatureDialog('Privacy Policy');
  void _viewTerms() => _showFeatureDialog('Terms of Service');

  void _showFeatureDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('$feature feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Account deletion cancelled'),
                  backgroundColor: AppColors.primaryPurple,
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppColors.primaryPurple)),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Go back to Dashboard using GoRouter
              context.go('/dashboard');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully signed out'),
                  backgroundColor: AppColors.primaryNavy,
                ),
              );
            },
            child: Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}