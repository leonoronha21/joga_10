import 'package:flutter/material.dart';
import '../models/liveness_action.dart';

/// Horizontal step dots showing which actions are done / active / upcoming.
class LivenessStepIndicator extends StatelessWidget {
  const LivenessStepIndicator({
    super.key,
    required this.actions,
    required this.completedCount,
    required this.isDark,
  });

  final List<LivenessAction> actions;
  final int completedCount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(actions.length, (i) {
        final done   = i < completedCount;
        final active = i == completedCount;
        return _StepDot(
          action: actions[i],
          done: done,
          active: active,
          isDark: isDark,
        );
      }),
    );
  }
}

class _StepDot extends StatefulWidget {
  const _StepDot({
    required this.action,
    required this.done,
    required this.active,
    required this.isDark,
  });
  final LivenessAction action;
  final bool done;
  final bool active;
  final bool isDark;

  @override
  State<_StepDot> createState() => _StepDotState();
}

class _StepDotState extends State<_StepDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_StepDot old) {
    super.didUpdateWidget(old);
    if (widget.active && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.active && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const activeColor  = Color(0xFF4F6BF4);
    const doneColor    = Color(0xFF10B981);
    final inactiveColor =
        widget.isDark ? Colors.white24 : Colors.black12;

    final color = widget.done
        ? doneColor
        : widget.active
            ? activeColor
            : inactiveColor;

    final size = widget.active ? 10.0 : 8.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) => Transform.scale(
              scale: widget.active ? 1.0 + _pulse.value * 0.25 : 1.0,
              child: child,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: widget.active
                    ? [BoxShadow(color: activeColor.withValues(alpha:0.5), blurRadius: 6)]
                    : [],
              ),
              child: widget.done
                  ? const Icon(Icons.check, color: Colors.white, size: 6)
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.action.shortLabel,
            style: TextStyle(
              fontSize: 9,
              color: widget.done
                  ? doneColor
                  : widget.active
                      ? activeColor
                      : (widget.isDark ? Colors.white38 : Colors.black38),
              fontWeight:
                  widget.active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
