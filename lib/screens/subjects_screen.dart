import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/subject.dart';
import '../theme/app_theme.dart';
import 'scores_screen.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<Subject> _subjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final subjects = await DatabaseHelper.instance.getAllSubjects();
    setState(() {
      _subjects = subjects;
      _loading = false;
    });
  }

  void _showSubjectDialog({Subject? editing}) {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final descCtrl = TextEditingController(text: editing?.description ?? '');
    String selectedColor = editing?.colorHex ?? AppTheme.subjectColors[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(editing == null ? 'Add Subject' : 'Edit Subject'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Subject Name', prefixIcon: Icon(Icons.book_rounded)),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description (optional)', prefixIcon: Icon(Icons.notes_rounded)),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Color', style: Theme.of(ctx).textTheme.labelMedium),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: AppTheme.subjectColors.map((hex) {
                    final c = AppTheme.subjectColor(hex);
                    return GestureDetector(
                      onTap: () => setS(() => selectedColor = hex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == hex ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: selectedColor == hex
                              ? [BoxShadow(color: c.withOpacity(0.6), blurRadius: 8, spreadRadius: 2)]
                              : [],
                        ),
                        child: selectedColor == hex
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final db = DatabaseHelper.instance;
                if (editing == null) {
                  await db.insertSubject(Subject(
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    colorHex: selectedColor,
                  ));
                } else {
                  await db.updateSubject(editing.copyWith(
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    colorHex: selectedColor,
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

  Future<void> _deleteSubject(Subject s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Delete "${s.name}" and all its test scores? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteSubject(s.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined, size: 72, color: cs.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('No subjects yet', style: tt.headlineSmall),
                      Text('Tap + to add your first subject', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _subjects.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          children: [
                            Text('Subjects', style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text('${_subjects.length} total', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      );
                    }
                    final s = _subjects[i - 1];
                    final color = AppTheme.subjectColor(s.colorHex);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ScoresScreen(subject: s)),
                        ).then((_) => _load()),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    s.name[0].toUpperCase(),
                                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                    if (s.description != null && s.description!.isNotEmpty)
                                      Text(s.description!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') _showSubjectDialog(editing: s);
                                  if (v == 'delete') _deleteSubject(s);
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_rounded), title: Text('Edit'), contentPadding: EdgeInsets.zero)),
                                  const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_rounded), title: Text('Delete'), contentPadding: EdgeInsets.zero)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubjectDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
      ),
    );
  }
}
