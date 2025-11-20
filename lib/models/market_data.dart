class MarketData {
  final String symbol;
  final double price;
  final double change;
  final double changePercent;
  final double high;
  final double low;
  final double open;
  final double volume;
  final DateTime timestamp;

  const MarketData({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.high,
    required this.low,
    required this.open,
    required this.volume,
    required this.timestamp,
  });

  factory MarketData.fromMap(Map<String, dynamic> map) {
    return MarketData(
      symbol: map['symbol'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      change: (map['change'] ?? 0.0).toDouble(),
      changePercent: (map['change_percent'] ?? 0.0).toDouble(),
      high: (map['high'] ?? 0.0).toDouble(),
      low: (map['low'] ?? 0.0).toDouble(),
      open: (map['open'] ?? 0.0).toDouble(),
      volume: (map['volume'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'symbol': symbol,
      'price': price,
      'change': change,
      'change_percent': changePercent,
      'high': high,
      'low': low,
      'open': open,
      'volume': volume,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  bool get isPositive => change >= 0;
  
  String get formattedPrice {
    final decimals = symbol.contains('JPY') ? 2 : 4;
    return price.toStringAsFixed(decimals);
  }

  String get formattedChange {
    final decimals = symbol.contains('JPY') ? 2 : 4;
    return change.toStringAsFixed(decimals);
  }

  String get formattedChangePercent {
    return '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%';
  }

  @override
  String toString() {
    return 'MarketData(symbol: $symbol, price: $price, change: $change)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarketData && other.symbol == symbol;
  }

  @override
  int get hashCode => symbol.hashCode;
}