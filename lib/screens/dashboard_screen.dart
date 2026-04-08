import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/subject.dart';
import '../models/test_score.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Subject> _subjects = [];
  List<TestScore> _recentScores = [];
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
      _recentScores = scores.take(5).toList();
      _avgBySubject = avg;
      _loading = false;
    });
  }

  double get _overallAvg {
    if (_avgBySubject.isEmpty) return 0;
    return _avgBySubject.values.reduce((a, b) => a + b) / _avgBySubject.length;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dashboard', style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Your academic overview', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Stat cards
              _buildStatCards(cs, tt),
              const SizedBox(height: 28),

              // Subject performance
              Text('Subject Performance', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (_subjects.isEmpty)
                _emptyCard('No subjects yet', 'Add subjects to see performance', Icons.school_outlined)
              else
                ..._subjects.map((s) => _buildSubjectPerformanceCard(s, cs, tt)),
              const SizedBox(height: 28),

              // Recent activity
              Text('Recent Tests', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (_recentScores.isEmpty)
                _emptyCard('No tests recorded', 'Add test scores to track progress', Icons.quiz_outlined)
              else
                ..._recentScores.map((score) => _buildRecentScoreCard(score, cs, tt)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards(ColorScheme cs, TextTheme tt) {
    final totalTests = _recentScores.length;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: [
        _statCard(
          icon: Icons.menu_book_rounded,
          label: 'Subjects',
          value: '${_subjects.length}',
          color: cs.primaryContainer,
          onColor: cs.onPrimaryContainer,
          tt: tt,
        ),
        _statCard(
          icon: Icons.quiz_rounded,
          label: 'Total Tests',
          value: '$totalTests',
          color: cs.secondaryContainer,
          onColor: cs.onSecondaryContainer,
          tt: tt,
        ),
        _statCard(
          icon: Icons.trending_up_rounded,
          label: 'Avg Score',
          value: _avgBySubject.isEmpty ? 'N/A' : '${_overallAvg.toStringAsFixed(1)}%',
          color: cs.tertiaryContainer,
          onColor: cs.onTertiaryContainer,
          tt: tt,
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color onColor,
    required TextTheme tt,
  }) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: onColor, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: tt.headlineMedium?.copyWith(color: onColor, fontWeight: FontWeight.bold)),
                Text(label, style: tt.bodySmall?.copyWith(color: onColor.withOpacity(0.8))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectPerformanceCard(Subject subject, ColorScheme cs, TextTheme tt) {
    final avg = _avgBySubject[subject.id] ?? -1;
    final hasData = avg >= 0;
    final color = AppTheme.subjectColor(subject.colorHex);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Text(
                subject.name.isNotEmpty ? subject.name[0].toUpperCase() : '?',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  if (!hasData)
                    Text('No tests yet', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))
                  else ...[
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: avg / 100,
                      backgroundColor: cs.surfaceVariant,
                      color: avg >= 70 ? Colors.green : avg >= 50 ? Colors.orange : Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (hasData)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${avg.toStringAsFixed(1)}%',
                  style: tt.labelMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentScoreCard(TestScore score, ColorScheme cs, TextTheme tt) {
    final subject = _subjects.firstWhere(
      (s) => s.id == score.subjectId,
      orElse: () => Subject(name: 'Unknown'),
    );
    final color = AppTheme.subjectColor(subject.colorHex);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Text(score.grade, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        title: Text(score.testName, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: Text(subject.name, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        trailing: Text(
          '${score.score.toStringAsFixed(0)}/${score.maxScore.toStringAsFixed(0)}',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _emptyCard(String title, String subtitle, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
