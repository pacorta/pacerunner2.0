import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'stats_view_mode_provider.dart';

/// Segmented control for switching between current week and 12-week views
class StatsSegmentedControl extends ConsumerWidget {
  const StatsSegmentedControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(statsViewModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Last 12 Weeks',
              isSelected: currentMode == StatsViewMode.last12Weeks,
              onTap: () => ref
                  .read(statsViewModeProvider.notifier)
                  .setMode(StatsViewMode.last12Weeks),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'Week',
              isSelected: currentMode == StatsViewMode.currentWeek,
              onTap: () => ref
                  .read(statsViewModeProvider.notifier)
                  .setMode(StatsViewMode.currentWeek),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color.fromRGBO(255, 87, 87, 1.0),
                    Color.fromRGBO(140, 82, 255, 1.0),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color.fromRGBO(140, 82, 255, 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black.withOpacity(0.6),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
