import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/date_utils.dart' as date_utils;

enum ChartMode {
  week, // 7 data points (M, T, W, T, F, S, S)
  twelveWeeks, // 12 data points (weekly aggregates)
}

/// Line chart that displays either weekly (7 days) or 12-week data
/// For week mode: data represents Monday (idx 0) to Sunday (idx 6)
/// For twelveWeeks mode: data represents 12 weeks of aggregated data
class WeeklyLineChart extends StatefulWidget {
  final List<double> data;
  final String unitLabel; // "km" or "mi"
  final bool showAvgToggle;
  final ChartMode mode;
  final List<String>?
      xAxisLabels; // Custom labels for x-axis (for 12-week mode)
  final Function(int)?
      onWeekTap; // Callback when a week is tapped (12-week mode only)
  final int?
      selectedWeekIndex; // Index of selected week to highlight (12-week mode only)
  final Function(int)?
      onDayTap; // Callback when a day is tapped (week mode only)
  final int?
      selectedDayIndex; // Index of selected day to highlight (week mode only)

  const WeeklyLineChart({
    super.key,
    required this.data,
    this.unitLabel = 'km',
    this.showAvgToggle = false,
    this.mode = ChartMode.week,
    this.xAxisLabels,
    this.onWeekTap,
    this.selectedWeekIndex,
    this.onDayTap,
    this.selectedDayIndex,
  });

  @override
  State<WeeklyLineChart> createState() => _WeeklyLineChartState();
}

class _WeeklyLineChartState extends State<WeeklyLineChart> {
  // Updated colors to match your app's theme
  late final List<Color> gradientColors = [
    const Color.fromRGBO(255, 87, 87, 1.0),
    const Color.fromRGBO(140, 82, 255, 1.0),
  ];

