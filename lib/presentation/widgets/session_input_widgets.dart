import 'package:flutter/material.dart';
import '../../core/theme/arclog_colors.dart';

// ── Roue de sélection (long press sur le chiffre) ────────────────────────────

class _WheelPickerSheet extends StatefulWidget {
  const _WheelPickerSheet({
    required this.label,
    required this.initialValue,
    required this.count,
    required this.onSelected,
    this.displayPadded = true,
  });

  final String label;
  final int initialValue;
  final int count;
  final ValueChanged<int> onSelected;
  final bool displayPadded;

  @override
  State<_WheelPickerSheet> createState() => _WheelPickerSheetState();
}

class _WheelPickerSheetState extends State<_WheelPickerSheet> {
  late final FixedExtentScrollController _ctrl;
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
    _ctrl = FixedExtentScrollController(initialItem: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: ArclogColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: ArclogColors.circuitLine),
          left: BorderSide(color: ArclogColors.circuitLine),
          right: BorderSide(color: ArclogColors.circuitLine),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: ArclogColors.circuitLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'Orbitron', fontSize: 11,
              color: ArclogColors.cyanGlow, letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),

          // Ligne de sélection
          Stack(
            alignment: Alignment.center,
            children: [
              // Bandeau de sélection
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: ArclogColors.cyanGlow.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ArclogColors.cyanGlow.withValues(alpha: 0.30)),
                ),
              ),
              SizedBox(
                height: 200,
                child: ListWheelScrollView.useDelegate(
                  controller: _ctrl,
                  itemExtent: 52,
                  perspective: 0.003,
                  diameterRatio: 1.8,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (i) =>
                      setState(() => _selected = i),
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (_, i) => Center(
                      child: Text(
                        widget.displayPadded
                            ? i.toString().padLeft(2, '0')
                            : '$i',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: i == _selected
                              ? ArclogColors.cyanGlow
                              : ArclogColors.textSecondary
                                  .withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    childCount: widget.count,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                widget.onSelected(_selected);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ArclogColors.cyanGlow,
                foregroundColor: ArclogColors.deepBlack,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('VALIDER',
                  style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}

void _showWheelPicker(
  BuildContext context, {
  required String label,
  required int value,
  required int count,
  required ValueChanged<int> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _WheelPickerSheet(
      label: label,
      initialValue: value,
      count: count,
      onSelected: onSelected,
    ),
  );
}

// ── Compteur durée (+/- par tranches de 5 min) ───────────────────────────────

class SessionDurationPicker extends StatelessWidget {
  const SessionDurationPicker({
    super.key,
    required this.hours,
    required this.minutes,
    required this.onHoursChanged,
    required this.onMinutesChanged,
  });

  final int hours;
  final int minutes;
  final ValueChanged<int> onHoursChanged;
  final ValueChanged<int> onMinutesChanged;

  // Incrémente minutes par 5 avec report sur les heures
  void _incrMinutes() {
    final next = (minutes ~/ 5 + 1) * 5;
    if (next >= 60) {
      if (hours < 99) {
        onHoursChanged(hours + 1);
        onMinutesChanged(0);
      }
    } else {
      onMinutesChanged(next);
    }
  }

  // Décrémente minutes par 5 avec emprunt sur les heures
  void _decrMinutes() {
    if (minutes == 0) {
      if (hours > 0) {
        onHoursChanged(hours - 1);
        onMinutesChanged(55);
      }
    } else {
      onMinutesChanged(((minutes - 1) ~/ 5) * 5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Counter(
          label: 'HEURES',
          value: hours,
          onDecrement: hours > 0 ? () => onHoursChanged(hours - 1) : null,
          onIncrement: hours < 99 ? () => onHoursChanged(hours + 1) : null,
          onLongPressValue: () => _showWheelPicker(
            context,
            label: 'HEURES',
            value: hours,
            count: 24,
            onSelected: onHoursChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: const Text(
            ':',
            style: TextStyle(
              fontFamily: 'Orbitron', fontSize: 36,
              fontWeight: FontWeight.w800,
              color: ArclogColors.cyanGlow,
            ),
          ),
        ),
        _Counter(
          label: 'MINUTES  ×5',
          value: minutes,
          onDecrement: (minutes > 0 || hours > 0) ? _decrMinutes : null,
          onIncrement: (hours < 99 || minutes < 55) ? _incrMinutes : null,
          onLongPressValue: () => _showWheelPicker(
            context,
            label: 'MINUTES',
            value: minutes,
            count: 60,
            onSelected: onMinutesChanged,
          ),
        ),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    this.onLongPressValue,
  });

  final String label;
  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final VoidCallback? onLongPressValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Orbitron', fontSize: 8,
            color: ArclogColors.textSecondary, letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Btn(icon: Icons.remove, onTap: onDecrement),
            const SizedBox(width: 10),
            // Long press → roue de sélection
            GestureDetector(
              onLongPress: onLongPressValue,
              child: Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: onLongPressValue != null
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: ArclogColors.cyanGlow.withValues(alpha: 0.20),
                        ),
                      )
                    : null,
                child: Text(
                  value.toString().padLeft(2, '0'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 38, fontWeight: FontWeight.w800,
                    color: ArclogColors.cyanGlow,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _Btn(icon: Icons.add, onTap: onIncrement),
          ],
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? ArclogColors.cyanGlow.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
            color: enabled
                ? ArclogColors.cyanGlow.withValues(alpha: 0.55)
                : ArclogColors.circuitLine,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon, size: 20,
          color: enabled ? ArclogColors.cyanGlow : ArclogColors.circuitLine,
        ),
      ),
    );
  }
}

// ── Chips de tags ─────────────────────────────────────────────────────────────

const sessionTags = [
  'Boss', 'Exploration', 'Farm', 'Histoire',
  'Combat', 'Craft', 'PvP', 'Grind',
  'Side Quest', 'Glitch', 'Speedrun', 'Co-op',
];

class SessionTagPicker extends StatelessWidget {
  const SessionTagPicker({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  final Set<String> selected;
  final void Function(String tag) onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: sessionTags.map((tag) {
        final isSelected = selected.contains(tag);
        return GestureDetector(
          onTap: () => onToggle(tag),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? ArclogColors.cyanGlow.withValues(alpha: 0.14)
                  : ArclogColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? ArclogColors.cyanGlow
                    : ArclogColors.cyanGlow.withValues(alpha: 0.22),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(
                      color: ArclogColors.cyanGlow.withValues(alpha: 0.18),
                      blurRadius: 6)]
                  : null,
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontFamily: 'Orbitron', fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? ArclogColors.cyanGlow
                    : ArclogColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
