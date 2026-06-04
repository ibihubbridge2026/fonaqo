import 'package:flutter/material.dart';
import 'dart:async';

/// Indicateur "en train d'écrire" avec debounce anti-spam
class TypingIndicator extends StatefulWidget {
  final String userName;
  final bool isTyping;
  final Duration debounceDuration;

  const TypingIndicator({
    super.key,
    required this.userName,
    required this.isTyping,
    this.debounceDuration = const Duration(seconds: 2),
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> {
  bool _showIndicator = false;
  Timer? _debounceTimer;

  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isTyping != oldWidget.isTyping) {
      if (widget.isTyping) {
        // Afficher immédiatement si l'utilisateur commence à écrire
        setState(() => _showIndicator = true);
        _debounceTimer?.cancel();
      } else {
        // Cacher après le délai de debounce
        _debounceTimer?.cancel();
        _debounceTimer = Timer(widget.debounceDuration, () {
          if (mounted) {
            setState(() => _showIndicator = false);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showIndicator) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${widget.userName} ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const _TypingDots(),
        ],
      ),
    );
  }
}

/// Animation des points de typing
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final opacity = (_animation.value - delay).clamp(0.0, 1.0);
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600]?.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
