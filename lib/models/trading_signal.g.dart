// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trading_signal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TradingSignal _$TradingSignalFromJson(Map<String, dynamic> json) =>
    TradingSignal(
      id: json['id'] as String,
      currencyPair: json['currencyPair'] as String,
      symbol: json['symbol'] as String,
      type: $enumDecode(_$SignalTypeEnumMap, json['type']),
      entryPrice: (json['entryPrice'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      stopLoss: (json['stopLoss'] as num?)?.toDouble(),
      takeProfit: (json['takeProfit'] as num?)?.toDouble(),
      status: $enumDecode(_$SignalStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      closedAt: json['closedAt'] == null
          ? null
          : DateTime.parse(json['closedAt'] as String),
      pnl: (json['pnl'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      description: json['description'] as String?,
      confidence: (json['confidence'] as num).toDouble(),
    );

Map<String, dynamic> _$TradingSignalToJson(TradingSignal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'currencyPair': instance.currencyPair,
      'symbol': instance.symbol,
      'type': _$SignalTypeEnumMap[instance.type]!,
      'entryPrice': instance.entryPrice,
      'price': instance.price,
      'stopLoss': instance.stopLoss,
      'takeProfit': instance.takeProfit,
      'status': _$SignalStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'closedAt': instance.closedAt?.toIso8601String(),
      'pnl': instance.pnl,
      'notes': instance.notes,
      'description': instance.description,
      'confidence': instance.confidence,
    };

const _$SignalTypeEnumMap = {
  SignalType.buy: 'buy',
  SignalType.sell: 'sell',
  SignalType.hold: 'hold',
};

const _$SignalStatusEnumMap = {
  SignalStatus.active: 'active',
  SignalStatus.closed: 'closed',
  SignalStatus.pending: 'pending',
};
