import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final List<double> soll = <double>[];
  final List<double> ist = <double>[];
  final List<double> current = <double>[];
  final List<double> voltage = <double>[];

  final List<List<bool>> digitalRows =
      List<List<bool>>.generate(10, (_) => <bool>[]);

  final Random rng = Random();

  Timer? timer;
  double t = 0.0;

  bool showSoll = true;
  bool showIst = true;
  bool showCurrent = true;
  bool showVoltage = false;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      t += 0.12;

      double target;
      if (t < 3.0) {
        target = t * 10.0;
      } else if (t < 11.0) {
        target = 30.0;
      } else if (t < 16.0) {
        target = 30.0 - (t - 11.0) * 6.0;
      } else {
        target = 0.0;
      }

      final double measured = max(0.0, target + rng.nextDouble() * 2.0 - 1.0);
      final double amp =
          max(0.0, 12.0 + measured * 0.25 + rng.nextDouble() * 2.0 - 1.0);
      final double volt = 24.0 + measured * 0.2 + rng.nextDouble() * 1.5;

      setState(() {
        soll.add(target);
        ist.add(measured);
        current.add(amp);
        voltage.add(volt);

        for (int row = 0; row < digitalRows.length; row++) {
          final bool value = _digitalValueForRow(row, t);
          digitalRows[row].add(value);
          if (digitalRows[row].length > 120) {
            digitalRows[row].removeAt(0);
          }
        }

        if (soll.length > 120) {
          soll.removeAt(0);
          ist.removeAt(0);
          current.removeAt(0);
          voltage.removeAt(0);
        }
      });
    });
  }

  bool _digitalValueForRow(int row, double time) {
    switch (row) {
      case 0:
        return time > 1.0 && time < 15.0;
      case 1:
        return time > 0.4 && time < 0.9;
      case 2:
        return time > 0.6 && time < 1.0;
      case 3:
        return time > 1.2 && time < 16.5;
      case 4:
        return time > 1.6 && time < 16.8;
      case 5:
        return time > 2.0 && time < 17.0;
      case 6:
        return time > 2.4 && time < 17.2;
      case 7:
        return time > 3.0 && time < 6.0;
      case 8:
        return time > 16.0 && time < 17.5;
      case 9:
        return time > 4.5 && time < 14.5;
      default:
        return false;
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Widget _legendItem({
    required String label,
    required Color color,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
      ],
    );
  }

  Widget _sidePanel() {
    return Container(
      width: 116,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade400),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendItem(
            label: 'f soll',
            color: Colors.red,
            value: showSoll,
            onChanged: (v) => setState(() => showSoll = v ?? false),
          ),
          const SizedBox(height: 8),
          _legendItem(
            label: 'f ist',
            color: Colors.blue,
            value: showIst,
            onChanged: (v) => setState(() => showIst = v ?? false),
          ),
          const SizedBox(height: 8),
          _legendItem(
            label: 'I ist',
            color: Colors.purple,
            value: showCurrent,
            onChanged: (v) => setState(() => showCurrent = v ?? false),
          ),
          const SizedBox(height: 8),
          _legendItem(
            label: 'U ist',
            color: Colors.black,
            value: showVoltage,
            onChanged: (v) => setState(() => showVoltage = v ?? false),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Y:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: () {},
            child: const Text('Auto'),
          ),
          const SizedBox(height: 12),
          const Text(
            'X:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: () {},
            child: const Text('Auto'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const List<String> ioLabels = <String>[
      'AUF',
      'AB',
      'Vi',
      'V0',
      'V1',
      'V2',
      'V3',
      'N',
      'P',
      'Prg',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fahrkurve'),
      ),
      body: Row(
        children: [
          _sidePanel(),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: AnalogGraphPainter(
                            soll: soll,
                            ist: ist,
                            current: current,
                            voltage: voltage,
                            showSoll: showSoll,
                            showIst: showIst,
                            showCurrent: showCurrent,
                            showVoltage: showVoltage,
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 8,
                        top: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('35Hz',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 11)),
                            Text('30Hz',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 11)),
                            Text('25Hz',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 11)),
                            Text('20Hz',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 11)),
                            Text('15Hz',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 11)),
                            Text('10Hz',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 11)),
                            Text('5Hz',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  color: Colors.black,
                ),
                Expanded(
                  flex: 2,
                  child: CustomPaint(
                    painter: DigitalGraphPainter(
                      rows: digitalRows,
                      labels: ioLabels,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: Colors.grey.shade200,
                  child: Text(
                    't=${t.toStringAsFixed(2)}s   '
                    'f=${ist.isNotEmpty ? ist.last.toStringAsFixed(2) : '0.00'}Hz   '
                    'I=${current.isNotEmpty ? current.last.toStringAsFixed(2) : '0.00'}A   '
                    'U=${voltage.isNotEmpty ? voltage.last.toStringAsFixed(0) : '0'}V',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnalogGraphPainter extends CustomPainter {
  final List<double> soll;
  final List<double> ist;
  final List<double> current;
  final List<double> voltage;
  final bool showSoll;
  final bool showIst;
  final bool showCurrent;
  final bool showVoltage;

  AnalogGraphPainter({
    required this.soll,
    required this.ist,
    required this.current,
    required this.voltage,
    required this.showSoll,
    required this.showIst,
    required this.showCurrent,
    required this.showVoltage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint grid = Paint()
      ..color = Colors.green.withOpacity(0.35)
      ..strokeWidth = 1;

    for (int i = 0; i <= 8; i++) {
      final double y = size.height / 8.0 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    for (int i = 0; i <= 10; i++) {
      final double x = size.width / 10.0 * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    if (showSoll) {
      _drawLine(canvas, size, soll, Colors.red, maxValue: 35.0);
    }
    if (showIst) {
      _drawLine(canvas, size, ist, Colors.blue, maxValue: 35.0);
    }
    if (showCurrent) {
      _drawLine(canvas, size, current, Colors.purple, maxValue: 35.0);
    }
    if (showVoltage) {
      _drawLine(canvas, size, voltage, Colors.black, maxValue: 35.0);
    }
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    List<double> data,
    Color color, {
    required double maxValue,
  }) {
    if (data.length < 2) return;

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final Path path = Path();

    for (int i = 0; i < data.length; i++) {
      final double x = size.width * i / (data.length - 1);
      final double normalized = (data[i] / maxValue).clamp(0.0, 1.0);
      final double y = size.height - (normalized * size.height * 0.92);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant AnalogGraphPainter oldDelegate) => true;
}

class DigitalGraphPainter extends CustomPainter {
  final List<List<bool>> rows;
  final List<String> labels;

  DigitalGraphPainter({
    required this.rows,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftLabelWidth = 44.0;
    final int rowCount = rows.length;
    final double rowHeight = size.height / rowCount;

    final Paint grid = Paint()
      ..color = Colors.green.withOpacity(0.35)
      ..strokeWidth = 1;

    for (int i = 0; i <= 10; i++) {
      final double x =
          leftLabelWidth + (size.width - leftLabelWidth) / 10.0 * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    const TextStyle textStyle = TextStyle(
      color: Colors.black,
      fontSize: 12,
    );

    for (int row = 0; row < rowCount; row++) {
      final double yTop = row * rowHeight;
      final double yMid = yTop + rowHeight / 2.0;

      final TextPainter tp = TextPainter(
        text: TextSpan(text: labels[row], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(6, yMid - tp.height / 2.0));

      if (rows[row].length < 2) continue;

      final Path path = Path();
      bool currentValue = rows[row].first;

      final double firstX = leftLabelWidth;
      final double firstY =
          currentValue ? yTop + rowHeight * 0.25 : yTop + rowHeight * 0.78;
      path.moveTo(firstX, firstY);

      for (int i = 1; i < rows[row].length; i++) {
        final double x = leftLabelWidth +
            (size.width - leftLabelWidth) * i / (rows[row].length - 1);

        final bool nextValue = rows[row][i];

        final double currentY =
            currentValue ? yTop + rowHeight * 0.25 : yTop + rowHeight * 0.78;
        final double nextY =
            nextValue ? yTop + rowHeight * 0.25 : yTop + rowHeight * 0.78;

        path.lineTo(x, currentY);
        if (nextValue != currentValue) {
          path.lineTo(x, nextY);
        }
        currentValue = nextValue;
      }

      final Paint paint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DigitalGraphPainter oldDelegate) => true;
}