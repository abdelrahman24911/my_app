import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';

// MethodChannel for native Android communication
const platform = MethodChannel('com.appguard.native_calls');

// App usage data model
class AppUsageData {
  final String appName;
  final String packageName;
  final int totalTimeInSeconds;

  AppUsageData({
    required this.appName,
    required this.packageName,
    required this.totalTimeInSeconds,
  });

  factory AppUsageData.fromJson(Map<String, dynamic> json) {
    return AppUsageData(
      appName: json['appName'] as String,
      packageName: json['packageName'] as String,
      totalTimeInSeconds: json['totalTimeInSeconds'] as int,
    );
  }
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _hasPermission = false;
  bool _isLoading = false;
  List<AppUsageData> usageData = [];
  int totalScreenTime = 0;
  String _selectedTimePeriod = 'daily'; // 'daily', 'weekly', 'monthly'

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final hasPermission = await platform.invokeMethod('hasUsagePermission');
      setState(() {
        _hasPermission = hasPermission;
      });
      if (hasPermission) {
        _loadUsageStats();
      }
    } on PlatformException catch (e) {
      debugPrint("Permission check failed: ${e.message}");
      setState(() {
        _hasPermission = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await platform.invokeMethod('requestUsagePermission');
      _showPermissionDialog();
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      _showPermissionDialog();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsageStats() async {
    try {
      String methodName;
      switch (_selectedTimePeriod) {
        case 'weekly':
          methodName = 'getWeeklyUsageStats';
          break;
        case 'monthly':
          methodName = 'getMonthlyUsageStats';
          break;
        case '3months':
          methodName = 'get3MonthsUsageStats';
          break;
        case '6months':
          methodName = 'get6MonthsUsageStats';
          break;
        case '1year':
          methodName = 'get1YearUsageStats';
          break;
        default:
          methodName = 'getUsageStats';
      }
      
      final List<dynamic> rawData = await platform.invokeMethod(methodName);
      final List<AppUsageData> loadedData = rawData
          .map((item) => AppUsageData.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      if (mounted) {
        setState(() {
          usageData = loadedData.where((d) => d.totalTimeInSeconds > 0).toList()
            ..sort((a, b) => b.totalTimeInSeconds.compareTo(a.totalTimeInSeconds));
          totalScreenTime = loadedData.fold(0, (sum, item) => sum + item.totalTimeInSeconds);
        });
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to load usage stats: ${e.message}");
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: Text(
            'Enable Usage Access',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To view real screen time data, please:',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '1. Tap "Open Settings" below',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '2. Look for "my_app" in the list',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '3. If you don\'t see "my_app", scroll down or search',
                style: GoogleFonts.inter(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '4. Toggle "Permit usage access" ON',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '5. Return to the app',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openUsageStatsSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Open Settings',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openUsageStatsSettings() {
    // This will open the usage stats settings page
    // The native Android code should handle this
    platform.invokeMethod('requestUsagePermission');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        elevation: 0,
        title: Text(
          'Screen Time Analytics',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await _loadUsageStats();
              setState(() {
                _isLoading = false;
              });
            },
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
            tooltip: 'Refresh Data',
          ),
        ],
        leading: IconButton(
          icon: const Icon(
            LucideIcons.barChart3,
            color: Color(0xFF7C3AED),
            size: 28,
          ),
          onPressed: () {},
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Time Period Selector
            _buildTimePeriodSelector(),
            const SizedBox(height: 20),
            
            // Debug Info (only show if no permission or data issues)
            if (!_hasPermission || usageData.isEmpty) ...[
              _buildDebugInfo(),
              const SizedBox(height: 20),
            ],
            
            // Permission Request Section
            if (!_hasPermission) ...[
              _buildPermissionRequestCard(),
              const SizedBox(height: 20),
            ],
            
            // Overview Cards
            _buildOverviewCards(),
            const SizedBox(height: 20),
            
            // Focus Score
            _buildFocusScoreCard(),
            const SizedBox(height: 20),
            
            // Usage Chart
            _buildUsageChart(),
            const SizedBox(height: 20),
            
            // Category Breakdown
            _buildCategoryBreakdown(),
            const SizedBox(height: 20),
            
            // Top Apps
            _buildTopApps(),
            const SizedBox(height: 20),
            
            // App Usage Visualization
            _buildAppUsageVisualization(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF2A2A2A),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Period',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTimePeriodButton('Daily', 'daily', LucideIcons.calendar),
                const SizedBox(width: 8),
                _buildTimePeriodButton('Weekly', 'weekly', LucideIcons.calendarDays),
                const SizedBox(width: 8),
                _buildTimePeriodButton('Monthly', 'monthly', LucideIcons.calendarRange),
                const SizedBox(width: 8),
                _buildTimePeriodButton('3 Months', '3months', LucideIcons.calendar),
                const SizedBox(width: 8),
                _buildTimePeriodButton('6 Months', '6months', LucideIcons.calendar),
                const SizedBox(width: 8),
                _buildTimePeriodButton('1 Year', '1year', LucideIcons.calendar),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePeriodButton(String label, String value, IconData icon) {
    final isSelected = _selectedTimePeriod == value;
    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedTimePeriod = value;
        });
        await _loadUsageStats();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF3A3A3A),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF4A4A4A),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.info, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Usage Data Debug Info',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Permission Status: ${_hasPermission ? "Granted" : "Not Granted"}',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
          ),
          Text(
            'Data Count: ${usageData.length} apps',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
          ),
          Text(
            'Total Time: ${_formatTime(totalScreenTime)}',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              try {
                final result = await platform.invokeMethod('validateUsageData');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Validation: ${result.toString()}'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Validation failed: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(double.infinity, 32),
            ),
            child: Text(
              'Validate Data Accuracy',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequestCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withOpacity(0.2),
            Colors.orange.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: Colors.orange.withOpacity(0.2),
                ),
                child: const Icon(
                  LucideIcons.shield,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enable Usage Access',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'To view real screen time data, please enable usage access permission.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _requestPermission,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(LucideIcons.shield),
                  label: Text(
                    _isLoading ? 'Requesting...' : 'Enable Usage Access',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    String timeLabel;
    switch (_selectedTimePeriod) {
      case 'weekly':
        timeLabel = 'This Week';
        break;
      case 'monthly':
        timeLabel = 'This Month';
        break;
      case '3months':
        timeLabel = 'Last 3 Months';
        break;
      case '6months':
        timeLabel = 'Last 6 Months';
        break;
      case '1year':
        timeLabel = 'Last Year';
        break;
      default:
        timeLabel = 'Today';
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: timeLabel,
            value: _formatTime(totalScreenTime),
            icon: LucideIcons.clock,
            color: const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Apps Used',
            value: '${usageData.length}',
            icon: LucideIcons.smartphone,
            color: const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: color.withOpacity(0.2),
            ),
            child: Icon(
              icon,
              color: color,
              size: 25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusScoreCard() {
    final focusScore = _calculateFocusScore();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.target, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Focus Score',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: focusScore / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(focusScore),
                      ),
                    ),
                    Center(
                      child: Text(
                        '$focusScore',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _getScoreMessage(focusScore),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              const Icon(LucideIcons.barChart3, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Weekly Usage Trend',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
              child: LineChart(
                LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Text(
                          days[value.toInt() % 7],
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}h',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                    spots: _generateWeeklyData(),
                      isCurved: true,
                    color: const Color(0xFF7C3AED),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF7C3AED),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.pieChart, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Category Breakdown',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
            ),
            const SizedBox(height: 16),
          ...usageData.take(5).map((app) {
            final percentage = totalScreenTime > 0
                ? ((app.totalTimeInSeconds / totalScreenTime) * 100).round()
                : 0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: _getAppColor(app.appName),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      app.appName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '${percentage}%',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopApps() {
    final topApps = _getTopApps();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.smartphone, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Most Used Apps',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topApps.map((app) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF7C3AED).withOpacity(0.2),
                  ),
                  child: const Icon(
                    LucideIcons.smartphone,
                    color: Color(0xFF7C3AED),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app['name'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        app['time'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Block app functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Block ${app['name']} functionality coming soon!'),
                        backgroundColor: const Color(0xFF7C3AED),
                      ),
                    );
                  },
                  icon: const Icon(
                    LucideIcons.shield,
                    color: Colors.orange,
                    size: 16,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAppUsageVisualization() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.pieChart, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'App Usage Distribution',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Circular chart
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: usageData.isEmpty
                      ? const CircularProgressIndicator(value: 1.0, color: Colors.grey)
                      : CustomPaint(
                          painter: CircularChartPainter(usageData, totalScreenTime),
                        ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Total', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      _formatTime(totalScreenTime),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds < 60) return '$totalSeconds secs';
    final int minutes = totalSeconds ~/ 60;
    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '${hours} hr ${remainingMinutes} mins';
    } else if (minutes > 0) {
      return '${minutes} mins';
    } else {
      return '$totalSeconds secs';
    }
  }

  int _calculateFocusScore() {
    if (usageData.isEmpty) return 0;
    
    // Simple focus score calculation based on app diversity and total time
    final productiveApps = usageData.where((app) => 
      app.appName.toLowerCase().contains('chrome') ||
      app.appName.toLowerCase().contains('notes') ||
      app.appName.toLowerCase().contains('calendar') ||
      app.appName.toLowerCase().contains('email')
    ).length;
    
    final totalApps = usageData.length;
    final productiveRatio = totalApps > 0 ? productiveApps / totalApps : 0;
    
    // Base score from productive ratio, adjusted by total time
    final baseScore = (productiveRatio * 100).round();
    final timeAdjustment = totalScreenTime > 3600 ? -10 : 0; // Penalty for excessive usage
    
    return (baseScore + timeAdjustment).clamp(0, 100);
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFFFFC107);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _getScoreMessage(int score) {
    if (score >= 80) return 'Excellent focus! Keep it up!';
    if (score >= 60) return 'Good focus, room for improvement';
    if (score >= 40) return 'Moderate focus, try to reduce distractions';
    return 'Low focus, consider blocking more apps';
  }

  Color _getAppColor(String appName) {
    if (appName.contains('Instagram')) return Colors.blueAccent;
    if (appName.contains('YouTube')) return Colors.red;
    if (appName.contains('Chrome')) return Colors.orange;
    if (appName.contains('Discord')) return Colors.purple;
    if (appName.contains('Spotify')) return Colors.green;
    return Colors.teal;
  }

  List<FlSpot> _generateWeeklyData() {
    // Generate sample data for the week based on current usage
    return List.generate(7, (index) {
      final baseHours = (totalScreenTime / 3600) / 7; // Distribute current usage across week
      final randomVariation = (index % 3 - 1) * 0.5;
      return FlSpot(index.toDouble(), (baseHours + randomVariation).clamp(0.0, 12.0));
    });
  }

  List<Map<String, dynamic>> _getTopApps() {
    return usageData.take(5).map((app) => {
          'name': app.appName,
          'packageName': app.packageName,
          'time': _formatTime(app.totalTimeInSeconds),
        }).toList();
  }
}

// Circular chart painter for screen time visualization
class CircularChartPainter extends CustomPainter {
  final List<AppUsageData> usageData;
  final int totalTime;
  final List<Color> colors = [
    Colors.blueAccent,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink
  ];

  CircularChartPainter(this.usageData, this.totalTime);

  @override
  void paint(Canvas canvas, Size size) {
    if (totalTime == 0) return;

    double startAngle = -pi / 2;
    const double sweepAngle = 2 * pi;
    const double strokeWidth = 20.0;

    final Paint backgroundPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, backgroundPaint);

    final List<AppUsageData> sortedData = usageData.where((d) => d.totalTimeInSeconds > 0).toList()
      ..sort((a, b) => b.totalTimeInSeconds.compareTo(a.totalTimeInSeconds));

    for (int i = 0; i < sortedData.take(5).length; i++) {
      final data = sortedData[i];
      final double fraction = data.totalTimeInSeconds / totalTime;
      final double segmentAngle = sweepAngle * fraction;

      final Paint segmentPaint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2),
        startAngle,
        segmentAngle,
        false,
        segmentPaint,
      );

      startAngle += segmentAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}


