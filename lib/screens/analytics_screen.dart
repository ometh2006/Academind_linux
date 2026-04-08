import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../models/subject.dart';
import '../models/test_score.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Subject> _subjects = [];
  List<TestScore> _allScores = [];
  Map<int, double> _avgBySubject = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    final subjects = await db.getAllSubjects();
    final scores = await db.getAllScores();
    final avg = await db.getAverageScoreBySubject();
    setState(() {
      _subjects = subjects;
      _allScores = scores;
      _avgBySubject = avg;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analytics', style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text('Performance insights', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 28),

            if (_subjects.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(64),
                  child: Column(
                    children: [
                      Icon(Icons.bar_chart_outlined, size: 72, color: cs.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('No data yet', style: tt.headlineSmall),
                      Text('Add subjects and test scores to see analytics', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
            else ...[
              // Bar chart - average per subject
              _sectionTitle('Average Score by Subject', tt),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    height: 240,
                    child: _avgBySubject.isEmpty
                        ? Center(child: Text('No test scores yet', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)))
                        : BarChart(_buildBarChartData(cs)),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Score distribution
              _sectionTitle('Grade Distribution', tt),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    height: 240,
                    child: _allScores.isEmpty
                        ? Center(child: Text('No test scores yet', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)))
                        : Row(
                            children: [
                              Expanded(child: PieChart(_buildPieChartData())),
                              const SizedBox(width: 24),
                              _buildLegend(tt, cs),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Subject breakdown table
              _sectionTitle('Subject Breakdown', tt),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _subjects.map((s) {
                      final avg = _avgBySubject[s.id];
                      final count = _allScores.where((sc) => sc.subjectId == s.id).length;
                      final color = AppTheme.subjectColor(s.colorHex);
                      return _buildSubjectRow(s, avg, count, color, tt, cs);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  BarChartData _buildBarChartData(ColorScheme cs) {
    final entries = _avgBySubject.entries.toList();
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 100,
      barGroups: entries.asMap().entries.map((e) {
        final idx = e.key;
        final entry = e.value;
        final subject = _subjects.firstWhere((s) => s.id == entry.key, orElse: () => Subject(name: '?'));
        final color = AppTheme.subjectColor(subject.colorHex);
        return BarChartGroupData(
          x: idx,
          barRods: [
            BarChartRodData(
              toY: entry.value,
              color: color,
              width: 32,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ],
        );
      }).toList(),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: const TextStyle(fontSize: 11)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (v, _) {
              final idx = v.toInt();
              if (idx < 0 || idx >= entries.length) return const SizedBox();
              final subj = _subjects.firstWhere((s) => s.id == entries[idx].key, orElse: () => Subject(name: '?'));
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  subj.name.length > 8 ? '${subj.name.substring(0, 7)}…' : subj.name,
                  style: const TextStyle(fontSize: 11),
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: true),
      borderData: FlBorderData(show: false),
    );
  }

  Map<String, int> get _gradeDistribution {
    final dist = {'A+': 0, 'A': 0, 'B': 0, 'C': 0, 'D': 0, 'F': 0};
    for (final s in _allScores) {
      dist[s.grade] = (dist[s.grade] ?? 0) + 1;
    }
    return dist;
  }

  PieChartData _buildPieChartData() {
    final dist = _gradeDistribution;
    final colors = {
      'A+': Colors.green.shade700,
      'A': Colors.green,
      'B': Colors.lightGreen,
      'C': Colors.orange,
      'D': Colors.deepOrange,
      'F': Colors.red,
    };
    final sections = dist.entries
        .where((e) => e.value > 0)
        .map((e) => PieChartSectionData(
              value: e.value.toDouble(),
              title: '${e.key}\n${e.value}',
              color: colors[e.key] ?? Colors.grey,
              radius: 80,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ))
        .toList();
    return PieChartData(sections: sections, sectionsSpace: 2);
  }

  Widget _buildLegend(TextTheme tt, ColorScheme cs) {
    final dist = _gradeDistribution;
    final colors = {
      'A+': Colors.green.shade700,
      'A': Colors.green,
      'B': Colors.lightGreen,
      'C': Colors.orange,
      'D': Colors.deepOrange,
      'F': Colors.red,
    };
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: dist.entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(width: 14, height: 14, decoration: BoxDecoration(color: colors[e.key], borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 8),
            Text('${e.key}: ${e.value}', style: tt.bodySmall),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSubjectRow(Subject s, double? avg, int count, Color color, TextTheme tt, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            radius: 20,
            child: Text(s.name[0].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(s.name, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500))),
          Text('$count tests', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: avg == null ? cs.surfaceVariant : (avg >= 70 ? Colors.green : avg >= 50 ? Colors.orange : Colors.red).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              avg == null ? 'N/A' : '${avg.toStringAsFixed(1)}%',
              style: tt.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: avg == null ? cs.onSurfaceVariant : (avg >= 70 ? Colors.green : avg >= 50 ? Colors.orange : Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, TextTheme tt) =>
      Text(title, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600));
}
