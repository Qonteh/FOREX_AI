import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/market_data_service.dart';

class CandlestickChart extends StatefulWidget {
  final String symbol;

  const CandlestickChart({super.key, this.symbol = 'EUR/USD'});

  @override
  State<CandlestickChart> createState() => _CandlestickChartState();
}

class _CandlestickChartState extends State<CandlestickChart> {
  final MarketDataService _marketDataService = MarketDataService();
  List<FlSpot> priceData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    try {
      final historicalData = await _marketDataService.getHistoricalData(widget.symbol, '1H');
      
      setState(() {
        priceData = historicalData.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value['close'].toDouble());
        }).toList();
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
      return const Center(child: CircularProgressIndicator());
    }

    if (priceData.isEmpty) {
      return const Center(child: Text('No chart data available'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 0.001,
          verticalInterval: 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 10,
              getTitlesWidget: (double value, TitleMeta meta) {
                final hours = ['09:00', '11:00', '13:00', '15:00', '17:00'];
                final index = (value / 10).round();
                if (index >= 0 && index < hours.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      hours[index],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 0.002,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toStringAsFixed(4),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
              reservedSize: 55,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: 0,
        maxX: (priceData.length - 1).toDouble(),
        minY: priceData.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 0.001,
        maxY: priceData.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 0.001,
        lineBarsData: [
          LineChartBarData(
            spots: priceData,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.3),
              ],
            ),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.2),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}