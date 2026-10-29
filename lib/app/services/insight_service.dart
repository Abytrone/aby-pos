import 'dart:convert';

import 'package:drift/drift.dart' show Variable;

import '../data/database/app_database.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/stock_repository.dart';

/// The kinds of insight (REP-08). Owners can turn a kind off.
enum InsightKind { runningOut, busyDay, marginDrop, lateCredit, cashShort }

/// One thing worth knowing, worked out on the device from the shop's own
/// data. [key] identifies it for dismissing; [values] fill in its sentence.
class Insight {
  const Insight(this.kind, this.key, {this.names = const [], this.numbers = const []});

  final InsightKind kind;
  final String key;
  final List<String> names;
  final List<int> numbers;
}

/// Simple rules, no internet: stock running out, the busiest day, margins
/// falling, customers more than 30 days late, cash short.
class InsightService {
  InsightService(this._db, this._stock, this._customers, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final StockRepository _stock;
  final CustomerRepository _customers;
  final DateTime Function() _clock;

  static const _dismissedKey = 'insights.dismissed';
  static const _offKey = 'insights.off';

  /// A dismissed insight comes back after this long, if still true.
  static const hideFor = Duration(days: 7);

  Future<Map<String, DateTime>> _dismissed() async {
    final raw = await _db.readMeta(_dismissedKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, DateTime.parse(v as String)));
  }

  Future<Set<InsightKind>> off() async {
    final raw = await _db.readMeta(_offKey);
    if (raw == null) return {};
    final byName = InsightKind.values.asNameMap();
    return {for (final n in (jsonDecode(raw) as List).cast<String>()) ?byName[n]};
  }

  Future<void> dismiss(Insight i) async {
    final d = await _dismissed();
    d[i.key] = _clock();
    await _db.writeMeta(_dismissedKey, jsonEncode(d.map((k, v) => MapEntry(k, v.toIso8601String()))));
  }

  Future<void> turnOff(InsightKind kind) async =>
      _db.writeMeta(_offKey, jsonEncode([...{...await off(), kind}.map((k) => k.name)]));

  Future<void> turnAllOn() => _db.writeMeta(_offKey, '[]');

  /// What is true now, less what was dismissed lately or turned off.
  Future<List<Insight>> current() async {
    final now = _clock();
    final all = [
      ...await _runningOut(now),
      ...await _busyDay(now),
      ...await _marginDrop(now),
      ...await _lateCredit(now),
      ...await _cashShort(now),
    ];
    final dismissed = await _dismissed();
    final kindsOff = await off();
    return [
      for (final i in all)
        if (!kindsOff.contains(i.kind) && !(dismissed[i.key]?.isAfter(now.subtract(hideFor)) ?? false)) i,
    ];
  }

  /// At this week's pace, stock that lasts under 3 days. numbers: days.
  Future<List<Insight>> _runningOut(DateTime now) async {
    final used = await _stock.usedSince(now.subtract(const Duration(days: 7)));
    final out = <Insight>[];
    for (final item in await _stock.items()) {
      final perDay = (used[item.id] ?? 0) / 7;
      if (perDay <= 0 || item.onHand <= 0) continue;
      final days = item.onHand / perDay;
      if (days < 3) out.add(Insight(InsightKind.runningOut, 'runningOut:${item.id}', names: [item.name], numbers: [days.ceil()]));
    }
    return out..sort((a, b) => a.numbers.first.compareTo(b.numbers.first));
  }

