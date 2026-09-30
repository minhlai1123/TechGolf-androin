import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/offline_score_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../courses/models/course_bundle_models.dart';
import '../../game_modes/game_mode_engine.dart';
import '../../liveplay/screens/liveplay_screen.dart';
import '../models/round_models.dart';

enum ScorecardViewCategory {
  gross,
  putts,
  penalties,
  fir,
  gir,
  stableford,
}

/// Comprehensive Digital Scorecard screen supporting 1-4 players and all Game Modes
class ScorecardScreen extends StatefulWidget {
  final RoundModel round;
  final CourseBundle bundle;
  final ApiClient apiClient;
  final List<RoundScoreModel> localScores;

  const ScorecardScreen({
    super.key,
    required this.round,
    required this.bundle,
    required this.apiClient,
    this.localScores = const [],
  });

  @override
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> {
  ScorecardMatrix? _matrix;
  bool _isLoading = true;
  ScorecardViewCategory _activeCategory = ScorecardViewCategory.gross;

  @override
  void initState() {
    super.initState();
    _loadScorecard();
  }

  Future<void> _loadScorecard() async {
    setState(() {
      _isLoading = true;
    });

    // Opportunistically flush pending offline scores before fetching scorecard
    try {
      await OfflineScoreStorage.syncPendingScores(widget.apiClient, widget.round.id);
    } catch (_) {}

    try {
      final matrix = await widget.apiClient.getScorecard(widget.round.id);
      if (mounted) {
        setState(() {
          _matrix = matrix;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Offline fallback: construct matrix from bundle and localScores (or OfflineScoreStorage)
      var effectiveScores = widget.localScores;
      if (effectiveScores.isEmpty) {
        final cached = await OfflineScoreStorage.getScoresForRound(widget.round.id);
        effectiveScores = cached.values.toList();
      }

      final holesList = widget.bundle.holes
          .map((h) => ScorecardHoleInfo(
                id: h.id,
                holeNumber: h.holeNumber,
                par: h.par,
                handicapIndex: h.handicapIndex,
              ))
          .toList();

      final totals = widget.round.players.map((p) {
        final pScores = effectiveScores.filter((s) => s.playerId == p.id);
        int gross = 0;
        int putts = 0;
        int penalties = 0;
        int firCount = 0;
        int firPossible = 0;
        int girCount = 0;
        int girPossible = 0;

        for (final s in pScores) {
          gross += s.grossScore;
          putts += s.putts;
          penalties += s.penalties;
          final hole = widget.bundle.holes.cast<HoleData?>().firstWhere(
                (h) => h?.id == s.holeId,
                orElse: () => null,
              );
          if (hole != null && hole.par > 3) {
            firPossible++;
            if (s.fairwayHit == FairwayHit.straight) firCount++;
          }
          if (s.gir != null) {
            girPossible++;
            if (s.gir == true) girCount++;
          }
        }

        return PlayerScorecardTotal(
          playerId: p.id,
          playerName: p.playerName,
          playerOrder: p.playerOrder,
          teamId: p.teamId,
          grossScore: gross,
          putts: putts,
          penalties: penalties,
          firCount: firCount,
          firPossible: firPossible,
          girCount: girCount,
          girPossible: girPossible,
          holesCompleted: pScores.length,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _matrix = ScorecardMatrix(
            roundId: widget.round.id,
            gameMode: widget.round.gameMode,
            status: widget.round.status,
            currentHole: widget.round.currentHole,
            holes: holesList,
            players: widget.round.players,
            scores: widget.localScores,
            totals: totals,
          );
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('SCORECARD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt, color: Colors.amber),
            tooltip: 'LivePlay Realtime',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LivePlayScreen(
                    roundId: widget.round.id,
                    apiClient: widget.apiClient,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScorecard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : _buildScorecardBody(),
    );
  }

  Widget _buildScorecardBody() {
    if (_matrix == null) {
      return const Center(child: Text('No scorecard data available'));
    }

    final matrix = _matrix!;
    final holes = matrix.holes;
    final players = matrix.players;

    return Column(
      children: [
        // Category Selector Chips
        Container(
          height: 48,
          color: AppTheme.darkSurface,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              _buildCategoryChip('Gross Score', ScorecardViewCategory.gross),
              _buildCategoryChip('Putts', ScorecardViewCategory.putts),
              _buildCategoryChip('Penalties', ScorecardViewCategory.penalties),
              _buildCategoryChip('Fairways (FIR)', ScorecardViewCategory.fir),
              _buildCategoryChip('Greens (GIR)', ScorecardViewCategory.gir),
              if (widget.round.gameMode == GameMode.stableford)
                _buildCategoryChip('Stableford Points', ScorecardViewCategory.stableford),
            ],
          ),
        ),

        // Scrollable Scorecard Table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Table(
                  defaultColumnWidth: const FixedColumnWidth(42),
                  columnWidths: const {
                    0: FixedColumnWidth(110), // Player/Header Column
                  },
                  border: TableBorder.all(color: Colors.white12, width: 1),
                  children: [
                    // Header Row: Hole Numbers
                    TableRow(
                      decoration: const BoxDecoration(color: AppTheme.surfaceElevated),
                      children: [
                        _buildCell('HOLE', isHeader: true),
                        ...holes.map((h) => _buildCell('${h.holeNumber}', isHeader: true)),
                        _buildCell('OUT', isHeader: true),
                        if (holes.length > 9) _buildCell('IN', isHeader: true),
                        _buildCell('TOT', isHeader: true),
                      ],
                    ),

                    // Par Row
                    TableRow(
                      decoration: BoxDecoration(color: AppTheme.darkSurface.withValues(alpha: 0.8)),
                      children: [
                        _buildCell('PAR', isHeader: true, textColor: AppTheme.textMuted),
                        ...holes.map((h) => _buildCell('${h.par}', textColor: AppTheme.textMuted)),
                        _buildCell('${_calculateOutPar(holes)}', textColor: AppTheme.textMuted),
                        if (holes.length > 9)
                          _buildCell('${_calculateInPar(holes)}', textColor: AppTheme.textMuted),
                        _buildCell('${holes.fold<int>(0, (s, h) => s + h.par)}', textColor: AppTheme.textMuted),
                      ],
                    ),

                    // Players Rows
                    ...players.map((player) {
                      return TableRow(
                        decoration: BoxDecoration(
                          color: players.indexOf(player).isEven
                              ? AppTheme.darkSurface
                              : AppTheme.surfaceElevated.withValues(alpha: 0.5),
                        ),
                        children: [
                          // Player Name Cell
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              player.playerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),

                          // Holes Values
                          ...holes.map((h) {
                            final score = matrix.scores.cast<RoundScoreModel?>().firstWhere(
                                  (s) => s?.playerId == player.id && s?.holeId == h.id,
                                  orElse: () => null,
                                );
                            return _buildScoreCell(score, h);
                          }),

                          // OUT Total
                          _buildTotalCell(player.id, holes.take(9).toList()),

                          // IN Total (if > 9 holes)
                          if (holes.length > 9)
                            _buildTotalCell(player.id, holes.skip(9).take(9).toList()),

                          // GRAND TOTAL
                          _buildTotalCell(player.id, holes, isGrandTotal: true),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Score Color Legend
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppTheme.darkSurface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Eagle', Colors.amber, isCircle: true),
              _buildLegendItem('Birdie', Colors.redAccent, isCircle: true),
              _buildLegendItem('Par', Colors.white, isCircle: false),
              _buildLegendItem('Bogey', Colors.blueAccent, isSquare: true),
              _buildLegendItem('Dbl+', Colors.purpleAccent, isSquare: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String title, ScorecardViewCategory category) {
    final isSelected = _activeCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(title, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        selectedColor: AppTheme.primaryGreen,
        backgroundColor: AppTheme.surfaceElevated,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => setState(() => _activeCategory = category),
      ),
    );
  }

  Widget _buildCell(String text, {bool isHeader = false, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 11 : 12,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: textColor ?? Colors.white,
        ),
      ),
    );
  }

  Widget _buildScoreCell(RoundScoreModel? score, ScorecardHoleInfo hole) {
    if (score == null) {
      return _buildCell('-', textColor: Colors.white30);
    }

    String display = '-';
    Color? cellColor;
    bool isCircle = false;
    bool isSquare = false;

    switch (_activeCategory) {
      case ScorecardViewCategory.gross:
        display = '${score.grossScore}';
        final diff = score.grossScore - hole.par;
        if (diff <= -2) {
          cellColor = Colors.amber;
          isCircle = true;
        } else if (diff == -1) {
          cellColor = Colors.redAccent;
          isCircle = true;
        } else if (diff == 0) {
          cellColor = Colors.white;
        } else if (diff == 1) {
          cellColor = Colors.blueAccent;
          isSquare = true;
        } else {
          cellColor = Colors.purpleAccent;
          isSquare = true;
        }
        break;

      case ScorecardViewCategory.putts:
        display = '${score.putts}';
        break;

      case ScorecardViewCategory.penalties:
        display = '${score.penalties}';
        break;

      case ScorecardViewCategory.fir:
        if (hole.par <= 3) {
          display = 'N/A';
        } else {
          display = score.fairwayHit == FairwayHit.straight
              ? '✓'
              : (score.fairwayHit == FairwayHit.left ? 'L' : (score.fairwayHit == FairwayHit.right ? 'R' : '-'));
        }
        break;

      case ScorecardViewCategory.gir:
        display = score.gir == true ? '✓' : (score.gir == false ? '✗' : '-');
        break;

      case ScorecardViewCategory.stableford:
        final pts = MobileGameModeEngine.calculateStablefordPoints(score.grossScore, hole.par);
        display = '$pts';
        break;
    }

    return Container(
      height: 38,
      alignment: Alignment.center,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isSquare ? BorderRadius.circular(4) : null,
          border: isCircle || isSquare ? Border.all(color: cellColor!, width: 1.5) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          display,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: cellColor ?? Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCell(String playerId, List<ScorecardHoleInfo> subsetHoles, {bool isGrandTotal = false}) {
    final subsetHoleIds = subsetHoles.map((h) => h.id).toSet();
    final pScores = _matrix!.scores.where((s) => s.playerId == playerId && subsetHoleIds.contains(s.holeId));

    int sum = 0;
    for (final s in pScores) {
      if (_activeCategory == ScorecardViewCategory.gross) {
        sum += s.grossScore;
      } else if (_activeCategory == ScorecardViewCategory.putts) {
        sum += s.putts;
      } else if (_activeCategory == ScorecardViewCategory.penalties) {
        sum += s.penalties;
      } else if (_activeCategory == ScorecardViewCategory.stableford) {
        final hole = subsetHoles.firstWhere((h) => h.id == s.holeId);
        sum += MobileGameModeEngine.calculateStablefordPoints(s.grossScore, hole.par);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      color: isGrandTotal ? AppTheme.primaryGreen.withValues(alpha: 0.15) : null,
      child: Text(
        sum > 0 ? '$sum' : '-',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isGrandTotal ? AppTheme.primaryGreen : Colors.white,
        ),
      ),
    );
  }

  int _calculateOutPar(List<ScorecardHoleInfo> holes) =>
      holes.take(9).fold<int>(0, (sum, h) => sum + h.par);

  int _calculateInPar(List<ScorecardHoleInfo> holes) =>
      holes.skip(9).take(9).fold<int>(0, (sum, h) => sum + h.par);

  Widget _buildLegendItem(String label, Color color, {bool isCircle = false, bool isSquare = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isSquare ? BorderRadius.circular(3) : null,
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }
}

extension ListFilterExtension<T> on List<T> {
  List<T> filter(bool Function(T element) test) => where(test).toList();
}
