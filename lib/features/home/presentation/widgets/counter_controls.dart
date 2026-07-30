import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';

class CounterControls extends StatelessWidget {
  const CounterControls({
    required this.count,
    required this.hapticsEnabled,
    required this.animationsEnabled,
    required this.onIncrement,
    required this.onContinuousCountStart,
    required this.onContinuousCountEnd,
    required this.onUndo,
    required this.onReset,
    required this.onSetTarget,
    required this.canUndo,
    required this.canReset,
    super.key,
  });

  final int count;
  final bool hapticsEnabled;
  final bool animationsEnabled;
  final VoidCallback onIncrement;
  final VoidCallback onContinuousCountStart;
  final VoidCallback onContinuousCountEnd;
  final VoidCallback? onUndo;
  final VoidCallback onReset;
  final VoidCallback onSetTarget;
  final bool canUndo;
  final bool canReset;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Column(
      children: [
        _PremiumCountButton(
          count: count,
          hapticsEnabled: hapticsEnabled,
          animationsEnabled: animationsEnabled,
          height: isLandscape ? 104 : 136,
          onTap: onIncrement,
          onLongPressStart: onContinuousCountStart,
          onLongPressEnd: onContinuousCountEnd,
        ),
        const SizedBox(height: AppSpacing.sm),
        _FloatingActionControls(
          canUndo: canUndo,
          canReset: canReset,
          onUndo: onUndo,
          onReset: onReset,
          onSetTarget: onSetTarget,
        ),
      ],
    );
  }
}

class _PremiumCountButton extends StatefulWidget {
  const _PremiumCountButton({
    required this.count,
    required this.hapticsEnabled,
    required this.animationsEnabled,
    required this.height,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  final int count;
  final bool hapticsEnabled;
  final bool animationsEnabled;
  final double height;
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  @override
  State<_PremiumCountButton> createState() => _PremiumCountButtonState();
}

class _PremiumCountButtonState extends State<_PremiumCountButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rippleController;
  Offset _rippleOrigin = Offset.zero;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didUpdateWidget(covariant _PremiumCountButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > oldWidget.count) {
      if (widget.animationsEnabled) {
        _pulseController.forward(from: 0);
      }
      if (widget.hapticsEnabled) {
        HapticFeedback.selectionClick();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _startRipple(TapDownDetails details) {
    setState(() {
      _rippleOrigin = details.localPosition;
    });
    if (widget.animationsEnabled) {
      _rippleController.forward(from: 0);
    }
  }

  void _startContinuousCount() {
    if (widget.hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    widget.onLongPressStart();
  }

  @override
  Widget build(BuildContext context) {
    final pulse = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.035,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.035,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 55,
      ),
    ]).animate(_pulseController);

    return ScaleTransition(
      scale: pulse,
      child: Semantics(
        button: true,
        label: 'Tasbeeh counter',
        value: '${widget.count}',
        hint: 'Double tap to add one. Touch and hold for continuous counting.',
        onTap: widget.onTap,
        onLongPress: widget.onTap,
        child: ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTapDown: _startRipple,
            onTap: widget.onTap,
            onLongPressStart: (_) => _startContinuousCount(),
            onLongPressEnd: (_) => widget.onLongPressEnd(),
            onLongPressCancel: widget.onLongPressEnd,
            child: _CounterSurface(
              height: widget.height,
              rippleOrigin: _rippleOrigin,
              rippleAnimation: _rippleController,
            ),
          ),
        ),
      ),
    );
  }
}

class _CounterSurface extends StatelessWidget {
  const _CounterSurface({
    required this.height,
    required this.rippleOrigin,
    required this.rippleAnimation,
  });

  final double height;
  final Offset rippleOrigin;
  final Animation<double> rippleAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xl)),
        boxShadow: theme.brightness == Brightness.dark
            ? AppShadows.cardDark
            : AppShadows.card,
      ),
      child: Material(
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xl)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rippleDiameter =
                  constraints.maxWidth + constraints.maxHeight;

              return Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: rippleAnimation,
                    builder: (context, _) {
                      final progress = Curves.easeOutCubic.transform(
                        rippleAnimation.value,
                      );
                      final diameter = rippleDiameter * progress;

                      return Positioned(
                        left: rippleOrigin.dx - diameter / 2,
                        top: rippleOrigin.dy - diameter / 2,
                        child: Opacity(
                          opacity: 1 - progress,
                          child: Container(
                            width: diameter,
                            height: diameter,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onPrimary.withValues(
                                alpha: 0.22,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 30,
                        color: theme.colorScheme.onPrimary,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '+1',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Tap to count · Hold to continue',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FloatingActionControls extends StatelessWidget {
  const _FloatingActionControls({
    required this.canUndo,
    required this.canReset,
    required this.onUndo,
    required this.onReset,
    required this.onSetTarget,
  });

  final bool canUndo;
  final bool canReset;
  final VoidCallback? onUndo;
  final VoidCallback onReset;
  final VoidCallback onSetTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: 'Counter actions',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
          boxShadow: theme.brightness == Brightness.dark
              ? AppShadows.cardDark
              : AppShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Undo last count',
                onPressed: canUndo ? onUndo : null,
                icon: const Icon(Icons.undo_rounded),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: 'Reset current count',
                onPressed: canReset ? onReset : null,
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton.filled(
                tooltip: 'Set custom target',
                onPressed: onSetTarget,
                icon: const Icon(Icons.flag_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
