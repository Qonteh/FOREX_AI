import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';

class MarketSessionsScreen extends StatefulWidget {
  const MarketSessionsScreen({super.key});

  @override
  State<MarketSessionsScreen> createState() => _MarketSessionsScreenState();
}

class _MarketSessionsScreenState extends State<MarketSessionsScreen> {
  final List<MarketSession> sessions = [
    MarketSession(
      name: 'Sydney',
      timeZone: 'GMT+11',
      openTime: '21:00',
      closeTime: '06:00',
      isActive: false,
      volume: 'Low',
      color: AppColors.primaryPurple,
    ),
    MarketSession(
      name: 'Tokyo',
      timeZone: 'GMT+9',
      openTime: '23:00',
      closeTime: '08:00',
      isActive: false,
      volume: 'Medium',
      color: AppColors.primaryNavy,
    ),
    MarketSession(
      name: 'London',
      timeZone: 'GMT+0',
      openTime: '07:00',
      closeTime: '16:00',
      isActive: true,
      volume: 'High',
      color: AppColors.primaryNavy,
    ),
    MarketSession(
      name: 'New York',
      timeZone: 'GMT-5',
      openTime: '12:00',
      closeTime: '21:00',
      isActive: true,
      volume: 'High',
      color: AppColors.primaryPurple,
    ),
  ];

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
          'Market Sessions',
          style: TextStyle(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.access_time, color: AppColors.primaryPurple),
            onPressed: () {
              // Show timezone selector
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCurrentTime(),
            const SizedBox(height: 20),
            _buildSessionOverview(),
            const SizedBox(height: 20),
            _buildSessionsList(),
            const SizedBox(height: 20),
            _buildTradingTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTime() {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppColors.primaryPurple.withOpacity(0.1),
              AppColors.primaryPurple.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Text(
              'Current GMT Time',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '14:35:27',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tuesday, November 18, 2025',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionOverview() {
    int activeSessions = sessions.where((session) => session.isActive).length;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    'Active Sessions',
                    activeSessions.toString(),
                    AppColors.primaryNavy,
                    Icons.radio_button_checked,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewCard(
                    'Market Activity',
                    'High',
                    AppColors.primaryPurple,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewCard(
                    'Best Pairs',
                    'EUR/USD',
                    AppColors.primaryPurple,
                    Icons.star,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trading Sessions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _buildSessionCard(session);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(MarketSession session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: session.isActive 
              ? session.color 
              : AppColors.mediumGray,
          width: session.isActive ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: session.isActive 
            ? session.color.withOpacity(0.05)
            : AppColors.mediumGray.withOpacity(0.05),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: session.isActive ? session.color : AppColors.mediumGray,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    Text(
                      session.timeZone,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: session.isActive 
                      ? AppColors.primaryNavy.withOpacity(0.1)
                      : AppColors.mediumGray.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  session.isActive ? 'OPEN' : 'CLOSED',
                  style: TextStyle(
                    color: session.isActive ? AppColors.primaryNavy : AppColors.mediumGray,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trading Hours',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${session.openTime} - ${session.closeTime}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Volume',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    session.volume,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTradingTips() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trading Tips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              Icons.schedule,
              'Best Trading Time',
              'London-NY overlap (12:00-16:00 GMT) for highest volatility',
              AppColors.primaryNavy,
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              Icons.volume_up,
              'High Volume Sessions',
              'London and New York sessions have the highest trading volume',
              AppColors.primaryPurple,
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              Icons.warning,
              'Low Activity Warning',
              'Sydney session typically has lower volatility and spreads',
              AppColors.primaryPurple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MarketSession {
  final String name;
  final String timeZone;
  final String openTime;
  final String closeTime;
  final bool isActive;
  final String volume;
  final Color color;

  MarketSession({
    required this.name,
    required this.timeZone,
    required this.openTime,
    required this.closeTime,
    required this.isActive,
    required this.volume,
    required this.color,
  });
}