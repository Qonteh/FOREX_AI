const Colors = require('flutter/material.dart').Colors;
const Icons = require('flutter/material.dart').Icons;

test('TradingSignal statusColor returns correct color', () => {
    const tradingSignal = new TradingSignal();
    expect(tradingSignal.statusColor).toBe(Colors.grey);
});

test('TradingSignal typeIcon returns correct icon', () => {
    const tradingSignal = new TradingSignal();
    expect(tradingSignal.typeIcon).toBe(Icons.trending_up);
});