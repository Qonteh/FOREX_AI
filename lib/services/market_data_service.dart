import '../models/market_data.dart';
import 'api_service.dart';

class MarketDataService {
  final ApiService _apiService = ApiService.instance;

  Future<List<MarketData>> getMarketData() async {
    try {
      // Mock data for now
      await Future.delayed(const Duration(seconds: 1));
      
      return [
        MarketData(
          symbol: 'EUR/USD',
          price: 1.0842,
          change: 0.0012,
          changePercent: 0.11,
          high: 1.0855,
          low: 1.0820,
          open: 1.0830,
          volume: 125000,
          timestamp: DateTime.now(),
        ),
        MarketData(
          symbol: 'GBP/USD',
          price: 1.2734,
          change: -0.0045,
          changePercent: -0.35,
          high: 1.2780,
          low: 1.2720,
          open: 1.2779,
          volume: 98000,
          timestamp: DateTime.now(),
        ),
        MarketData(
          symbol: 'USD/JPY',
          price: 149.85,
          change: 0.75,
          changePercent: 0.50,
          high: 150.12,
          low: 149.20,
          open: 149.10,
          volume: 156000,
          timestamp: DateTime.now(),
        ),
        MarketData(
          symbol: 'AUD/USD',
          price: 0.6542,
          change: -0.0023,
          changePercent: -0.35,
          high: 0.6570,
          low: 0.6535,
          open: 0.6565,
          volume: 87000,
          timestamp: DateTime.now(),
        ),
      ];
    } catch (e) {
      throw Exception('Failed to fetch market data: $e');
    }
  }

  Future<MarketData> getSymbolData(String symbol) async {
    try {
      final response = await _apiService.get('/market-data/$symbol');
      return MarketData.fromMap(response.data);
    } catch (e) {
      // Return mock data for now
      return MarketData(
        symbol: symbol,
        price: 1.0842,
        change: 0.0012,
        changePercent: 0.11,
        high: 1.0855,
        low: 1.0820,
        open: 1.0830,
        volume: 125000,
        timestamp: DateTime.now(),
      );
    }
  }

  Future<List<Map<String, dynamic>>> getHistoricalData(String symbol, String timeframe) async {
    try {
      // Mock historical data
      await Future.delayed(const Duration(milliseconds: 500));
      
      return List.generate(50, (index) {
        final basePrice = 1.0800;
        final variation = (index % 10 - 5) * 0.001;
        return {
          'timestamp': DateTime.now().subtract(Duration(hours: 50 - index)).millisecondsSinceEpoch,
          'open': basePrice + variation,
          'high': basePrice + variation + 0.002,
          'low': basePrice + variation - 0.002,
          'close': basePrice + variation + 0.001,
          'volume': 1000 + (index * 100),
        };
      });
    } catch (e) {
      throw Exception('Failed to fetch historical data: $e');
    }
  }
}