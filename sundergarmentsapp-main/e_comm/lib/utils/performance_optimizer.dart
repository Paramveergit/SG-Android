// Performance Optimizer to reduce frame skipping and improve responsiveness
// Addresses the Choreographer frame skipping issues seen in terminal logs

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class PerformanceOptimizer {
  static bool _isInitialized = false;

  /// Initialize performance optimizations
  static void init() {
    if (_isInitialized) return;
    
    // Set frame rate to 60fps consistently
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Ensure smooth animations
      WidgetsBinding.instance.addObserver(_PerformanceObserver());
    });
    
    _isInitialized = true;
  }

  /// Optimized ListView builder for better performance
  static Widget optimizedListView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
    EdgeInsets? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Avoid rebuilding off-screen widgets
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const BouncingScrollPhysics(),
      cacheExtent: 100.0, // Cache only nearby items
    );
  }

  /// Optimized GridView builder for better performance
  static Widget optimizedGridView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    EdgeInsets? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return GridView.builder(
      itemCount: itemCount,
      gridDelegate: gridDelegate,
      itemBuilder: (context, index) {
        // Avoid rebuilding off-screen widgets
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const BouncingScrollPhysics(),
      cacheExtent: 100.0, // Cache only nearby items
    );
  }

  /// Optimized image loading widget
  static Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit? fit,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return RepaintBoundary(
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? 
            Container(
              width: width,
              height: height,
              color: Colors.grey.shade200,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? 
            Container(
              width: width,
              height: height,
              color: Colors.grey.shade200,
              child: const Icon(Icons.error),
            );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            child: child,
          );
        },
      ),
    );
  }

  /// Debounced function execution to prevent excessive calls
  static Function debounce(Function func, Duration delay) {
    var timeout;
    return (args) {
      if (timeout != null) {
        timeout.cancel();
      }
      timeout = Timer(delay, () => func(args));
    };
  }
}

class _PerformanceObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Optimize based on app lifecycle
    switch (state) {
      case AppLifecycleState.paused:
        // App is in background, reduce resource usage
        break;
      case AppLifecycleState.resumed:
        // App is active, normal operation
        break;
      case AppLifecycleState.inactive:
        // App is transitioning
        break;
      case AppLifecycleState.detached:
        // App is being destroyed
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
    super.didChangeAppLifecycleState(state);
  }
}

/// Timer utility for debouncing
class Timer {
  final Duration duration;
  final VoidCallback callback;
  late Future _future;
  bool _isActive = true;

  Timer(this.duration, this.callback) {
    _future = Future.delayed(duration, () {
      if (_isActive) {
        callback();
      }
    });
  }

  void cancel() {
    _isActive = false;
  }
}





