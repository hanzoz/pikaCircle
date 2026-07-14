import 'dart:math' as math;

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pikacircle/core/appwrite/appwrite_providers.dart';
import 'package:pikacircle/core/constants/table_ids.dart';
import 'package:pikacircle/features/auth/presentation/controllers/auth_controller.dart';

final _profileSkillGraphProvider =
    FutureProvider.autoDispose<_PlayerSkillGraph?>((ref) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null || userId.isEmpty) return null;

      final tables = ref.watch(appwriteTablesDbProvider);
      final config = ref.watch(appwriteConfigProvider);

      try {
        String? relationId(Object? value) {
          if (value is Map) {
            final relationValue = value[r'$id'];
            final relationId = relationValue?.toString().trim();
            return relationId == null || relationId.isEmpty ? null : relationId;
          }
          final normalized = value?.toString().trim();
          if (normalized == null || normalized.isEmpty) return null;
          return normalized;
        }

        final rows = await tables.listRows(
          databaseId: config.databaseId,
          tableId: TableIds.skills,
          queries: [Query.equal('user_id', userId), Query.limit(1)],
        );
        if (rows.rows.isEmpty) {
          // Backward-compatible fallbacks for environments where skills row ids
          // are deterministic and not queryable by user_id due to
          // permission/index differences.
          for (final rowId in <String>[userId, 'skill_$userId']) {
            try {
              final row = await tables.getRow(
                databaseId: config.databaseId,
                tableId: TableIds.skills,
                rowId: rowId,
              );
              return _PlayerSkillGraph.fromRow(row.data);
            } on AppwriteException catch (fallbackError) {
              if (fallbackError.code != 404) rethrow;
            }
          }

          // Final fallback: read a page and match relation id client-side.
          // This helps when relationship query behavior differs across
          // environments.
          final scanRows = await tables.listRows(
            databaseId: config.databaseId,
            tableId: TableIds.skills,
            queries: [Query.limit(200)],
          );
          for (final row in scanRows.rows) {
            final relatedUserId = relationId(row.data['user_id']);
            if (relatedUserId == userId || row.$id == userId) {
              return _PlayerSkillGraph.fromRow(row.data);
            }
          }

          return null;
        }
        return _PlayerSkillGraph.fromRow(rows.rows.first.data);
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          return null;
        }
        rethrow;
      }
    });

