class RealtimePortfolioTotals {
  final double marketValue;
  final double dayGain;
  final double dayGainPct;
  final int? liveHoldingsCount;
  final int? unsupportedHoldingsCount;

  // New fields from websocket totals
  final double? totalNetworth;
  final double? dailyGain;
  final double? invested;
  final double? etfTotal;
  final double? equityTotal;
  final double? insuranceTotal;

  RealtimePortfolioTotals({
    required this.marketValue,
    required this.dayGain,
    required this.dayGainPct,
    this.liveHoldingsCount,
    this.unsupportedHoldingsCount,
    this.totalNetworth,
    this.dailyGain,
    this.invested,
    this.etfTotal,
    this.equityTotal,
    this.insuranceTotal,
  });

  factory RealtimePortfolioTotals.fromJson(Map<String, dynamic> json) {
    // Graceful fallbacks for backward compatibility
    final mv = (json['market_value'] as num?)?.toDouble() ??
        (json['total_networth'] as num?)?.toDouble() ??
        0.0;
    final dg = (json['day_gain'] as num?)?.toDouble() ??
        (json['daily_gain'] as num?)?.toDouble() ??
        0.0;
    final dgp = (json['day_gain_pct'] as num?)?.toDouble() ?? 0.0;

    return RealtimePortfolioTotals(
      marketValue: mv,
      dayGain: dg,
      dayGainPct: dgp,
      liveHoldingsCount: json['live_holdings_count'] as int?,
      unsupportedHoldingsCount: json['unsupported_holdings_count'] as int?,
      totalNetworth: (json['total_networth'] as num?)?.toDouble(),
      dailyGain: (json['daily_gain'] as num?)?.toDouble(),
      invested: (json['invested'] as num?)?.toDouble(),
      etfTotal: (json['etf_total'] as num?)?.toDouble(),
      equityTotal: (json['equity_total'] as num?)?.toDouble(),
      insuranceTotal: (json['insurance_total'] as num?)?.toDouble(),
    );
  }
}

class RealtimeHolding {
  final String isin;
  final String symbol;
  final String exchange;
  final double lastPrice;
  final double previousClose;
  final double quantity;
  final double marketValue;
  final double dayGain;
  final double dayGainPct;
  final double? totalGain;
  final double? totalGainPct;
  final double? avgBuyPrice;
  final double? totalInvested;
  final double? cagrPct;

  RealtimeHolding({
    required this.isin,
    required this.symbol,
    required this.exchange,
    required this.lastPrice,
    required this.previousClose,
    required this.quantity,
    required this.marketValue,
    required this.dayGain,
    required this.dayGainPct,
    this.totalGain,
    this.totalGainPct,
    this.avgBuyPrice,
    this.totalInvested,
    this.cagrPct,
  });

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory RealtimeHolding.fromJson(Map<String, dynamic> json) {
    return RealtimeHolding(
      isin: json['isin'] as String,
      symbol: json['symbol'] as String,
      exchange: json['exchange'] as String,
      lastPrice: (json['last_price'] as num).toDouble(),
      previousClose: (json['previous_close'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      marketValue: (json['market_value'] as num).toDouble(),
      dayGain: (json['day_gain'] as num).toDouble(),
      dayGainPct: (json['day_gain_pct'] as num).toDouble(),
      totalGain: _parseNullableDouble(json['total_gain']),
      totalGainPct: _parseNullableDouble(json['total_gain_pct']),
      avgBuyPrice: _parseNullableDouble(json['avg_buy_price']),
      totalInvested: _parseNullableDouble(json['total_invested']),
      cagrPct: _parseNullableDouble(json['cagr_pct']),
    );
  }
}

class UnsupportedHolding {
  final String isin;
  final String name;
  final String reason;

  UnsupportedHolding({
    required this.isin,
    required this.name,
    required this.reason,
  });

  factory UnsupportedHolding.fromJson(Map<String, dynamic> json) {
    return UnsupportedHolding(
      isin: json['isin'] as String,
      name: json['name'] as String,
      reason: json['reason'] as String,
    );
  }
}

class PortfolioSnapshot {
  final DateTime asOfAt;
  final RealtimePortfolioTotals totals;
  final List<RealtimeHolding> holdings;
  final List<UnsupportedHolding> unsupportedHoldings;

  PortfolioSnapshot({
    required this.asOfAt,
    required this.totals,
    required this.holdings,
    this.unsupportedHoldings = const [],
  });

  factory PortfolioSnapshot.fromJson(Map<String, dynamic> json) {
    return PortfolioSnapshot(
      asOfAt: DateTime.parse(json['as_of_at'] as String),
      totals: RealtimePortfolioTotals.fromJson(
        json['totals'] as Map<String, dynamic>,
      ),
      holdings:
          (json['holdings'] as List<dynamic>?)
              ?.map((e) => RealtimeHolding.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      unsupportedHoldings:
          (json['unsupported_holdings'] as List<dynamic>?)
              ?.map(
                (e) => UnsupportedHolding.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class PortfolioDelta {
  final DateTime asOfAt;
  final RealtimePortfolioTotals? totals;
  final List<RealtimeHolding> holdings;

  PortfolioDelta({required this.asOfAt, this.totals, required this.holdings});

  factory PortfolioDelta.fromJson(Map<String, dynamic> json) {
    return PortfolioDelta(
      asOfAt: DateTime.parse(json['as_of_at'] as String),
      totals:
          json['totals'] != null
              ? RealtimePortfolioTotals.fromJson(
                json['totals'] as Map<String, dynamic>,
              )
              : null,
      holdings:
          (json['holdings'] as List<dynamic>?)
              ?.map((e) => RealtimeHolding.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
