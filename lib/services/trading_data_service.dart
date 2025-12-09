import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/market_data.dart';

class TradingDataService {
  static TradingDataService? _instance;
  static TradingDataService get instance => _instance ??= TradingDataService._();
  
  TradingDataService._();
  
  FirebaseFirestore get _firestore => FirebaseService.instance.firestore;
  String? get currentUserId => FirebaseService.instance.auth.currentUser?.uid;
  
  // Save market data to Firebase
  Future<void> saveMarketData(String symbol, MarketData data) async {
    try {
      await _firestore.collection('market_data').doc(symbol).set({
        'symbol': symbol,
        'price': data.price,
        'change': data.change,
        'changePercent': data.changePercent,
        'high': data.high,
        'low': data.low,
        'open': data.open,
        'volume': data.volume,
        'timestamp': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ Market data saved to Firebase: $symbol');
    } catch (e) {
      print('❌ Error saving market data: $e');
    }
  }
  
  // Save trade data
  Future<void> saveTrade(Map<String, dynamic> tradeData) async {
    if (currentUserId == null) {
      print('❌ User not authenticated');
      return;
    }
    
    try {
      await _firestore.collection('trades').add({
        ...tradeData,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': currentUserId,
      });
      
      print('✅ Trade saved to Firebase: ${tradeData['symbol']}');
    } catch (e) {
      print('❌ Error saving trade: $e');
    }
  }
  
  // Get user trades
  Stream<QuerySnapshot> getUserTrades() {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    return _firestore
        .collection('trades')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }
  
  // Get real-time market data
  Stream<DocumentSnapshot> getMarketData(String symbol) {
    return _firestore.collection('market_data').doc(symbol).snapshots();
  }
  
  // Save trading signals
  Future<void> saveTradingSignal(Map<String, dynamic> signalData) async {
    try {
      await _firestore.collection('trading_signals').add({
        ...signalData,
        'timestamp': FieldValue.serverTimestamp(),
        'active': true,
      });
      
      print('✅ Trading signal saved: ${signalData['symbol']}');
    } catch (e) {
      print('❌ Error saving signal: $e');
    }
  }
  
  // Get active signals
  Stream<QuerySnapshot> getActiveTradingSignals() {
    return _firestore
        .collection('trading_signals')
        .where('active', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  // Save user watchlist
  Future<void> saveToWatchlist(String symbol) async {
    if (currentUserId == null) return;
    
    try {
      await _firestore.collection('watchlists').doc(currentUserId).set({
        'symbols': FieldValue.arrayUnion([symbol]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ Added to watchlist: $symbol');
    } catch (e) {
      print('❌ Error saving to watchlist: $e');
    }
  }
  
  // Remove from watchlist
  Future<void> removeFromWatchlist(String symbol) async {
    if (currentUserId == null) return;
    
    try {
      await _firestore.collection('watchlists').doc(currentUserId!).update({
        'symbols': FieldValue.arrayRemove([symbol]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      print('✅ Removed from watchlist: $symbol');
    } catch (e) {
      print('❌ Error removing from watchlist: $e');
    }
  }
  
  // Get user watchlist
  Stream<DocumentSnapshot> getUserWatchlist() {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    return _firestore.collection('watchlists').doc(currentUserId!).snapshots();
  }
}