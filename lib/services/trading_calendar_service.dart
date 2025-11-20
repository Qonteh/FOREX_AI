import 'api_service.dart';

class TradingCalendarService {
  final ApiService _apiService = ApiService.instance;

  Future<List<Map<String, dynamic>>> getCalendarEvents() async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      
      return [
        {
          'id': '1',
          'title': 'US Non-Farm Payrolls',
          'date': DateTime.now().add(const Duration(days: 1)),
          'time': '14:30',
          'currency': 'USD',
          'impact': 'High',
          'forecast': '200K',
          'previous': '187K',
          'description': 'Monthly change in the number of employed people in the US',
        },
        {
          'id': '2',
          'title': 'ECB Interest Rate Decision',
          'date': DateTime.now().add(const Duration(days: 3)),
          'time': '13:45',
          'currency': 'EUR',
          'impact': 'High',
          'forecast': '4.50%',
          'previous': '4.50%',
          'description': 'European Central Bank monetary policy decision',
        },
        {
          'id': '3',
          'title': 'UK GDP Growth',
          'date': DateTime.now().add(const Duration(days: 5)),
          'time': '08:30',
          'currency': 'GBP',
          'impact': 'Medium',
          'forecast': '0.2%',
          'previous': '0.1%',
          'description': 'Quarterly Gross Domestic Product growth rate',
        },
        {
          'id': '4',
          'title': 'US CPI Inflation',
          'date': DateTime.now().add(const Duration(days: 7)),
          'time': '14:30',
          'currency': 'USD',
          'impact': 'High',
          'forecast': '3.2%',
          'previous': '3.0%',
          'description': 'Consumer Price Index year-over-year change',
        },
      ];
    } catch (e) {
      throw Exception('Failed to get calendar events: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMarketSessions() async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      
      final now = DateTime.now();
      
      return [
        {
          'name': 'Sydney',
          'timezone': 'AEDT',
          'open': DateTime(now.year, now.month, now.day, 22, 0),
          'close': DateTime(now.year, now.month, now.day + 1, 7, 0),
          'isActive': _isSessionActive(22, 7),
          'volume': 'Low',
        },
        {
          'name': 'Tokyo',
          'timezone': 'JST',
          'open': DateTime(now.year, now.month, now.day, 0, 0),
          'close': DateTime(now.year, now.month, now.day, 9, 0),
          'isActive': _isSessionActive(0, 9),
          'volume': 'Medium',
        },
        {
          'name': 'London',
          'timezone': 'GMT',
          'open': DateTime(now.year, now.month, now.day, 8, 0),
          'close': DateTime(now.year, now.month, now.day, 17, 0),
          'isActive': _isSessionActive(8, 17),
          'volume': 'High',
        },
        {
          'name': 'New York',
          'timezone': 'EST',
          'open': DateTime(now.year, now.month, now.day, 13, 0),
          'close': DateTime(now.year, now.month, now.day, 22, 0),
          'isActive': _isSessionActive(13, 22),
          'volume': 'High',
        },
      ];
    } catch (e) {
      throw Exception('Failed to get market sessions: $e');
    }
  }

  bool _isSessionActive(int openHour, int closeHour) {
    final now = DateTime.now();
    final currentHour = now.hour;
    
    if (openHour < closeHour) {
      return currentHour >= openHour && currentHour < closeHour;
    } else {
      return currentHour >= openHour || currentHour < closeHour;
    }
  }
}