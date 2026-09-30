import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../game_modes/game_mode_engine.dart';
import '../models/liveplay_models.dart';
import '../services/liveplay_socket_client.dart';

class LivePlayScreen extends StatefulWidget {
  final String roundId;
  final ApiClient apiClient;
  final ILivePlaySocketClient? socketClient;

  const LivePlayScreen({
    super.key,
    required this.roundId,
    required this.apiClient,
    this.socketClient,
  });

  @override
  State<LivePlayScreen> createState() => _LivePlayScreenState();
}

class _LivePlayScreenState extends State<LivePlayScreen> {
  late final ILivePlaySocketClient _socket;
  StreamSubscription<LivePlayConnectionStatus>? _statusSub;
  StreamSubscription<Map<String, dynamic>>? _eventSub;

  bool _isLoading = true;
  String? _errorMessage;
  LivePlayStateModel? _liveState;
  LivePlayConnectionStatus _connectionStatus = LivePlayConnectionStatus.connecting;

  @override
  void initState() {
    super.initState();
    _socket = widget.socketClient ?? LivePlaySocketClient();
    _initLivePlay();
  }

  Future<void> _initLivePlay() async {
    // 1. Subscribe to socket status & events
    _statusSub = _socket.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _connectionStatus = status;
        });
      }
    });

    _eventSub = _socket.eventStream.listen(_handleSocketEvent);

    // 2. Load initial REST state
    await _fetchInitialState();

    // 3. Connect socket and join round room
    final wsUrl = widget.apiClient.livePlayWsUrl;
    final token = widget.apiClient.authToken;

    await _socket.connect(wsUrl, token: token);
    await _socket.joinRound(widget.roundId, token: token);
  }

  Future<void> _fetchInitialState() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final state = await widget.apiClient.getLivePlayState(widget.roundId);
      if (mounted) {
        setState(() {
          _liveState = state;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _handleSocketEvent(Map<String, dynamic> msg) {
    final event = msg['event'] as String?;
    final data = msg['data'] as Map<String, dynamic>? ?? {};

    if (event == 'liveplay:joined') {
      if (data['state'] != null && mounted) {
        setState(() {
          _liveState = LivePlayStateModel.fromJson(data['state'] as Map<String, dynamic>);
        });
      }
    } else if (event == 'score:updated') {
      // Re-fetch or update score item
      final scoreJson = data['score'] as Map<String, dynamic>?;
      if (scoreJson != null && mounted) {
        final newScore = LivePlayScore.fromJson(scoreJson);
        setState(() {
          if (_liveState != null) {
            final updatedScores = List<LivePlayScore>.from(_liveState!.scores);
            final idx = updatedScores.indexWhere(
              (s) => s.playerId == newScore.playerId && s.holeId == newScore.holeId,
            );
            if (idx >= 0) {
              updatedScores[idx] = newScore;
            } else {
              updatedScores.add(newScore);
            }
            _liveState = LivePlayStateModel(
              roundId: _liveState!.roundId,
              courseName: _liveState!.courseName,
              gameMode: _liveState!.gameMode,
              roundStatus: _liveState!.roundStatus,
              currentHole: _liveState!.currentHole,
              players: _liveState!.players,
              holes: _liveState!.holes,
              scores: updatedScores,
              playerSummaries: _liveState!.playerSummaries,
              leaderboard: _liveState!.leaderboard,
            );
          }
        });
      }
    } else if (event == 'leaderboard:updated') {
      // Realtime leaderboard standings broadcast
      final rawLb = data['leaderboard'] as Map<String, dynamic>? ?? {};
      final rawSummaries = (data['playerSummaries'] as List<dynamic>? ?? [])
          .map((s) => LivePlayPlayerSummary.fromJson(s as Map<String, dynamic>))
          .toList();
      final currentHole = data['currentHole'] as int? ?? _liveState?.currentHole ?? 1;

      if (mounted && _liveState != null) {
        setState(() {
          _liveState = LivePlayStateModel(
            roundId: _liveState!.roundId,
            courseName: _liveState!.courseName,
            gameMode: _liveState!.gameMode,
            roundStatus: _liveState!.roundStatus,
            currentHole: currentHole,
            players: _liveState!.players,
            holes: _liveState!.holes,
            scores: _liveState!.scores,
            playerSummaries: rawSummaries.isNotEmpty ? rawSummaries : _liveState!.playerSummaries,
            leaderboard: rawLb,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leaderboard updated in real-time!'),
            duration: Duration(seconds: 1),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } else if (event == 'player:joined') {
      final playerName = data['playerName'] as String? ?? 'A player';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$playerName joined LivePlay'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppTheme.darkSurface,
          ),
        );
      }
    } else if (event == 'liveplay:error') {
      final message = data['message'] as String? ?? 'LivePlay error';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _eventSub?.cancel();
    _socket.leaveRound(widget.roundId);
    _socket.dispose();
    super.dispose();
  }

  void _manualReconnect() {
    final wsUrl = widget.apiClient.livePlayWsUrl;
    final token = widget.apiClient.authToken;
    _socket.connect(wsUrl, token: token);
    _socket.joinRound(widget.roundId, token: token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('LIVEPLAY'),
            const SizedBox(width: 8),
            _buildConnectionBadge(),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh State',
            onPressed: _fetchInitialState,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppTheme.primaryRed),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchInitialState,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                          child: const Text('Retry', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchInitialState,
                  color: AppTheme.primaryGreen,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_connectionStatus != LivePlayConnectionStatus.connected)
                        _buildConnectionBanner(),
                      _buildHeaderCard(),
                      const SizedBox(height: 16),
                      _buildLeaderboardSection(),
                      const SizedBox(height: 16),
                      _buildHoleScoresMatrix(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildConnectionBadge() {
    Color color;
    String label;

    switch (_connectionStatus) {
      case LivePlayConnectionStatus.connected:
        color = AppTheme.primaryGreen;
        label = 'LIVE';
        break;
      case LivePlayConnectionStatus.connecting:
        color = AppTheme.accentOrange;
        label = 'Connecting...';
        break;
      case LivePlayConnectionStatus.reconnecting:
        color = AppTheme.accentOrange;
        label = 'Reconnecting...';
        break;
      case LivePlayConnectionStatus.disconnected:
        color = Colors.grey;
        label = 'Offline';
        break;
      case LivePlayConnectionStatus.error:
        color = AppTheme.primaryRed;
        label = 'Error';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.accentOrange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.accentOrange),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppTheme.accentOrange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _connectionStatus == LivePlayConnectionStatus.reconnecting
                  ? 'Connection lost. Reconnecting to LivePlay...'
                  : 'Disconnected from LivePlay session.',
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: _manualReconnect,
            child: const Text('Reconnect', style: TextStyle(color: AppTheme.accentOrange)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final state = _liveState;
    if (state == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
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
                  state.courseName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Hole ${state.currentHole}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  state.gameMode.displayName,
                  style: const TextStyle(fontSize: 11, color: AppTheme.goldAccent),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${state.players.length} Players connected',
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    final state = _liveState;
    if (state == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.leaderboard, color: AppTheme.primaryGreen, size: 20),
                SizedBox(width: 8),
                Text(
                  'Realtime Leaderboard',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          _buildLeaderboardHeader(),
          const Divider(height: 1, color: Colors.white12),
          ...state.playerSummaries.map((p) => _buildPlayerLeaderboardRow(p)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLeaderboardHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text('POS', style: TextStyle(fontSize: 11, color: Colors.white54))),
          Expanded(child: Text('PLAYER', style: TextStyle(fontSize: 11, color: Colors.white54))),
          SizedBox(width: 48, child: Text('THRU', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white54))),
          SizedBox(width: 48, child: Text('TO PAR', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white54))),
          SizedBox(width: 52, child: Text('GROSS', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: Colors.white54))),
        ],
      ),
    );
  }

  Widget _buildPlayerLeaderboardRow(LivePlayPlayerSummary p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${p.playerOrder}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.goldAccent),
            ),
          ),
          Expanded(
            child: Text(
              p.playerName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              p.thru,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              p.formattedToPar,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: p.toPar < 0
                    ? AppTheme.primaryRed
                    : p.toPar == 0
                        ? Colors.white
                        : AppTheme.primaryGreen,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '${p.grossScore}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoleScoresMatrix() {
    final state = _liveState;
    if (state == null || state.holes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hole Scores (Live Sync)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowHeight: 36,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 44,
              columns: [
                const DataColumn(label: Text('Player', style: TextStyle(color: Colors.white54))),
                ...state.holes.map((h) => DataColumn(
                      label: Text('H${h.holeNumber}', style: const TextStyle(color: Colors.white54)),
                    )),
              ],
              rows: state.players.map((p) {
                return DataRow(
                  cells: [
                    DataCell(Text(p.playerName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                    ...state.holes.map((h) {
                      final score = state.scores.firstWhere(
                        (s) => s.playerId == p.id && s.holeId == h.id,
                        orElse: () => const LivePlayScore(id: '', playerId: '', holeId: '', grossScore: 0),
                      );
                      final val = score.grossScore > 0 ? '${score.grossScore}' : '-';
                      return DataCell(
                        Center(
                          child: Text(
                            val,
                            style: TextStyle(
                              fontWeight: score.grossScore > 0 ? FontWeight.bold : FontWeight.normal,
                              color: score.grossScore > 0 ? AppTheme.primaryGreen : Colors.white30,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
