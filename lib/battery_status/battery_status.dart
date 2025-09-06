import 'package:flutter/material.dart';
import 'battery_status_manager.dart';

class BatteryStatus extends StatefulWidget {
  final double? size;
  final Color? color;

  const BatteryStatus({super.key, this.size, this.color});

  @override
  State<BatteryStatus> createState() => _BatteryStatusState();
}

class _BatteryStatusState extends State<BatteryStatus> {
  final manager = BatteryStatusManager();

  @override
  void initState() {
    super.initState();
    manager.initialize(); // 한 번만 실행됨
  }

  IconData _getBatteryIcon(int level) {
    switch (level) {
      case 0: return Icons.battery_1_bar_outlined;
      case 1: return Icons.battery_2_bar_outlined;
      case 2: return Icons.battery_4_bar_outlined;
      case 3: return Icons.battery_6_bar_outlined;
      case 4: return Icons.battery_full;
      case 5: return Icons.battery_charging_full;
      default: return Icons.battery_unknown;
    }
  }

  Color _getBatteryColor(int level) {
    switch (level) {
      case 0: return Colors.red;
      case 1: return Colors.orange;
      case 2: return Colors.yellow;
      case 3: return Colors.lightGreen;
      case 4: return Colors.green;
      case 5: return Colors.greenAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: manager.batteryLevel,
      builder: (context, level, _) {
        return Icon(
          _getBatteryIcon(level),
          size: widget.size ?? 32,
          color: widget.color ?? _getBatteryColor(level),
        );
      },
    );
  }
}