  /// The busiest day of the week against weekdays, over 4 weeks. numbers:
  /// weekday (1 Monday), percent more.
  Future<List<Insight>> _busyDay(DateTime now) async {
    final rows = await _db.customSelect(
      "SELECT CAST(strftime('%w', created_at, 'unixepoch', 'localtime') AS INTEGER) AS dow, SUM(total) AS v, "
      "COUNT(DISTINCT date(created_at, 'unixepoch', 'localtime')) AS days FROM sales "
      "WHERE status = 'completed' AND deleted_at IS NULL AND created_at >= ? GROUP BY dow",
      variables: [Variable.withDateTime(now.subtract(const Duration(days: 28)))],
      readsFrom: {_db.sales},
    ).get();
    final perDay = {for (final r in rows) r.read<int>('dow'): r.read<int>('v') / r.read<int>('days')};
    final weekdays = [for (final d in [1, 2, 3, 4, 5]) ?perDay[d]];
    if (weekdays.length < 3 || perDay.length < 5) return const [];
    final weekdayAvg = weekdays.reduce((a, b) => a + b) / weekdays.length;
    final best = perDay.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final more = ((best.value / weekdayAvg - 1) * 100).round();
    if (weekdayAvg <= 0 || more < 30 || (best.key >= 1 && best.key <= 5)) return const [];
    // strftime: 0 Sunday ... 6 Saturday; DateTime: 1 Monday ... 7 Sunday.
    final weekday = best.key == 0 ? 7 : best.key;
    return [Insight(InsightKind.busyDay, 'busyDay:$weekday', numbers: [weekday, more])];
  }

  /// A product's margin down 10 points or more: the last 7 days against the
  /// 28 before. numbers: margin before, margin now (percent).
  Future<List<Insight>> _marginDrop(DateTime now) async {
    Future<Map<String, (String, int, int)>> margins(DateTime from, DateTime to) async {
      final rows = await _db.customSelect(
        'SELECT l.product_id AS id, l.product_name AS name, SUM(l.line_total - l.discount - l.order_discount_share) AS revenue, '
        'SUM(l.cost_total) AS cost FROM sale_lines l JOIN sales s ON s.id = l.sale_id '
        "WHERE l.deleted_at IS NULL AND s.status = 'completed' AND s.deleted_at IS NULL AND s.created_at >= ? AND s.created_at < ? "
        'GROUP BY l.product_id',
        variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
        readsFrom: {_db.sales, _db.saleLines},
      ).get();
      return {for (final r in rows) r.read<String>('id'): (r.read<String>('name'), r.read<int>('revenue'), r.read<int>('cost'))};
    }

    final weekAgo = now.subtract(const Duration(days: 7));
    final recent = await margins(weekAgo, now);
    final before = await margins(weekAgo.subtract(const Duration(days: 28)), weekAgo);
    final out = <Insight>[];
    for (final MapEntry(key: id, value: (name, revenue, cost)) in recent.entries) {
      final old = before[id];
      // Enough sales either side, and costs known.
      if (old == null || revenue < 2000 || old.$2 < 2000 || cost == 0 || old.$3 == 0) continue;
      final was = ((old.$2 - old.$3) * 100 / old.$2).round();
      final nowM = ((revenue - cost) * 100 / revenue).round();
      if (was - nowM >= 10) out.add(Insight(InsightKind.marginDrop, 'marginDrop:$id', names: [name], numbers: [was, nowM]));
    }
    return out;
  }

  /// Customers more than 30 days late. numbers: how many, pesewas.
  Future<List<Insight>> _lateCredit(DateTime now) async {
    var count = 0, amount = 0;
    for (final c in (await _customers.list(owing: true))) {
      final late = await _customers.openDebts(c.id);
      final over30 = late.where((d) => d.daysOverdue(now) > 30).fold(0, (s, d) => s + d.outstanding);
      if (over30 > 0) {
        count++;
        amount += over30;
      }
    }
    return count == 0 ? const [] : [Insight(InsightKind.lateCredit, 'lateCredit:${now.year}-${now.month}', numbers: [count, amount])];
  }

  /// Cash short 3 or more times this month. numbers: times, pesewas.
  Future<List<Insight>> _cashShort(DateTime now) async {
    final r = await _db.customSelect(
      'SELECT COUNT(*) AS n, COALESCE(SUM(expected_cash - counted_cash), 0) AS v FROM day_closes '
      'WHERE deleted_at IS NULL AND counted_cash < expected_cash AND closed_at >= ?',
      variables: [Variable.withDateTime(DateTime(now.year, now.month))],
      readsFrom: {_db.dayCloses},
    ).getSingle();
    final n = r.read<int>('n');
    return n < 3 ? const [] : [Insight(InsightKind.cashShort, 'cashShort:${now.year}-${now.month}', numbers: [n, r.read<int>('v')])];
  }
}
