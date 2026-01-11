import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;

  const LoadingIndicator({super.key, this.color, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    // Increase size multiplier to make it really big
    return _AnimatedLogo(size: size * 8);
  }
}

class _AnimatedLogo extends StatefulWidget {
  final double size;

  const _AnimatedLogo({required this.size});

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.size,
      width: widget.size, // Assuming square logo, or let it take width
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base Layer: Black Logo
          Image.asset(
            'assets/images/logo.png',
            height: widget.size,
            fit: BoxFit.contain,
          ),

          // Overlay Layer: Color Logo with Moving Mask
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: const [
                      Colors.transparent,
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                    transform: _GradientTransform(_controller.value),
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: child,
              );
            },
            child: Image.asset(
              'assets/images/logo_v2.png',
              height: widget.size,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientTransform extends GradientTransform {
  final double value;

  const _GradientTransform(this.value);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Move the gradient from left (outside) to right (outside)
    // We translate the gradient based on the animation value
    final double dist = bounds.width * 3;
    return Matrix4.translationValues(-bounds.width + (dist * value), 0, 0);
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
          Positioned.fill(
            child: Container(
              color: Colors.white, // Solid white to hide underlying content
              child: Center(child: LoadingIndicator(color: color, size: 24)),
            ),
          ),
      ],
    );
  }
}