class ProfileSkillGraphSection extends ConsumerWidget {
  const ProfileSkillGraphSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_profileSkillGraphProvider);
    final textTheme = Theme.of(context).textTheme;

    return state.when(
      loading: () => _SkillGraphCard(
        child: const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      ),
      error: (_, _) => _SkillGraphCard(
        child: SizedBox(
          height: 120,
          child: Center(
            child: Text(
              'Could not load skill graph.',
              style: textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6F7482),
              ),
            ),
          ),
        ),
      ),
      data: (skillGraph) {
        if (skillGraph == null) {
          return _SkillGraphCard(
            child: SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'No skill profile found for this user yet.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6F7482),
                  ),
                ),
              ),
            ),
          );
        }

        final hasAnyScore = skillGraph.axes.any((axis) => axis.score > 0);
        final radarMaxScore = _resolveRadarMaxScore(skillGraph);

        return _SkillGraphCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Skill graph',
                      style: textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF1D2230),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (skillGraph.overallSkillRating != null)
                    Text(
                      'Overall ${skillGraph.overallSkillRating!.toStringAsFixed(1)}',
                      style: textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF6F7482),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (!hasAnyScore)
                SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'Skill scores are not available yet.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6F7482),
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 240,
                  child: CustomPaint(
                    painter: _SkillRadarPainter(
                      axes: skillGraph.axes,
                      maxSkillScore: radarMaxScore,
                      lineColor: Theme.of(context).colorScheme.primary,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.25),
                      gridColor: const Color(0xFFCFE8E6),
                      labelColor: const Color(0xFF2F3340),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SkillGraphCard extends StatelessWidget {
  const _SkillGraphCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FA),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF0F1F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SkillAxisScore {
  const _SkillAxisScore({required this.label, required this.score});

  final String label;
  final double score;
}

class _PlayerSkillGraph {
  const _PlayerSkillGraph({
    required this.axes,
    required this.overallSkillRating,
  });

  final List<_SkillAxisScore> axes;
  final double? overallSkillRating;

  factory _PlayerSkillGraph.fromRow(Map<String, dynamic> data) {
    final serve = _normalizeSkillScore(_toDouble(data['serve']));
    final returns = _normalizeSkillScore(_toDouble(data['return']));
    final offense = _normalizeSkillScore(_toDouble(data['offense']));
    final defense = _normalizeSkillScore(_toDouble(data['defense']));
    final agility = _normalizeSkillScore(_toDouble(data['agility']));
    final consistency = _normalizeSkillScore(_toDouble(data['consistency']));

    return _PlayerSkillGraph(
      axes: <_SkillAxisScore>[
        _SkillAxisScore(label: 'SRV', score: serve),
        _SkillAxisScore(label: 'RET', score: returns),
        _SkillAxisScore(label: 'OFF', score: offense),
        _SkillAxisScore(label: 'DEF', score: defense),
        _SkillAxisScore(label: 'AGI', score: agility),
        _SkillAxisScore(label: 'CON', score: consistency),
      ],
      overallSkillRating: _toDouble(data['overall_skill_rating']),
    );
  }
}

class _SkillRadarPainter extends CustomPainter {
  _SkillRadarPainter({
    required this.axes,
    required this.maxSkillScore,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<_SkillAxisScore> axes;
  final double maxSkillScore;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (axes.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2 + 6);
    final radius = math.min(size.width, size.height) * 0.33;
    final axisCount = axes.length;

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final axisPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var level = 1; level <= 4; level++) {
      final scale = level / 4;
      final ringPoints = List<Offset>.generate(axisCount, (index) {
        final angle = _angleForIndex(index, axisCount);
        return center +
            Offset(math.cos(angle), math.sin(angle)) * (radius * scale);
      });
      canvas.drawPath(_polygonPath(ringPoints), gridPaint);
    }

    for (var i = 0; i < axisCount; i++) {
      final angle = _angleForIndex(i, axisCount);
      final end = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawLine(center, end, axisPaint);
    }

    final dataPoints = List<Offset>.generate(axisCount, (index) {
      final normalized = (axes[index].score / maxSkillScore)
          .clamp(0.0, 1.0)
          .toDouble();
      final angle = _angleForIndex(index, axisCount);
      return center +
          Offset(math.cos(angle), math.sin(angle)) * (radius * normalized);
    });

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;

    final pointFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final pointStrokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;

    final polygonPath = _polygonPath(dataPoints);
    canvas.drawPath(polygonPath, fillPaint);
    canvas.drawPath(polygonPath, strokePaint);

    for (final point in dataPoints) {
      canvas.drawCircle(point, 5.2, pointFillPaint);
      canvas.drawCircle(point, 5.2, pointStrokePaint);
    }

    for (var i = 0; i < axisCount; i++) {
      final angle = _angleForIndex(i, axisCount);
      final labelOffset =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius + 24);
      final text = '${axes[i].label} ${axes[i].score.toStringAsFixed(1)}';

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: labelColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final textPosition = Offset(
        labelOffset.dx - textPainter.width / 2,
        labelOffset.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, textPosition);
    }
  }

  @override
  bool shouldRepaint(covariant _SkillRadarPainter oldDelegate) {
    return oldDelegate.axes != axes ||
        oldDelegate.maxSkillScore != maxSkillScore ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelColor != labelColor;
  }

  Path _polygonPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    return path;
  }

  double _angleForIndex(int index, int axisCount) {
    return -math.pi / 2 + (index * 2 * math.pi / axisCount);
  }
}

double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

double _normalizeSkillScore(double? value) {
  if (value == null || value.isNaN) return 0;
  return value.clamp(0, 100).toDouble();
}

double _resolveRadarMaxScore(_PlayerSkillGraph skillGraph) {
  const fallbackMax = 8.0;
  final overall = skillGraph.overallSkillRating;
  final derivedMax = overall != null && overall > 0
      ? overall + 2.0
      : fallbackMax;
  final highestAxisScore = skillGraph.axes.fold<double>(
    0,
    (maxScore, axis) => math.max(maxScore, axis.score),
  );

  return math.max(derivedMax, highestAxisScore).clamp(1.0, 100.0).toDouble();
}
