import 'package:flutter/material.dart';
import 'package:somine_app/core/design/design_tokens.dart';

class LoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;
  
  const LoadingIndicator({
    super.key, 
    this.color,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? DesignTokens.primary,
        ),
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color? color;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.white.withValues(alpha: 0.5),
            child: Center(
              child: LoadingIndicator(
                color: color,
                size: 32,
              ),
            ),
          ),
      ],
    );
  }
}
