// Full-screen, pinch-to-zoom product image viewer.
//
// Replaces the old tap-to-open-Dialog behavior on the product details
// carousel, which opened an undersized popup (the Dialog box only
// sized itself to its content, not the screen) with an InteractiveViewer
// that had no real room to pan/zoom inside it. This instead pushes a
// real full-screen route: true edge-to-edge image, pinch/double-tap
// zoom with sane bounds, and swipe between all of the product's photos
// (not just the one that was tapped).
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FullscreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  /// Opens the viewer as a full-screen route over [context].
  static void open(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: FullscreenImageViewer(
              imageUrls: imageUrls,
              initialIndex: initialIndex,
            ),
          );
        },
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _handleDoubleTap(TapDownDetails details, Size viewportSize) {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.05) {
      _resetZoom();
      return;
    }
    const targetScale = 2.5;
    final tapPosition = details.localPosition;
    final x = -tapPosition.dx * (targetScale - 1);
    final y = -tapPosition.dy * (targetScale - 1);
    // Column-major 4x4: uniform x/y scale plus a translation, built
    // directly (Matrix4.translate/scale are deprecated in newer
    // vector_math releases).
    _transformationController.value = Matrix4(
      targetScale, 0, 0, 0,
      0, targetScale, 0, 0,
      0, 0, 1, 0,
      x, y, 0, 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _resetZoom();
              },
              itemBuilder: (context, index) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onDoubleTapDown: (details) => _handleDoubleTap(
                        details,
                        constraints.biggest,
                      ),
                      onDoubleTap: () {},
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 1.0,
                        maxScale: 5.0,
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl: widget.imageUrls[index],
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CupertinoActivityIndicator(color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white54,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Close button
            Positioned(
              top: 8,
              left: 8,
              child: Material(
                color: Colors.black45,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),

            // Page indicator, only shown when there's more than one photo
            if (widget.imageUrls.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.imageUrls.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
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