  bool showAvg = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AspectRatio(
          aspectRatio: 2.0, // More space for breathing
          child: Padding(
            padding: const EdgeInsets.only(
              right: 8,
              left: 8,
              top: 16,
              bottom: 8,
            ),
            child: LineChart(
              showAvg ? _avgData() : _mainData(),
            ),
          ),
        ),
        if (widget.showAvgToggle)
          SizedBox(
            width: 60,
            height: 34,
            child: TextButton(
              onPressed: () => setState(() => showAvg = !showAvg),
              child: Text(
                'avg',
                style: TextStyle(
                  fontSize: 12,
                  color: showAvg ? Colors.white.withOpacity(0.5) : Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---- Títulos de ejes ----

  Widget _bottomTitle(double value, TitleMeta meta) {
    final style = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: widget.mode == ChartMode.week ? 10 : 9,
      color: Colors.black.withOpacity(0.6),
    );
    final i = value.toInt();

    String text;
    if (widget.mode == ChartMode.twelveWeeks) {
      // Use custom labels for 12-week mode (month abbreviations)
      if (widget.xAxisLabels != null &&
          i >= 0 &&
          i < widget.xAxisLabels!.length) {
        text = widget.xAxisLabels![i];
      } else {
        text = '';
      }
    } else {
      // Use day labels for week mode
      text = (i >= 0 && i < 7) ? date_utils.dayNamesShort[i] : '';
    }

    return SideTitleWidget(
      meta: meta,
      child: Text(text, style: style),
    );
  }

  Widget _leftTitle(double value, TitleMeta meta) {
    // Don't show labels if no data
    if (widget.data.every((d) => d == 0)) {
      return const SizedBox.shrink();
    }

    // Only show labels within valid range
    if (value > _maxY || value < 0) {
      return const SizedBox.shrink();
    }

    final style = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 9,
      color: Colors.black.withOpacity(0.5),
    );
    // Round to nearest integer for clean display
    return Text(value.round().toString(), style: style);
  }

  // ---- Datos / ejes dinámicos ----

  List<FlSpot> get _spots => List.generate(
        widget.data.length,
        (i) => FlSpot(i.toDouble(), widget.data[i]),
      );

  double get _maxX => (widget.data.length - 1).toDouble();

  double get _maxY {
    final m = widget.data.fold<double>(0, (a, b) => b > a ? b : a);

    // Si no hay datos, retornar 1.0
    if (m == 0) return 1.0;

    // Para valores muy pequeños (< 1), usar mínimo de 1.0
    if (m < 1.0) {
      return 1.0;
    }

    // Redondear hacia arriba al entero más cercano (sin margen extra)
    return m.ceilToDouble();
  }

  // ---- Config principal ----

  LineChartData _baseChart({
    required List<LineChartBarData> bars,
    bool withTouch = true,
  }) {
    return LineChartData(
      lineTouchData: withTouch
          ? LineTouchData(
              touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                if (event is FlTapUpEvent &&
                    response?.lineBarSpots != null &&
                    response!.lineBarSpots!.isNotEmpty) {
                  final index = response.lineBarSpots!.first.x.toInt();

                  // Handle tap in twelveWeeks mode
                  if (widget.mode == ChartMode.twelveWeeks &&
                      widget.onWeekTap != null) {
                    widget.onWeekTap!(index);
                  }
                  // Handle tap in week mode
                  else if (widget.mode == ChartMode.week &&
                      widget.onDayTap != null) {
                    widget.onDayTap!(index);
                  }
                }
              },
              // Disable tooltip by returning null for each item
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (items) => items.map((e) => null).toList(),
              ),
            )
          : const LineTouchData(enabled: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false, // Hide vertical lines for cleaner look
        // Only 3 horizontal lines: 0, middle, and max
        horizontalInterval: (_maxY / 2).clamp(0.5, 999).toDouble(),
        verticalInterval: 1,
        getDrawingHorizontalLine: (_) => FlLine(
          color: Colors.black.withOpacity(0.1), // Very subtle grid
          strokeWidth: 0.5,
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: 1,
            getTitlesWidget: _bottomTitle,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            // Show only 3 labels: 0, middle, and max
            interval: (_maxY / 2).clamp(0.5, 999).toDouble(),
            reservedSize: 30,
            getTitlesWidget: _leftTitle,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false, // Remove border for transparent look
      ),
      minX: 0,
      maxX: _maxX,
      minY: 0,
      maxY: _maxY,
      lineBarsData: bars,
      extraLinesData: _buildExtraLines(),
    );
  }

  /// Build extra lines (vertical indicator for selected week/day)
  ExtraLinesData? _buildExtraLines() {
    // Determine which selection index to use based on mode
    double? selectedX;

    if (widget.mode == ChartMode.twelveWeeks &&
        widget.selectedWeekIndex != null) {
      selectedX = widget.selectedWeekIndex!.toDouble();
    } else if (widget.mode == ChartMode.week &&
        widget.selectedDayIndex != null) {
      selectedX = widget.selectedDayIndex!.toDouble();
    }

    // No selection, don't show line
    if (selectedX == null) {
      return null;
    }

    return ExtraLinesData(
      verticalLines: [
        VerticalLine(
          x: selectedX,
          color: const Color.fromRGBO(
              140, 82, 255, 0.6), // Gradient color with transparency
          strokeWidth: 2.5,
          dashArray: [5, 5], // Dashed line for subtle effect
        ),
      ],
    );
  }

  LineChartData _mainData() {
    return _baseChart(
      bars: [
        LineChartBarData(
          spots: _spots,
          isCurved: true,
          gradient: LinearGradient(colors: gradientColors),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: gradientColors[1],
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors.map((c) => c.withOpacity(0.2)).toList(),
            ),
          ),
        ),
      ],
      withTouch: true,
    );
  }

  LineChartData _avgData() {
    final dataLength = widget.data.length;
    final avg = widget.data.isEmpty
        ? 0.0
        : widget.data.reduce((a, b) => a + b) / dataLength.toDouble();

    return _baseChart(
      bars: [
        LineChartBarData(
          spots: List.generate(dataLength, (i) => FlSpot(i.toDouble(), avg)),
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              ColorTween(begin: gradientColors[0], end: gradientColors[1])
                  .lerp(0.2)!,
              ColorTween(begin: gradientColors[0], end: gradientColors[1])
                  .lerp(0.2)!,
            ],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                ColorTween(begin: gradientColors[0], end: gradientColors[1])
                    .lerp(0.2)!
                    .withOpacity(0.10),
                ColorTween(begin: gradientColors[0], end: gradientColors[1])
                    .lerp(0.2)!
                    .withOpacity(0.10),
              ],
            ),
          ),
        ),
      ],
      withTouch: false,
    );
  }
}
