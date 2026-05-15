import 'package:flutter/material.dart';

enum FeedbackType { success, error, info, warning }

class CustomToast extends StatefulWidget {
  final String message;
  final FeedbackType type;
  final Duration duration;
  
  const CustomToast({
    super.key,
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<CustomToast> createState() => _CustomToastState();
}

class _CustomToastState extends State<CustomToast> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.forward();
    
    // Auto-dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    
    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(colors.icon, color: colors.iconColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.type == FeedbackType.error)
                  IconButton(
                    icon: Icon(Icons.close, color: colors.text, size: 20),
                    onPressed: () {
                      _controller.reverse().then((_) {
                        if (mounted) Navigator.of(context).pop();
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  _ToastColors _getColors() {
    switch (widget.type) {
      case FeedbackType.success:
        return _ToastColors(
          background: const Color(0xFFE8F5E8),
          text: const Color(0xFF2E7D32),
          icon: Icons.check_circle,
          iconColor: const Color(0xFF4CAF50),
          shadow: Colors.green.withOpacity(0.2),
        );
      case FeedbackType.error:
        return _ToastColors(
          background: const Color(0xFFFFF3F0),
          text: const Color(0xFFD32F2F),
          icon: Icons.error_outline,
          iconColor: const Color(0xFFE53935),
          shadow: Colors.red.withOpacity(0.2),
        );
      case FeedbackType.warning:
        return _ToastColors(
          background: const Color(0xFFFFF8E1),
          text: const Color(0xFFE65100),
          icon: Icons.warning_amber,
          iconColor: const Color(0xFFFF9800),
          shadow: Colors.orange.withOpacity(0.2),
        );
      case FeedbackType.info:
        return _ToastColors(
          background: const Color(0xFFE3F2FD),
          text: const Color(0xFF1565C0),
          icon: Icons.info_outline,
          iconColor: const Color(0xFF2196F3),
          shadow: Colors.blue.withOpacity(0.2),
        );
    }
  }
}

class _ToastColors {
  final Color background;
  final Color text;
  final IconData icon;
  final Color iconColor;
  final Color shadow;
  
  _ToastColors({
    required this.background,
    required this.text,
    required this.icon,
    required this.iconColor,
    required this.shadow,
  });
}
