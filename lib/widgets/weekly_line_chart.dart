import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Distancias por día de Lunes (idx 0) a Domingo (idx 6)
class WeeklyLineChart extends StatefulWidget {
  final List<double> data; // ej: [0, 3.2, 4.0, 2.8, 0, 12.7, 0]
  final String unitLabel; // "km" o "mi"
  final bool showAvgToggle; // si quieres el botón 'avg'

  const WeeklyLineChart({
    super.key,
    required this.data,
    this.unitLabel = 'km',
    this.showAvgToggle = false, // Changed to false for cleaner look in snapshot
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

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  Widget _bottomTitle(double value, TitleMeta meta) {
    final style = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 10,
      color: Colors.black.withOpacity(0.6),
    );
    final i = value.toInt();
    final text = (i >= 0 && i < 7) ? _dayLabels[i] : '';
    return SideTitleWidget(
      meta: meta,
      child: Text(text, style: style),
    );
  }

  Widget _leftTitle(double value, TitleMeta meta) {
    // Solo mostrar etiquetas si hay datos significativos
    if (widget.data.every((d) => d == 0)) {
      return const SizedBox.shrink(); // No mostrar etiquetas si no hay datos
    }

    // Solo mostrar etiquetas en valores enteros y cuando sea apropiado
    if (value.toInt() > _maxY || value < 0) {
      return const SizedBox.shrink();
    }

    final style = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 9,
      color: Colors.black.withOpacity(0.5),
    );
    return Text(value.toInt().toString(), style: style);
  }

  // ---- Datos / ejes dinámicos ----

  List<FlSpot> get _spots =>
      List.generate(7, (i) => FlSpot(i.toDouble(), widget.data[i]));

  double get _maxY {
    final m = widget.data.fold<double>(0, (a, b) => b > a ? b : a);

    // Si no hay datos, retornar 1.0
    if (m == 0) return 1.0;

    // Para valores muy pequeños (< 1), usar un margen más pequeño
    if (m < 1.0) {
      return (m * 1.5).clamp(0.5, 1.0);
    }

    // Para valores normales, usar margen del 25%
    return m * 1.25;
  }

  // ---- Config principal ----

  LineChartData _baseChart({
    required List<LineChartBarData> bars,
    bool withTouch = true,
  }) {
    return LineChartData(
      lineTouchData: withTouch
          ? LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (items) => items.map((it) {
                  final day = _dayLabels[it.x.toInt()];
                  final v = it.y;
                  // 0–9 con 2 decimales, >=10 sin decimales
                  final txt =
                      v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
                  return LineTooltipItem(
                    '$day: $txt ${widget.unitLabel}',
                    const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            )
          : const LineTouchData(enabled: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false, // Hide vertical lines for cleaner look
        horizontalInterval:
            (_maxY <= 5 ? 1 : (_maxY / 5)).clamp(1, 999).toDouble(),
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
            interval: _calculateLeftInterval(),
            reservedSize: 30,
            getTitlesWidget: _leftTitle,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false, // Remove border for transparent look
      ),
      minX: 0,
      maxX: 6,
      minY: 0,
      maxY: _maxY,
      lineBarsData: bars,
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
    final avg =
        widget.data.isEmpty ? 0.0 : widget.data.reduce((a, b) => a + b) / 7.0;

    return _baseChart(
      bars: [
        LineChartBarData(
          spots: List.generate(7, (i) => FlSpot(i.toDouble(), avg)),
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

  double _calculateLeftInterval() {
    final maxY = _maxY;
    if (maxY <= 5) {
      return 1.0;
    }
    return (maxY / 5).ceilToDouble();
  }
}
