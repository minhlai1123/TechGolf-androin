import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/handicap_models.dart';

class HandicapHistoryScreen extends StatefulWidget {
  final ApiClient? apiClient;

  const HandicapHistoryScreen({
    super.key,
    this.apiClient,
  });

  @override
  State<HandicapHistoryScreen> createState() => _HandicapHistoryScreenState();
}

class _HandicapHistoryScreenState extends State<HandicapHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final ApiClient _api;
  late final TabController _tabController;

  bool _isLoading = true;
  bool _isRecalculating = false;
  String? _errorMessage;

  HandicapCurrentModel? _currentHandicap;
  List<ScoreDifferentialModel> _differentials = [];
  List<HandicapHistoryModel> _history = [];

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? ApiClient();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final current = await _api.getCurrentHandicap();
      final diffs = await _api.getScoreDifferentials();
      final hist = await _api.getHandicapHistory();

      if (mounted) {
        setState(() {
          _currentHandicap = current;
          _differentials = diffs;
          _history = hist;
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

  Future<void> _recalculateHandicap() async {
    setState(() {
      _isRecalculating = true;
    });

    try {
      await _api.recalculateHandicap();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Handicap Index recalculated successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to recalculate: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecalculating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WHS Handicap Index'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Differentials'),
            Tab(text: 'Audit History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppTheme.primaryRed),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                          child: const Text('Retry', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    _buildHeaderCard(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDifferentialsTab(),
                          _buildHistoryTab(),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isRecalculating ? null : _recalculateHandicap,
        backgroundColor: AppTheme.primaryGreen,
        icon: _isRecalculating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              )
            : const Icon(Icons.calculate, color: Colors.black),
        label: Text(
          _isRecalculating ? 'Calculating...' : 'Recalculate WHS',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final hcp = _currentHandicap;
    if (hcp == null) return const SizedBox.shrink();

    final isEstablished = hcp.isEstablished;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEstablished ? AppTheme.primaryGreen : AppTheme.accentOrange,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isEstablished
                  ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                  : AppTheme.accentOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'INDEX',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEstablished ? hcp.handicapIndex.toStringAsFixed(1) : '---',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isEstablished ? AppTheme.primaryGreen : AppTheme.accentOrange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isEstablished
                            ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                            : AppTheme.accentOrange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isEstablished ? 'ESTABLISHED' : 'UNESTABLISHED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isEstablished ? AppTheme.primaryGreen : AppTheme.accentOrange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${hcp.roundsCount} eligible rounds',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  hcp.message,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifferentialsTab() {
    if (_differentials.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No completed rounds with score differentials yet.\nPlay and complete rounds to record differentials.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _differentials.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final d = _differentials[index];
        return Card(
          color: AppTheme.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        d.courseName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Diff: ${d.scoreDifferential.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                if (d.teeName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tee: ${d.teeName}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.goldAccent),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('Gross', '${d.grossScore}'),
                    _buildStatItem('AGS (Net DB)', '${d.adjustedGrossScore}'),
                    _buildStatItem('CR', d.courseRating.toStringAsFixed(1)),
                    _buildStatItem('Slope', '${d.slopeRating}'),
                    _buildStatItem('PCC', d.pccAdjustment.toStringAsFixed(1)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No calculation history logs found.',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _history.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final h = _history[index];
        return Card(
          color: AppTheme.darkSurface,
          child: ListTile(
            title: Text(
              'Handicap Index: ${h.resultingHandicapIndex.toStringAsFixed(1)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            subtitle: Text(
              'Rounds: ${h.roundsCount ?? 0} | Used: ${h.differentialsUsedCount ?? 0} diffs\nDate: ${h.calculatedAt.toLocal().toString().split('.')[0]}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                h.status ?? 'VALID',
                style: const TextStyle(fontSize: 11, color: AppTheme.goldAccent),
              ),
            ),
          ),
        );
      },
    );
  }
}
