import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'trading_signal.g.dart';

enum SignalType { buy, sell, hold }

enum SignalStatus { active, closed, pending }

@JsonSerializable()
class TradingSignal {
  final String id;
  final String currencyPair;
  final String symbol;
  final SignalType type;
  final double entryPrice;
  final double price;
  final double? stopLoss;
  final double? takeProfit;
  final SignalStatus status;
  final DateTime createdAt;
  final DateTime? closedAt;
  final double? pnl;
  final String? notes;
  final String? description;
  final double confidence;

  const TradingSignal({
    required this.id,
    required this.currencyPair,
    required this.symbol,
    required this.type,
    required this.entryPrice,
    required this.price,
    this.stopLoss,
    this.takeProfit,
    required this.status,
    required this.createdAt,
    this.closedAt,
    this.pnl,
    this.notes,
    this.description,
    required this.confidence,
  });

  factory TradingSignal.fromJson(Map<String, dynamic> json) => _$TradingSignalFromJson(json);
  
  Map<String, dynamic> toJson() => _$TradingSignalToJson(this);

  bool get isActive => status == SignalStatus.active;

  Color get statusColor {
    if (pnl == null) return Colors.grey;
    if (pnl! > 0) return Colors.green;
    if (pnl! < 0) return Colors.red;
    return Colors.orange;
  }

  Color get typeColor {
    switch (type) {
      case SignalType.buy:
        return Colors.green;
      case SignalType.sell:
        return Colors.red;
      case SignalType.hold:
        return Colors.orange;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case SignalType.buy:
        return Icons.trending_up;
      case SignalType.sell:
        return Icons.trending_down;
      case SignalType.hold:
        return Icons.trending_flat;
    }
  }

  TradingSignal copyWith({
    String? id,
    String? currencyPair,
    String? symbol,
    SignalType? type,
    double? entryPrice,
    double? price,
    double? stopLoss,
    double? takeProfit,
    SignalStatus? status,
    DateTime? createdAt,
    DateTime? closedAt,
    double? pnl,
    String? notes,
    String? description,
    double? confidence,
  }) {
    return TradingSignal(
      id: id ?? this.id,
      currencyPair: currencyPair ?? this.currencyPair,
      symbol: symbol ?? this.symbol,
      type: type ?? this.type,
      entryPrice: entryPrice ?? this.entryPrice,
      price: price ?? this.price,
      stopLoss: stopLoss ?? this.stopLoss,
      takeProfit: takeProfit ?? this.takeProfit,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      closedAt: closedAt ?? this.closedAt,
      pnl: pnl ?? this.pnl,
      notes: notes ?? this.notes,
      description: description ?? this.description,
      confidence: confidence ?? this.confidence,
    );
  }
}
