import 'package:flutter/material.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/offline_course_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../courses/models/course_bundle_models.dart';
import '../../game_modes/game_mode_engine.dart';
import '../../golf_map/screens/golf_map_screen.dart';
import '../models/round_models.dart';
import 'scorecard_screen.dart';
import 'round_summary_screen.dart';

/// Screen for recording hole score (Gross, Putts, Penalties, FIR, GIR) for all flight players
class ScoreEntryScreen extends StatefulWidget {
  final RoundModel round;
  final CourseBundle bundle;
  final ApiClient apiClient;
  final OfflineCourseStorage storage;
  final LocationService locationService;
  final int initialHoleNumber;

  const ScoreEntryScreen({
    super.key,
    required this.round,
    required this.bundle,
    required this.apiClient,
    required this.storage,
    required this.locationService,
    this.initialHoleNumber = 1,
  });

  @override
  State<ScoreEntryScreen> createState() => _ScoreEntryScreenState();
}

class _ScoreEntryScreenState extends State<ScoreEntryScreen> {
  late int _currentHoleNumber;
  int _selectedPlayerIndex = 0;
  bool _isSaving = false;

  // Local cache of scores: key = "$playerId-$holeId"
  final Map<String, RoundScoreModel> _scoresCache = {};

  @override
  void initState() {
    super.initState();
    _currentHoleNumber = widget.initialHoleNumber;
    _initScoresForCurrentHole();
  }

  HoleData get _currentHole {
    return widget.bundle.holes.firstWhere(
      (h) => h.holeNumber == _currentHoleNumber,
      orElse: () => widget.bundle.holes.first,
    );
  }

  String _cacheKey(String playerId, String holeId) => '$playerId-$holeId';

  void _initScoresForCurrentHole() {
    final hole = _currentHole;
    for (final player in widget.round.players) {
      final key = _cacheKey(player.id, hole.id);
      if (!_scoresCache.containsKey(key)) {
        // Initialize with default par score
        _scoresCache[key] = RoundScoreModel(
          id: 'temp-$key',
          roundId: widget.round.id,
          playerId: player.id,
          holeId: hole.id,
          grossScore: hole.par,
          putts: 2,
          penalties: 0,
          fairwayHit: hole.par > 3 ? FairwayHit.straight : null,
          gir: true,
        );
      }
    }
  }

  RoundScoreModel _getCurrentPlayerScore() {
    final player = widget.round.players[_selectedPlayerIndex];
    final key = _cacheKey(player.id, _currentHole.id);
    return _scoresCache[key]!;
  }

  void _updateScore(void Function(RoundScoreModel score) update) {
    setState(() {
      final score = _getCurrentPlayerScore();
      update(score);
      // Validate putts <= grossScore
      if (score.putts > score.grossScore) {
        score.putts = score.grossScore;
      }
      // Re-evaluate default GIR if not explicitly touched
      score.gir ??= MobileGameModeEngine.calculateDefaultGir(
        grossScore: score.grossScore,
        putts: score.putts,
        par: _currentHole.par,
      );
    });
  }

  Future<void> _saveCurrentHoleScores() async {
    setState(() {
      _isSaving = true;
    });

    final hole = _currentHole;
    for (final player in widget.round.players) {
      final score = _scoresCache[_cacheKey(player.id, hole.id)];
      if (score != null) {
        try {
          await widget.apiClient.saveScore(
            roundId: widget.round.id,
            playerId: player.id,
            holeId: hole.id,
            grossScore: score.grossScore,
            putts: score.putts,
            penalties: score.penalties,
            fairwayHit: score.fairwayHit,
            gir: score.gir,
          );
        } catch (_) {
          // In offline mode, scores are kept in memory and local storage
        }
      }
    }

    setState(() {
      _isSaving = false;
    });
  }

