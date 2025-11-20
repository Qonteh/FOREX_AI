import 'package:flutter/material.dart';
import '../../services/technical_analysis_service.dart';

class TechnicalIndicators extends StatefulWidget {
  final String symbol;

  const TechnicalIndicators({super.key, this.symbol = 'EUR/USD'});

  @override
  State<TechnicalIndicators> createState() => _TechnicalIndicatorsState();
}

class _TechnicalIndicatorsState extends State<TechnicalIndicators> {
  final TechnicalAnalysisService _analysisService = TechnicalAnalysisService();
  List<Map<String, dynamic>> _indicators = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIndicators();
  }

  Future<void> _loadIndicators() async {
    try {
      final indicators = await _analysisService.getIndicators(widget.symbol);
      setState(() {
        _indicators = indicators;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Technical Indicators',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _indicators.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final indicator = _indicators[index];
                return _IndicatorItem(indicator: indicator);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorItem extends StatelessWidget {
  final Map<String, dynamic> indicator;

  const _IndicatorItem({required this.indicator});

  @override
  Widget build(BuildContext context) {
    final signal = indicator['signal'] as String;
    Color signalColor;
    IconData signalIcon;

    switch (signal.toLowerCase()) {
      case 'bullish':
        signalColor = Colors.green;
        signalIcon = Icons.trending_up;
        break;
      case 'bearish':
        signalColor = Colors.red;
        signalIcon = Icons.trending_down;
        break;
      default:
        signalColor = Colors.orange;
        signalIcon = Icons.trending_flat;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  indicator['name'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  indicator['description'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              indicator['value'].toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: signalColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(signalIcon, color: signalColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    signal,
                    style: TextStyle(
                      color: signalColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
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