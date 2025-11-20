import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final List<PricingPlan> plans = [
    PricingPlan(
      name: '💎 PREMIUM MONTHLY',
      price: 299.00,
      period: 'Monthly',
      originalPrice: 399.00,
      features: [
        '🚀 Unlimited Quick Analysis',
        '📅 Full Trading Calendar Access',
        '📊 Advanced AI Trading Signals',
        '⚡ Real-time Market Alerts',
        '🎯 Personalized Trading Strategies',
        '📱 Premium Mobile Features',
        '💬 Priority 24/7 Support',
        '📈 Advanced Risk Management',
        '🔔 Push Notifications',
        '📚 Exclusive Trading Courses',
      ],
      color: AppColors.primaryPurple,
      isPopular: false,
      badge: 'MONTHLY',
      savings: null,
    ),
    PricingPlan(
      name: '🏆 LIFETIME PRO',
      price: 1999.00,
      period: 'One Time',
      originalPrice: 3999.00,
      features: [
        '🌟 ALL Premium Features FOREVER',
        '💎 Lifetime Access - No Recurring Fees',
        '🚀 Future Updates Included FREE',
        '🎓 VIP Trading Masterclass Access',
        '📞 Direct Line to Trading Experts',
        '🔥 Exclusive VIP Discord Community',
        '📊 Custom Trading Bot Integration',
        '💰 Advanced Portfolio Analytics',
        '🎯 Personal Trading Coach Session',
        '🏅 Lifetime Achievement Badges',
        '🎁 Exclusive Bonuses & Perks',
        '⭐ VIP Status & Recognition',
      ],
      color: Colors.amber.shade700,
      isPopular: true,
      badge: 'BEST VALUE',
      savings: 'SAVE \$2000+',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryPurple.withOpacity(0.1),
              Colors.white,
              Colors.amber.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 30),
                          _buildPricingCards(),
                          const SizedBox(height: 30),
                          _buildFeatureComparison(),
                          const SizedBox(height: 30),
                          _buildTestimonials(),
                          const SizedBox(height: 30),
                          _buildGuarantee(),
                          const SizedBox(height: 30),
                          _buildFAQ(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back,
                color: AppColors.primaryPurple,
              ),
            ),
            onPressed: () => context.go('/dashboard'),
          ),
          Expanded(
            child: Text(
              'Upgrade to Pro',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade700),
            ),
            child: Text(
              '🔥 LIMITED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryPurple,
            AppColors.primaryPurple.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.diamond,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '🚀 UNLOCK PRO TRADING',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Join 50,000+ successful traders worldwide!\nGet unlimited access to all premium features.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flash_on, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  'Special Launch Offer - 50% OFF!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCards() {
    return Column(
      children: plans.asMap().entries.map((entry) {
        int index = entry.key;
        PricingPlan plan = entry.value;
        return AnimatedContainer(
          duration: Duration(milliseconds: 800 + (index * 200)),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.only(bottom: 20),
          child: _buildPricingCard(plan),
        );
      }).toList(),
    );
  }

  Widget _buildPricingCard(PricingPlan plan) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: plan.isPopular 
            ? [Colors.amber.shade50, Colors.amber.shade100]
            : [Colors.white, Colors.grey.shade50],
        ),
        border: Border.all(
          color: plan.isPopular ? Colors.amber.shade700 : AppColors.primaryPurple,
          width: plan.isPopular ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: plan.color.withOpacity(0.3),
            blurRadius: plan.isPopular ? 25 : 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Floating Badge
          if (plan.isPopular)
            Positioned(
              top: -10,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade600, Colors.amber.shade700],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      plan.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          
          Padding(
            padding: EdgeInsets.only(
              top: plan.isPopular ? 30 : 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              children: [
                // Plan Name
                Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: plan.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
                
                // Price Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: plan.color.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (plan.originalPrice != null)
                        Text(
                          '\$${plan.originalPrice!.toInt()}',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${plan.price.toInt()}',
                            style: TextStyle(
                              fontSize: plan.isPopular ? 42 : 36,
                              fontWeight: FontWeight.bold,
                              color: plan.color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            plan.period,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (plan.savings != null)
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Text(
                            plan.savings!,
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),
                
                // Features List
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: plan.features.map((feature) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: plan.color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.check,
                                color: plan.color,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: TextStyle(
                                  color: AppColors.primaryNavy,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: 25),
                
                // CTA Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [plan.color, plan.color.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: plan.color.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _selectPlan(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          plan.isPopular ? Icons.diamond : Icons.arrow_forward,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          plan.isPopular ? 'GET LIFETIME ACCESS' : 'START MONTHLY PLAN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureComparison() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '📊 Feature Comparison',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 20),
          
          // Header Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Features',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'FREE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'PRO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildComparisonRow('Quick Analysis', false, true),
          _buildComparisonRow('Trading Calendar', false, true),
          _buildComparisonRow('Daily Signals', true, true),
          _buildComparisonRow('Real-time Alerts', false, true),
          _buildComparisonRow('AI Trading Bot', false, true),
          _buildComparisonRow('Personal Coach', false, true),
          _buildComparisonRow('24/7 Support', false, true),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String feature, bool free, bool pro) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                free ? Icons.check : Icons.close,
                color: free ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                pro ? Icons.check : Icons.close,
                color: pro ? AppColors.primaryPurple : Colors.red,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonials() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade50,
            Colors.amber.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            '⭐ What Our Users Say',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 20),
          _buildTestimonial(
            'Made \$15,000 in my first month!',
            'Sarah Johnson',
            '⭐⭐⭐⭐⭐',
          ),
          const SizedBox(height: 12),
          _buildTestimonial(
            'The AI signals are incredibly accurate.',
            'Michael Chen',
            '⭐⭐⭐⭐⭐',
          ),
          const SizedBox(height: 12),
          _buildTestimonial(
            'Best trading app I\'ve ever used!',
            'Emily Rodriguez',
            '⭐⭐⭐⭐⭐',
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonial(String text, String name, String rating) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rating, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            '"$text"',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: AppColors.primaryNavy,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '- $name',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuarantee() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.verified,
              color: Colors.green.shade700,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '🛡️ 30-Day Money-Back Guarantee',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Try risk-free! If you\'re not completely satisfied, get a full refund within 30 days. No questions asked.',
            style: TextStyle(
              color: Colors.green.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ() {
    final faqs = [
      {
        'question': '💳 What payment methods do you accept?',
        'answer': 'We accept all major credit cards, PayPal, Apple Pay, and Google Pay. All payments are secured with 256-bit SSL encryption.'
      },
      {
        'question': '🔄 Can I switch between plans?',
        'answer': 'Yes! You can upgrade from Monthly to Lifetime anytime. Contact support for seamless plan switching.'
      },
      {
        'question': '📱 Does it work on all devices?',
        'answer': 'Absolutely! Access your account on iOS, Android, and web. All features sync across devices.'
      },
      {
        'question': '🎯 How accurate are the trading signals?',
        'answer': 'Our AI has a 89% accuracy rate based on historical data. Results may vary based on market conditions.'
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '❓ Frequently Asked Questions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 20),
          ...faqs.map((faq) => _buildFAQItem(faq['question']!, faq['answer']!)),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryNavy,
            fontSize: 14,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectPlan(PricingPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.diamond, color: plan.color),
            const SizedBox(width: 8),
            const Expanded(child: Text('Confirm Subscription')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You selected:', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(
              plan.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: plan.color,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${plan.price.toInt()} ${plan.period}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.green.shade700, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '30-day money-back guarantee',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processPurchase(plan);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: plan.color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm Purchase', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _processPurchase(PricingPlan plan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.payment, color: Colors.white),
            const SizedBox(width: 8),
            Text('Processing payment for ${plan.name}...'),
          ],
        ),
        backgroundColor: AppColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    
    // Navigate back to dashboard after 2 seconds (simulate payment processing)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/dashboard');
      }
    });
  }
}

class PricingPlan {
  final String name;
  final double price;
  final String period;
  final double? originalPrice;
  final List<String> features;
  final Color color;
  final bool isPopular;
  final String? badge;
  final String? savings;

  PricingPlan({
    required this.name,
    required this.price,
    required this.period,
    this.originalPrice,
    required this.features,
    required this.color,
    required this.isPopular,
    this.badge,
    this.savings,
  });
}