import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../auth/domain/app_user.dart';

class GrowthAnalyticsDashboard extends StatefulWidget {
  const GrowthAnalyticsDashboard({super.key});

  @override
  State<GrowthAnalyticsDashboard> createState() => _GrowthAnalyticsDashboardState();
}

class _GrowthAnalyticsDashboardState extends State<GrowthAnalyticsDashboard> {
  bool _isLoading = true;
  String? _error;

  int _totalUsers = 0;
  double _d1Retention = 0.0;
  double _d7Retention = 0.0;
  double _d30Retention = 0.0;

  double _avgMoodLogs = 0.0;
  double _avgJournals = 0.0;
  double _avgEmergencyClicks = 0.0;
  double _avgLetters = 0.0;

  List<AppUser> _userList = [];

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Fetch all users
      final usersSnapshot = await firestore.collection('users').get();
      final users = usersSnapshot.docs.map((doc) => AppUser.fromJson(doc.data())).toList();

      if (users.isEmpty) {
        setState(() {
          _totalUsers = 0;
          _isLoading = false;
        });
        return;
      }

      // Sort users by signup date descending
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final now = DateTime.now();

      // 2. Cohort Retention Calculations
      int d1Eligible = 0;
      int d1Retained = 0;

      int d7Eligible = 0;
      int d7Retained = 0;

      int d30Eligible = 0;
      int d30Retained = 0;

      for (var u in users) {
        final daysSinceSignup = now.difference(u.createdAt).inDays;
        final daysActiveAfterSignup = u.lastActiveAt.difference(u.createdAt).inDays;

        if (daysSinceSignup >= 1) {
          d1Eligible++;
          if (daysActiveAfterSignup >= 1) {
            d1Retained++;
          }
        }

        if (daysSinceSignup >= 7) {
          d7Eligible++;
          if (daysActiveAfterSignup >= 7) {
            d7Retained++;
          }
        }

        if (daysSinceSignup >= 30) {
          d30Eligible++;
          if (daysActiveAfterSignup >= 30) {
            d30Retained++;
          }
        }
      }

      final d1Pct = d1Eligible > 0 ? (d1Retained / d1Eligible) * 100 : 0.0;
      final d7Pct = d7Eligible > 0 ? (d7Retained / d7Eligible) * 100 : 0.0;
      final d30Pct = d30Eligible > 0 ? (d30Retained / d30Eligible) * 100 : 0.0;

      // 3. Collection Group Queries for Feature Usage
      final journalsSnap = await firestore.collectionGroup('journals').get();
      final moodsSnap = await firestore.collectionGroup('moods').get();
      final clicksSnap = await firestore.collectionGroup('emergency_clicks').get();
      final lettersSnap = await firestore.collectionGroup('letters').get();

      final userCount = users.length;
      final avgJournals = journalsSnap.docs.length / userCount;
      final avgMoodLogs = moodsSnap.docs.length / userCount;
      final avgClicks = clicksSnap.docs.length / userCount;
      final avgLetters = lettersSnap.docs.length / userCount;

      setState(() {
        _totalUsers = userCount;
        _d1Retention = d1Pct;
        _d7Retention = d7Pct;
        _d30Retention = d30Pct;
        _avgJournals = avgJournals;
        _avgMoodLogs = avgMoodLogs;
        _avgEmergencyClicks = avgClicks;
        _avgLetters = avgLetters;
        _userList = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Growth & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMetrics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Error: $_error', style: TextStyle(color: theme.colorScheme.error)),
                ))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Stats
                      _buildHeaderStatsCard(theme),
                      const SizedBox(height: 16),

                      // Retention Cohorts
                      Text(
                        'Retention Cohorts',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildCohortCard(theme, 'D1 Retention', _d1Retention, Colors.blue)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildCohortCard(theme, 'D7 Retention', _d7Retention, Colors.green)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildCohortCard(theme, 'D30 Retention', _d30Retention, Colors.purple)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Usage Metrics
                      Text(
                        'Average Feature Usage per User',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildUsageRow(theme, 'Mood Check-ins', _avgMoodLogs, 'logs/user'),
                              const Divider(),
                              _buildUsageRow(theme, 'Journal Notes', _avgJournals, 'notes/user'),
                              const Divider(),
                              _buildUsageRow(theme, 'Emergency Button Clicks', _avgEmergencyClicks, 'clicks/user'),
                              const Divider(),
                              _buildUsageRow(theme, 'Unsent Letters Vault', _avgLetters, 'letters/user'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Registered Users
                      Text(
                        'Registered User List (${_userList.length})',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _userList.length,
                        itemBuilder: (context, index) {
                          final u = _userList[index];
                          final regDate = DateFormat.yMMMd().format(u.createdAt);
                          final activeDate = DateFormat.yMMMd().add_jm().format(u.lastActiveAt);
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(u.email),
                              subtitle: Text('Signed Up: $regDate\nLast Active: $activeDate', style: const TextStyle(fontSize: 12)),
                              isThreeLine: true,
                              trailing: Text('Streak\n${u.noContactStreak}d', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderStatsCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.primaryContainer.withAlpha(25),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'TOTAL REGISTERED USERS',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_totalUsers',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCohortCard(ThemeData theme, String title, double value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          children: [
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 48,
                  width: 48,
                  child: CircularProgressIndicator(
                    value: value / 100,
                    strokeWidth: 5,
                    color: color,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageRow(ThemeData theme, String label, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
