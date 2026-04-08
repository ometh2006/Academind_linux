import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/subject.dart';
import '../models/test_score.dart';
import '../theme/app_theme.dart';

class ScoresScreen extends StatefulWidget {
  final Subject subject;
  const ScoresScreen({super.key, required this.subject});

  @override
  State<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends State<ScoresScreen> {
  List<TestScore> _scores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scores = await DatabaseHelper.instance.getScoresForSubject(widget.subject.id!);
    setState(() {
      _scores = scores;
      _loading = false;
    });
  }

  double get _average => _scores.isEmpty ? 0 : _scores.map((s) => s.percentage).reduce((a, b) => a + b) / _scores.length;
  double get _best => _scores.isEmpty ? 0 : _scores.map((s) => s.percentage).reduce((a, b) => a > b ? a : b);

  void _showAddScoreDialog({TestScore? editing}) {
    final nameCtrl = TextEditingController(text: editing?.testName ?? '');
    final scoreCtrl = TextEditingController(text: editing?.score.toString() ?? '');
    final maxCtrl = TextEditingController(text: editing?.maxScore.toString() ?? '100');
    final notesCtrl = TextEditingController(text: editing?.notes ?? '');
    DateTime selectedDate = editing?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(editing == null ? 'Add Test Score' : 'Edit Score'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Test Name', prefixIcon: Icon(Icons.quiz_rounded)),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: scoreCtrl,
                        decoration: const InputDecoration(labelText: 'Score', prefixIcon: Icon(Icons.grade_rounded)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxCtrl,
                        decoration: const InputDecoration(labelText: 'Out of', prefixIcon: Icon(Icons.score_rounded)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setS(() => selectedDate = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today_rounded)),
                    child: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.notes_rounded)),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final s = double.tryParse(scoreCtrl.text) ?? 0;
                final m = double.tryParse(maxCtrl.text) ?? 100;
                final db = DatabaseHelper.instance;
                if (editing == null) {
                  await db.insertScore(TestScore(
                    subjectId: widget.subject.id!,
                    testName: nameCtrl.text.trim(),
                    score: s,
                    maxScore: m,
                    date: selectedDate,
                    notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  ));
                } else {
                  await db.updateScore(TestScore(
                    id: editing.id,
                    subjectId: editing.subjectId,
                    testName: nameCtrl.text.trim(),
                    score: s,
                    maxScore: m,
                    date: selectedDate,
                    notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  ));
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: Text(editing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteScore(TestScore score) async {
    await DatabaseHelper.instance.deleteScore(score.id!);
    _load();
  }

  Color _gradeColor(double pct) {
    if (pct >= 80) return Colors.green;
    if (pct >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = AppTheme.subjectColor(widget.subject.colorHex);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
        backgroundColor: color.withOpacity(0.15),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats banner
                if (_scores.isNotEmpty)
                  Container(
                    color: color.withOpacity(0.08),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _miniStat('Tests', '${_scores.length}', tt, cs),
                        _divider(),
                        _miniStat('Average', '${_average.toStringAsFixed(1)}%', tt, cs),
                        _divider(),
                        _miniStat('Best', '${_best.toStringAsFixed(1)}%', tt, cs),
                      ],
                    ),
                  ),
                // List
                Expanded(
                  child: _scores.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.quiz_outlined, size: 72, color: cs.onSurfaceVariant),
                              const SizedBox(height: 16),
                              Text('No tests yet', style: tt.headlineSmall),
                              Text('Tap + to add your first test score', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _scores.length,
                          itemBuilder: (ctx, i) {
                            final score = _scores[i];
                            final gc = _gradeColor(score.percentage);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56, height: 56,
                                      decoration: BoxDecoration(
                                        color: gc.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Text(score.grade, style: TextStyle(color: gc, fontWeight: FontWeight.bold, fontSize: 18)),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(score.testName, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                          Text(DateFormat('MMM d, yyyy').format(score.date), style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                                          const SizedBox(height: 6),
                                          LinearProgressIndicator(
                                            value: score.percentage / 100,
                                            backgroundColor: cs.surfaceVariant,
                                            color: gc,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${score.score.toStringAsFixed(0)}/${score.maxScore.toStringAsFixed(0)}',
                                          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        Text('${score.percentage.toStringAsFixed(1)}%', style: tt.bodySmall?.copyWith(color: gc)),
                                      ],
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == 'edit') _showAddScoreDialog(editing: score);
                                        if (v == 'delete') _deleteScore(score);
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_rounded), title: Text('Edit'), contentPadding: EdgeInsets.zero)),
                                        const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_rounded), title: Text('Delete'), contentPadding: EdgeInsets.zero)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddScoreDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Test'),
      ),
    );
  }

  Widget _miniStat(String label, String val, TextTheme tt, ColorScheme cs) => Column(
        children: [
          Text(val, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      );

  Widget _divider() => Container(width: 1, height: 40, color: Theme.of(context).colorScheme.outline.withOpacity(0.3));
}
