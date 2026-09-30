import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/offline_course_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../courses/models/course_bundle_models.dart';
import '../../game_modes/game_mode_engine.dart';
import '../../health/models/health_models.dart';
import '../../health/screens/health_dashboard_screen.dart';
import '../../health/services/health_service.dart';
import '../models/round_models.dart';
import 'scorecard_screen.dart';

/// Screen displaying round results, leaderboard, and statistics summary
class RoundSummaryScreen extends StatefulWidget {
  final RoundModel round;
  final CourseBundle bundle;
  final ApiClient apiClient;
  final OfflineCourseStorage storage;
  final Map<String, RoundScoreModel> scoresMap;
  final IHealthService? healthService;

  const RoundSummaryScreen({
    super.key,
    required this.round,
    required this.bundle,
    required this.apiClient,
    required this.storage,
    required this.scoresMap,
    this.healthService,
  });

  @override
  State<RoundSummaryScreen> createState() => _RoundSummaryScreenState();
}

class _RoundSummaryScreenState extends State<RoundSummaryScreen> {
  Map<String, dynamic>? _apiResult;
  GolfHealthMetrics? _healthMetrics;
  late final IHealthService _healthService;

  @override
  void initState() {
    super.initState();
    _healthService = widget.healthService ?? HealthService();
    _fetchApiResult();
    _fetchHealthMetrics();
  }

  Future<void> _fetchHealthMetrics() async {
    try {
      final metrics = await _healthService.getRoundHealthMetrics(
        roundId: widget.round.id,
        startTime: DateTime.now().subtract(const Duration(hours: 3)),
      );
      if (mounted) {
        setState(() {
          _healthMetrics = metrics;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchApiResult() async {
    try {
      final res = await widget.apiClient.getRoundResult(widget.round.id);
      if (mounted) {
        setState(() {
          _apiResult = res;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final players = widget.round.players;
    final allScores = widget.scoresMap.values.toList();

    // Compute player statistics
    final playerSummaries = players.map((player) {
      final pScores = allScores.where((s) => s.playerId == player.id).toList();
      int gross = 0;
      int putts = 0;
      int penalties = 0;
      int firCount = 0;
      int firPossible = 0;
      int girCount = 0;
      int girPossible = 0;
      int stablefordPoints = 0;

      for (final s in pScores) {
        gross += s.grossScore;
        putts += s.putts;
        penalties += s.penalties;

        final hole = widget.bundle.holes.cast<HoleData?>().firstWhere(
              (h) => h?.id == s.holeId,
              orElse: () => null,
            );

        if (hole != null) {
          if (hole.par > 3) {
            firPossible++;
            if (s.fairwayHit == FairwayHit.straight) firCount++;
          }
          stablefordPoints += MobileGameModeEngine.calculateStablefordPoints(s.grossScore, hole.par);
        }

        if (s.gir != null) {
          girPossible++;
          if (s.gir == true) girCount++;
        }
      }

      return {
        'player': player,
        'gross': gross,
        'putts': putts,
        'penalties': penalties,
        'firCount': firCount,
        'firPossible': firPossible,
        'girCount': girCount,
        'girPossible': girPossible,
        'stablefordPoints': stablefordPoints,
        'holesPlayed': pScores.length,
      };
    }).toList();

    // Sort by game mode
    if (widget.round.gameMode == GameMode.stableford) {
      playerSummaries.sort((a, b) =>
          (b['stablefordPoints'] as int).compareTo(a['stablefordPoints'] as int));
    } else {
      playerSummaries.sort(
          (a, b) => (a['gross'] as int).compareTo(b['gross'] as int));
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('ROUND SUMMARY'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.bundle.course.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryGreen),
                        ),
                        child: Text(
                          widget.round.gameMode.displayName.toUpperCase(),
                          style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Round Finished  •  ${widget.bundle.holes.length} Holes',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                  if (_apiResult != null && _apiResult!['matchPlay'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Match Result: ${_apiResult!['matchPlay']['matchStatus'] ?? ""}',
                      style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Health & Fitness Section
            _buildHealthSummaryCard(),
            const SizedBox(height: 16),

            // Leaderboard / Results Section
            const Text(
              'LEADERBOARD',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 10),

            ...playerSummaries.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final data = entry.value;
              final player = data['player'] as RoundPlayerModel;
              final gross = data['gross'] as int;
              final putts = data['putts'] as int;
              final penalties = data['penalties'] as int;
              final pts = data['stablefordPoints'] as int;
              final firCount = data['firCount'] as int;
              final firPossible = data['firPossible'] as int;
              final girCount = data['girCount'] as int;
              final girPossible = data['girPossible'] as int;

              final firPct = firPossible > 0 ? ((firCount / firPossible) * 100).round() : 0;
              final girPct = girPossible > 0 ? ((girCount / girPossible) * 100).round() : 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: rank == 1
                      ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                      : AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: rank == 1 ? AppTheme.primaryGreen : Colors.white12,
                    width: rank == 1 ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: rank == 1 ? AppTheme.primaryGreen : AppTheme.surfaceElevated,
                          child: Text(
                            '$rank',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: rank == 1 ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.playerName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              if (player.teamId != null)
                                Text(
                                  player.teamId!,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.round.gameMode == GameMode.stableford
                                  ? '$pts PTS'
                                  : '$gross',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textHighContrast,
                              ),
                            ),
                            Text(
                              widget.round.gameMode == GameMode.stableford
                                  ? 'Gross $gross'
                                  : 'Total Gross',
                              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('PUTTS', '$putts'),
                        _buildStat('PENALTIES', '$penalties'),
                        _buildStat('FIR', '$firPct% ($firCount/$firPossible)'),
                        _buildStat('GIR', '$girPct% ($girCount/$girPossible)'),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppTheme.darkSurface,
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScorecardScreen(
                          round: widget.round,
                          bundle: widget.bundle,
                          apiClient: widget.apiClient,
                          localScores: allScores,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.grid_on_rounded, color: Colors.white70),
                  label: const Text('SCORECARD', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  icon: const Icon(Icons.home_rounded, color: Colors.black),
                  label: const Text(
                    'DONE',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthSummaryCard() {
    final m = _healthMetrics;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.favorite, color: AppTheme.primaryRed, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'HEALTH & FITNESS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HealthDashboardScreen(
                        healthService: _healthService,
                        activeRoundId: widget.round.id,
                        courseName: widget.bundle.course.name,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('STEPS', m?.formattedSteps ?? '---'),
              _buildStat('DISTANCE', m?.formattedDistanceKm ?? '---'),
              _buildStat('CALORIES', m?.formattedCalories ?? '---'),
              _buildStat('DURATION', m?.formattedDuration ?? '---'),
            ],
          ),
          if (m != null && m.limitationNote != null) ...[
            const SizedBox(height: 10),
            Text(
              m.limitationNote!,
              style: const TextStyle(fontSize: 10, color: Colors.white38),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}
