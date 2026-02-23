import 'package:flutter/material.dart';

class CornerOrnaments extends StatelessWidget {
  const CornerOrnaments({
    super.key,
    required this.bottomLeftAsset,
    required this.bottomRightAsset,
    this.opacity = 0.14,
    this.size = 88,
    this.bottomOffset = -18,
    this.sideOffset = -18,
    this.rotation = 0.0,
    this.tintColor,
  });

  final String bottomLeftAsset;
  final String bottomRightAsset;
  final double opacity;
  final double size;
  final double bottomOffset;
  final double sideOffset;
  final double rotation;
  final Color? tintColor;

  @override
  Widget build(BuildContext context) {
    final tone = tintColor ??
        Theme.of(context).colorScheme.primary.withValues(
              alpha:
                  Theme.of(context).brightness == Brightness.dark ? 0.88 : 0.68,
            );

    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              bottom: bottomOffset,
              left: sideOffset,
              child: Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: -rotation,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(tone, BlendMode.srcIn),
                    child: Image.asset(
                      bottomLeftAsset,
                      width: size,
                      height: size,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: bottomOffset,
              right: sideOffset,
              child: Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: rotation,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(tone, BlendMode.srcIn),
                    child: Image.asset(
                      bottomRightAsset,
                      width: size,
                      height: size,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