  void _onNextHole() async {
    await _saveCurrentHoleScores();

    final currentIndex = widget.bundle.holes.indexWhere((h) => h.holeNumber == _currentHoleNumber);
    if (currentIndex < widget.bundle.holes.length - 1) {
      setState(() {
        _currentHoleNumber = widget.bundle.holes[currentIndex + 1].holeNumber;
        _initScoresForCurrentHole();
      });
      try {
        await widget.apiClient.updateCurrentHole(widget.round.id, _currentHoleNumber);
      } catch (_) {}
    } else {
      _onFinishRound();
    }
  }

  void _onPrevHole() async {
    await _saveCurrentHoleScores();

    final currentIndex = widget.bundle.holes.indexWhere((h) => h.holeNumber == _currentHoleNumber);
    if (currentIndex > 0) {
      setState(() {
        _currentHoleNumber = widget.bundle.holes[currentIndex - 1].holeNumber;
        _initScoresForCurrentHole();
      });
    }
  }

  void _onFinishRound() async {
    await _saveCurrentHoleScores();

    try {
      await widget.apiClient.finishRound(widget.round.id);
    } catch (_) {}

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RoundSummaryScreen(
            round: widget.round,
            bundle: widget.bundle,
            apiClient: widget.apiClient,
            storage: widget.storage,
            scoresMap: _scoresCache,
          ),
        ),
      );
    }
  }

  void _openScorecard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScorecardScreen(
          round: widget.round,
          bundle: widget.bundle,
          apiClient: widget.apiClient,
          localScores: _scoresCache.values.toList(),
        ),
      ),
    );
  }

  void _openGpsMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GolfMapScreen(
          bundle: widget.bundle,
          locationService: widget.locationService,
          initialHoleNumber: _currentHoleNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hole = _currentHole;
    final score = _getCurrentPlayerScore();
    final activePlayer = widget.round.players[_selectedPlayerIndex];
    final isLastHole =
        _currentHoleNumber == widget.bundle.holes.last.holeNumber;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('HOLE ${hole.holeNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: AppTheme.primaryGreen),
            tooltip: 'View GPS Map',
            onPressed: _openGpsMap,
          ),
          IconButton(
            icon: const Icon(Icons.grid_on_rounded, color: Colors.white70),
            tooltip: 'View Scorecard',
            onPressed: _openScorecard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hole Summary Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppTheme.darkSurface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HOLE ${hole.holeNumber}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Par ${hole.par}  •  Stroke Index ${hole.handicapIndex ?? "-"}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryGreen),
                    ),
                    child: Text(
                      widget.round.gameMode.displayName.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Player Tabs (if more than 1 player)
            if (widget.round.players.length > 1) ...[
              Container(
                height: 44,
                color: AppTheme.surfaceElevated,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.round.players.length,
                  itemBuilder: (context, index) {
                    final player = widget.round.players[index];
                    final isSelected = _selectedPlayerIndex == index;
                    return InkWell(
                      onTap: () => setState(() => _selectedPlayerIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          player.playerName,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.white54,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Active player name label
                  Text(
                    'SCORING FOR: ${activePlayer.playerName.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. GROSS SCORE STEPPER
                  _buildSectionCard(
                    title: 'GROSS SCORE',
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStepperButton(
                              icon: Icons.remove,
                              onTap: score.grossScore > 1
                                  ? () => _updateScore((s) => s.grossScore--)
                                  : null,
                            ),
                            Container(
                              width: 100,
                              alignment: Alignment.center,
                              child: Text(
                                '${score.grossScore}',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            _buildStepperButton(
                              icon: Icons.add,
                              onTap: () => _updateScore((s) => s.grossScore++),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Quick score chips (Birdie, Par, Bogey)
                        Wrap(
                          spacing: 8,
                          children: [
                            if (hole.par > 1)
                              _buildQuickChip('Birdie (${hole.par - 1})', hole.par - 1, score.grossScore),
                            _buildQuickChip('Par (${hole.par})', hole.par, score.grossScore),
                            _buildQuickChip('Bogey (${hole.par + 1})', hole.par + 1, score.grossScore),
                            _buildQuickChip('Dbl (${hole.par + 2})', hole.par + 2, score.grossScore),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. PUTTS & PENALTIES ROW
                  Row(
                    children: [
                      // Putts
                      Expanded(
                        child: _buildSectionCard(
                          title: 'PUTTS',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStepperButton(
                                icon: Icons.remove,
                                size: 36,
                                onTap: score.putts > 0
                                    ? () => _updateScore((s) => s.putts--)
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  '${score.putts}',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                ),
                              ),
                              _buildStepperButton(
                                icon: Icons.add,
                                size: 36,
                                onTap: score.putts < score.grossScore
                                    ? () => _updateScore((s) => s.putts++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Penalties
                      Expanded(
                        child: _buildSectionCard(
                          title: 'PENALTIES',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStepperButton(
                                icon: Icons.remove,
                                size: 36,
                                onTap: score.penalties > 0
                                    ? () => _updateScore((s) => s.penalties--)
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  '${score.penalties}',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                ),
                              ),
                              _buildStepperButton(
                                icon: Icons.add,
                                size: 36,
                                onTap: () => _updateScore((s) => s.penalties++),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. FAIRWAY HIT (FIR)
                  if (hole.par > 3) ...[
                    _buildSectionCard(
                      title: 'FAIRWAY HIT',
                      child: Row(
                        children: [
                          _buildFirOption('LEFT (↖)', FairwayHit.left, score.fairwayHit),
                          const SizedBox(width: 8),
                          _buildFirOption('HIT (↑)', FairwayHit.straight, score.fairwayHit),
                          const SizedBox(width: 8),
                          _buildFirOption('RIGHT (↗)', FairwayHit.right, score.fairwayHit),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 4. GREEN IN REGULATION (GIR)
                  _buildSectionCard(
                    title: 'GREEN IN REGULATION (GIR)',
                    child: Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('GIR YES (Hit Green)')),
                            selected: score.gir == true,
                            selectedColor: AppTheme.primaryGreen,
                            backgroundColor: AppTheme.surfaceElevated,
                            labelStyle: TextStyle(
                              color: score.gir == true ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) => _updateScore((s) => s.gir = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('GIR NO (Missed)')),
                            selected: score.gir == false,
                            selectedColor: Colors.redAccent,
                            backgroundColor: AppTheme.surfaceElevated,
                            labelStyle: TextStyle(
                              color: score.gir == false ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) => _updateScore((s) => s.gir = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppTheme.darkSurface,
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
                onPressed: _currentHoleNumber > 1 ? _onPrevHole : null,
                tooltip: 'Previous Hole',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _onNextHole,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Icon(
                            isLastHole ? Icons.flag_rounded : Icons.check_circle_outline_rounded,
                            color: Colors.black,
                          ),
                    label: Text(
                      isLastHole ? 'FINISH ROUND' : 'SAVE & NEXT HOLE',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Colors.black,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70),
                onPressed: _onNextHole,
                tooltip: 'Next Hole',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback? onTap,
    double size = 44,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: onTap != null ? AppTheme.surfaceElevated : Colors.white10,
            shape: BoxShape.circle,
            border: Border.all(color: onTap != null ? Colors.white24 : Colors.transparent),
          ),
          child: Icon(icon, color: onTap != null ? Colors.white : Colors.white24),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, int value, int currentScore) {
    final isSelected = currentScore == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: AppTheme.surfaceElevated,
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white70),
      onSelected: (_) => _updateScore((s) => s.grossScore = value),
    );
  }

  Widget _buildFirOption(String label, FairwayHit hit, FairwayHit? current) {
    final isSelected = current == hit;
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label, style: const TextStyle(fontSize: 12))),
        selected: isSelected,
        selectedColor: AppTheme.primaryGreen,
        backgroundColor: AppTheme.surfaceElevated,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => _updateScore((s) => s.fairwayHit = hit),
      ),
    );
  }
}
