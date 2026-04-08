class TestScore {
  final int? id;
  final int subjectId;
  final String testName;
  final double score;
  final double maxScore;
  final DateTime date;
  final String? notes;

  TestScore({
    this.id,
    required this.subjectId,
    required this.testName,
    required this.score,
    required this.maxScore,
    DateTime? date,
    this.notes,
  }) : date = date ?? DateTime.now();

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;

  String get grade {
    final p = percentage;
    if (p >= 90) return 'A+';
    if (p >= 80) return 'A';
    if (p >= 70) return 'B';
    if (p >= 60) return 'C';
    if (p >= 50) return 'D';
    return 'F';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'subjectId': subjectId,
        'testName': testName,
        'score': score,
        'maxScore': maxScore,
        'date': date.toIso8601String(),
        'notes': notes,
      };

  factory TestScore.fromMap(Map<String, dynamic> map) => TestScore(
        id: map['id'],
        subjectId: map['subjectId'],
        testName: map['testName'],
        score: map['score'],
        maxScore: map['maxScore'],
        date: DateTime.parse(map['date']),
        notes: map['notes'],
      );
}
