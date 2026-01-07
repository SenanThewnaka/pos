import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/logic/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  final AppDatabase db;
  const AnalyticsScreen({Key? key, required this.db}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AnalyticsService _analyticsService;
  
  // State
  List<DailySalesMetric> _dailyMetrics = [];
  List<TopProductMetric> _topProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _analyticsService = AnalyticsService(widget.db);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 7));
    
    try {
      final daily = await _analyticsService.getDailySales(start, end);
      final top = await _analyticsService.getTopSellingProducts(5);
      
      if (mounted) {
        setState(() {
          _dailyMetrics = daily;
          _topProducts = top;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading analytics: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Business Intelligence")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Summary Cards (Today)
              _buildSummaryCards(),
              const SizedBox(height: 24),
              
              // 2. Bar Chart (Sales vs Cost)
              const Text("Performance (Last 7 Days)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(height: 300, child: _buildRevenueChart()),
              const SizedBox(height: 24),

              // 3. Top Products
              const Text("Top Selling Products (All Time)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildTopProductsList(),
            ],
          ),
    );
  }

  Widget _buildSummaryCards() {
    // Determine Today's stats
    final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Find metric for today (ignoring time component match which is handled by string or day-check)
    // DailySalesMetric date is DateTime.
    final todayMetric = _dailyMetrics.firstWhere(
      (m) => DateFormat('yyyy-MM-dd').format(m.date) == nowStr,
      orElse: () => DailySalesMetric(date: DateTime.now(), totalSales: 0, totalCost: 0, grossProfit: 0)
    );

    return Row(
      children: [
        Expanded(child: _MetricCard(title: "Today's Sales", value: "Rs. ${todayMetric.totalSales.toStringAsFixed(2)}", color: Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _MetricCard(title: "Today's Profit", value: "Rs. ${todayMetric.grossProfit.toStringAsFixed(2)}", color: Colors.green)),
      ],
    );
  }

  Widget _buildRevenueChart() {
    if (_dailyMetrics.isEmpty) return const Center(child: Text("No Sales Data"));

    // We need to reverse because API returns DESC (latest first), but chart usually reads left-to-right (old -> new)
    final data = _dailyMetrics.reversed.toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (data.map((e) => e.totalSales).reduce((a, b) => a > b ? a : b) * 1.2), // 20% buffer
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final index = val.toInt();
                if (index < 0 || index >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(DateFormat('MM/dd').format(data[index].date), style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide Y axis for clean look
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((start) {
            final idx = start.key;
            final m = start.value;
            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(toY: m.totalSales, color: Colors.blue, width: 12),
                BarChartRodData(toY: m.totalCost, color: Colors.red.withOpacity(0.5), width: 12),
              ],
            );
        }).toList(),
      ),
    );
  }

  Widget _buildTopProductsList() {
    if (_topProducts.isEmpty) return const Text("No data.");
    
    return Card(
      elevation: 2,
      child: Column(
        children: _topProducts.map((p) => ListTile(
          leading: CircleAvatar(child: Text(p.productName[0])),
          title: Text(p.productName),
          subtitle: Text("Sold: ${p.quantitySold.toInt()} | Rev: ${p.totalRevenue.toStringAsFixed(0)}"),
          trailing: const Icon(Icons.trending_up, color: Colors.green),
        )).toList(),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
