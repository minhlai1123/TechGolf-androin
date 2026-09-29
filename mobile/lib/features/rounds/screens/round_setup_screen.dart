import 'package:flutter/material.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/offline_course_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../courses/models/course_bundle_models.dart';
import '../../game_modes/game_mode_engine.dart';
import '../models/round_models.dart';
import 'score_entry_screen.dart';

/// Screen for configuring Flight (1-4 players) and Game Mode to start a round
class RoundSetupScreen extends StatefulWidget {
  final CourseBundle bundle;
  final ApiClient apiClient;
  final OfflineCourseStorage storage;
  final LocationService locationService;

  const RoundSetupScreen({
    super.key,
    required this.bundle,
    required this.apiClient,
    required this.storage,
    required this.locationService,
  });

  @override
  State<RoundSetupScreen> createState() => _RoundSetupScreenState();
}

class _RoundSetupScreenState extends State<RoundSetupScreen> {
  int _playerCount = 1;
  GameMode _selectedMode = GameMode.strokePlay;
  bool _isStarting = false;

  final List<TextEditingController> _nameControllers = [
    TextEditingController(text: 'Golfer 1 (You)'),
    TextEditingController(text: 'Golfer 2'),
    TextEditingController(text: 'Golfer 3'),
    TextEditingController(text: 'Golfer 4'),
  ];

  final List<String> _teamAssignments = [
    'Team A',
    'Team A',
    'Team B',
    'Team B',
  ];

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onPlayerCountChanged(int count) {
    setState(() {
      _playerCount = count;
      // Auto adjust mode if invalid for player count
      if (_playerCount == 1 &&
          (_selectedMode == GameMode.matchPlay ||
              _selectedMode == GameMode.scramble ||
              _selectedMode == GameMode.fourBall)) {
        _selectedMode = GameMode.strokePlay;
      }
      if (_playerCount != 2 && _selectedMode == GameMode.matchPlay) {
        _selectedMode = GameMode.strokePlay;
      }
      if (_playerCount != 4 && _selectedMode == GameMode.fourBall) {
        _selectedMode = GameMode.strokePlay;
      }
    });
  }

  Future<void> _startRound() async {
    setState(() {
      _isStarting = true;
    });

    final players = <Map<String, dynamic>>[];
    final isTeamMode = _selectedMode == GameMode.scramble || _selectedMode == GameMode.fourBall;

    for (int i = 0; i < _playerCount; i++) {
      players.add({
        'playerName': _nameControllers[i].text.trim().isEmpty
            ? 'Player ${i + 1}'
            : _nameControllers[i].text.trim(),
        'playerOrder': i + 1,
        if (isTeamMode) 'teamId': _teamAssignments[i],
      });
    }

    try {
      // 1. Create round via API
      final round = await widget.apiClient.createRound(
        courseId: widget.bundle.course.id,
        gameMode: _selectedMode,
        players: players,
      );

      // 2. Start round
      final startedRound = await widget.apiClient.startRound(round.id);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ScoreEntryScreen(
              round: startedRound,
              bundle: widget.bundle,
              apiClient: widget.apiClient,
              storage: widget.storage,
              locationService: widget.locationService,
            ),
          ),
        );
      }
    } catch (e) {
      // Offline fallback: create local in-memory round
      final localPlayers = <RoundPlayerModel>[];
      for (int i = 0; i < _playerCount; i++) {
        localPlayers.add(RoundPlayerModel(
          id: 'local-p-${i + 1}',
          roundId: 'local-round-${DateTime.now().millisecondsSinceEpoch}',
          playerName: _nameControllers[i].text.trim().isEmpty
              ? 'Player ${i + 1}'
              : _nameControllers[i].text.trim(),
          playerOrder: i + 1,
          teamId: isTeamMode ? _teamAssignments[i] : null,
        ));
      }

      final localRound = RoundModel(
        id: 'local-round-${DateTime.now().millisecondsSinceEpoch}',
        courseId: widget.bundle.course.id,
        gameMode: _selectedMode,
        status: RoundStatus.inProgress,
        currentHole: 1,
        startedAt: DateTime.now(),
        players: localPlayers,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Starting round in offline mode'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ScoreEntryScreen(
              round: localRound,
              bundle: widget.bundle,
              apiClient: widget.apiClient,
              storage: widget.storage,
              locationService: widget.locationService,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('ROUND SETUP'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Info Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.golf_course, color: AppTheme.primaryGreen, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.bundle.course.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${widget.bundle.holes.length} Holes  •  Par ${widget.bundle.holes.fold<int>(0, (s, h) => s + h.par)}',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Number of Players Selector (1 to 4)
            const Text(
              'NUMBER OF PLAYERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [1, 2, 3, 4].map((count) {
                final isSelected = _playerCount == count;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          '$count ${count == 1 ? "Player" : "Players"}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryGreen,
                      backgroundColor: AppTheme.darkSurface,
                      onSelected: (_) => _onPlayerCountChanged(count),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Players Names & Teams
            const Text(
              'FLIGHT MEMBERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(_playerCount, (index) {
              final isTeamMode =
                  _selectedMode == GameMode.scramble || _selectedMode == GameMode.fourBall;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.surfaceElevated,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _nameControllers[index],
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'Player Name',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                      ),
                    ),
                    if (isTeamMode) ...[
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _teamAssignments[index],
                        dropdownColor: AppTheme.darkSurface,
                        style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold),
                        underline: const SizedBox(),
                        items: ['Team A', 'Team B'].map((team) {
                          return DropdownMenuItem(value: team, child: Text(team));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _teamAssignments[index] = val;
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // Game Mode Selection
            const Text(
              'GAME MODE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            ...GameMode.values.map((mode) {
              final isSelected = _selectedMode == mode;
              bool isAllowed = true;
              if (mode == GameMode.matchPlay && _playerCount != 2) isAllowed = false;
              if (mode == GameMode.fourBall && _playerCount != 4) isAllowed = false;
              if (mode == GameMode.scramble && _playerCount < 2) isAllowed = false;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isSelected ? AppTheme.primaryGreen.withValues(alpha: 0.15) : AppTheme.darkSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryGreen : Colors.white12,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    enabled: isAllowed,
                    title: Text(
                      mode.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isAllowed ? Colors.white : Colors.white30,
                      ),
                    ),
                    subtitle: Text(
                      mode.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: isAllowed ? AppTheme.textMuted : Colors.white24,
                      ),
                    ),
                    trailing: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? AppTheme.primaryGreen : Colors.white24,
                      size: 22,
                    ),
                    onTap: isAllowed ? () => setState(() => _selectedMode = mode) : null,
                  ),
                ),
              );
            }),
            const SizedBox(height: 30),
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
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isStarting ? null : _startRound,
              icon: _isStarting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.play_arrow_rounded, color: Colors.black),
              label: Text(
                _isStarting ? 'STARTING...' : 'START ROUND',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
