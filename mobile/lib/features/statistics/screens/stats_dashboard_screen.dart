import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../handicap/models/handicap_models.dart';
import '../../handicap/screens/handicap_history_screen.dart';
import '../models/statistics_models.dart';
import '../../strokes_gained/models/strokes_gained_models.dart';

class StatsDashboardScreen extends StatefulWidget {
  final ApiClient? apiClient;

  const StatsDashboardScreen({
    super.key,
    this.apiClient,
  });

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  late final ApiClient _api;

  int? _selectedRoundsLimit = 10; // null = all rounds
  bool _isLoading = true;
  String? _errorMessage;

  HandicapCurrentModel? _handicap;
  StatsOverviewModel? _overview;
  List<TrendPointModel> _trends = [];
  StrokesGainedSummaryModel? _strokesGained;

  final List<Map<String, dynamic>> _periodOptions = [
    {'label': 'Last 5', 'limit': 5},
    {'label': 'Last 10', 'limit': 10},
    {'label': 'Last 20', 'limit': 20},
    {'label': 'All', 'limit': null},
  ];

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? ApiClient();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hcpFuture = _api.getCurrentHandicap();
      final overviewFuture = _api.getStatsOverview(limit: _selectedRoundsLimit);
      final trendsFuture = _api.getStatsTrends(limit: _selectedRoundsLimit);
      final sgFuture = _api.getStrokesGained();

      final results = await Future.wait([
        hcpFuture,
        overviewFuture,
        trendsFuture,
        sgFuture,
      ]);

      if (mounted) {
        setState(() {
          _handicap = results[0] as HandicapCurrentModel;
          _overview = results[1] as StatsOverviewModel;
          _trends = results[2] as List<TrendPointModel>;
          _strokesGained = results[3] as StrokesGainedSummaryModel;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Golf Performance & Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchStats,
          ),
        ],
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
                          onPressed: _fetchStats,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                          child: const Text('Retry', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchStats,
                  color: AppTheme.primaryGreen,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildPeriodSelector(),
                      const SizedBox(height: 16),
                      _buildHandicapCard(),
                      const SizedBox(height: 16),
                      _buildScoringBanner(),
                      const SizedBox(height: 16),
                      _buildCoreStatsGrid(),
                      const SizedBox(height: 16),
                      _buildParBreakdownCard(),
                      const SizedBox(height: 16),
                      _buildScoreDistributionCard(),
                      const SizedBox(height: 16),
                      _buildTrendsSection(),
                      const SizedBox(height: 16),
                      _buildStrokesGainedSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: _periodOptions.map((opt) {
        final isSelected = _selectedRoundsLimit == opt['limit'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Center(
                child: Text(
                  opt['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.black : Colors.white70,
                  ),
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.primaryGreen,
              backgroundColor: AppTheme.darkSurface,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedRoundsLimit = opt['limit'] as int?;
                  });
                  _fetchStats();
                }
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHandicapCard() {
    final hcp = _handicap;
    if (hcp == null) return const SizedBox.shrink();

    final isEstablished = hcp.isEstablished;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HandicapHistoryScreen(apiClient: _api),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WHS HANDICAP INDEX',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      isEstablished ? hcp.handicapIndex.toStringAsFixed(1) : '---',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: isEstablished ? AppTheme.primaryGreen : AppTheme.accentOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isEstablished
                            ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                            : AppTheme.accentOrange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isEstablished ? 'ESTABLISHED' : 'NEEDS 3 ROUNDS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isEstablished ? AppTheme.primaryGreen : AppTheme.accentOrange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isEstablished
                      ? '${hcp.roundsCount} eligible rounds recorded'
                      : '${hcp.roundsCount}/3 rounds completed to establish',
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildScoringBanner() {
    final ov = _overview;
    if (ov == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _buildBannerMetric(
            'Scoring Average',
            ov.scoringAverage != null ? ov.scoringAverage!.toStringAsFixed(1) : '---',
            '${ov.roundsPlayed} rounds played',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBannerMetric(
            'Best Score',
            ov.bestScore != null ? '${ov.bestScore}' : '---',
            '18 holes gross',
          ),
        ),
      ],
    );
  }

  Widget _buildBannerMetric(String label, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildCoreStatsGrid() {
    final ov = _overview;
    if (ov == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildFirCard(ov.fir)),
            const SizedBox(width: 12),
            Expanded(child: _buildGirCard(ov.gir)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPuttsCard(ov.putts)),
            const SizedBox(width: 12),
            Expanded(child: _buildScramblingCard(ov.scrambling)),
          ],
        ),
      ],
    );
  }

  Widget _buildFirCard(FirModel fir) {
    return _buildMetricCard(
      title: 'Fairways (FIR)',
      value: fir.percentage != null ? '${fir.percentage!.toStringAsFixed(1)}%' : '---',
      subtitle: '${fir.hitCount} of ${fir.totalOpportunities} hit',
      badgeText: 'Par 3s excluded',
      details: 'Miss: L ${fir.missLeftCount} | R ${fir.missRightCount}',
    );
  }

  Widget _buildGirCard(GirModel gir) {
    return _buildMetricCard(
      title: 'Greens (GIR)',
      value: gir.percentage != null ? '${gir.percentage!.toStringAsFixed(1)}%' : '---',
      subtitle: '${gir.hitCount} of ${gir.totalOpportunities} hit',
      badgeText: 'Regulation',
      details: 'Missed: ${gir.missCount}',
    );
  }

  Widget _buildPuttsCard(PuttsModel putts) {
    return _buildMetricCard(
      title: 'Putting',
      value: putts.puttsPerHole != null ? putts.puttsPerHole!.toStringAsFixed(2) : '---',
      subtitle: 'per hole avg (${putts.totalPutts} tot)',
      badgeText: putts.puttsPerGir != null ? '${putts.puttsPerGir!.toStringAsFixed(2)} GIR' : 'Putts',
      details: '1P: ${putts.onePuttsCount} | 2P: ${putts.twoPuttsCount} | 3P+: ${putts.threeOrMorePuttsCount}',
    );
  }

  Widget _buildScramblingCard(ScramblingModel scram) {
    final hasOpp = scram.hasOpportunities;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Scrambling',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hasOpp ? AppTheme.primaryGreen.withValues(alpha: 0.15) : Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hasOpp ? 'Up & Down' : 'No opportunities',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: hasOpp ? AppTheme.primaryGreen : AppTheme.goldAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasOpp ? '${scram.percentage!.toStringAsFixed(1)}%' : '---',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: hasOpp ? Colors.white : Colors.white38,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasOpp
                ? '${scram.successCount} of ${scram.opportunitiesCount} saved'
                : 'No missed greens data',
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
          const SizedBox(height: 4),
          Text(
            hasOpp ? 'Par or better after missed green' : 'Requires missed GIR to compute',
            style: const TextStyle(fontSize: 10, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required String badgeText,
    required String details,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white60)),
          const SizedBox(height: 4),
          Text(details, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildParBreakdownCard() {
    final pb = _overview?.parBreakdown;
    if (pb == null) return const SizedBox.shrink();

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
            'Scoring by Par',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildParStat('Par 3s', pb.par3Average != null ? pb.par3Average!.toStringAsFixed(2) : '---'),
              _buildParStat('Par 4s', pb.par4Average != null ? pb.par4Average!.toStringAsFixed(2) : '---'),
              _buildParStat('Par 5s', pb.par5Average != null ? pb.par5Average!.toStringAsFixed(2) : '---'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
        ),
      ],
    );
  }

  Widget _buildScoreDistributionCard() {
    final dist = _overview?.scoreDistribution;
    if (dist == null) return const SizedBox.shrink();

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
            'Score Distribution',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDistItem('Eagles', dist.eaglesOrBetter, AppTheme.goldAccent),
              _buildDistItem('Birdies', dist.birdies, AppTheme.primaryGreen),
              _buildDistItem('Pars', dist.pars, Colors.white),
              _buildDistItem('Bogeys', dist.bogeys, AppTheme.accentOrange),
              _buildDistItem('Double+', dist.doubleBogeys + dist.tripleOrWorse, AppTheme.primaryRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildTrendsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Trends',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        if (_trends.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No round trends available yet. Complete rounds to see performance trends.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          )
        else
          ..._trends.map((t) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.courseName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.roundDate.toLocal().toString().split(' ')[0],
                            style: const TextStyle(fontSize: 11, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Score: ${t.grossScore}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          if (t.scoreDifferential != null)
                            Text(
                              'Diff: ${t.scoreDifferential!.toStringAsFixed(1)}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'FIR: ${t.firPercentage != null ? "${t.firPercentage!.toStringAsFixed(0)}%" : "--"}',
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                          Text(
                            'GIR: ${t.girPercentage != null ? "${t.girPercentage!.toStringAsFixed(0)}%" : "--"}',
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildStrokesGainedSection() {
    final sg = _strokesGained;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: AppTheme.goldAccent, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Strokes Gained Framework',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppTheme.goldAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sg?.message ??
                        'Strokes Gained data unavailable: Benchmark reference table (PGA Tour / Mark Broadie) is not supplied in specification. Data cannot be faked with 0.00.',
                    style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Shot Categorization Distribution:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 8),
          _buildSgCategoryRow('Driving (Off-the-Tee)', sg?.categories['DRIVING']),
          _buildSgCategoryRow('Approach-the-Green', sg?.categories['APPROACH']),
          _buildSgCategoryRow('Around-the-Green (Short Game)', sg?.categories['SHORT_GAME']),
          _buildSgCategoryRow('Putting', sg?.categories['PUTTING']),
        ],
      ),
    );
  }

  Widget _buildSgCategoryRow(String label, StrokesGainedCategoryModel? cat) {
    final count = cat?.shotsCount ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          Row(
            children: [
              Text(
                '$count shots',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Unavailable',
                  style: TextStyle(fontSize: 10, color: AppTheme.goldAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
