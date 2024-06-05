import 'package:flutter/material.dart';

class FullVendorRefreshIndicator extends StatefulWidget {
  const FullVendorRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshIndicatorKey,
  });
  final Widget child;
  final RefreshCallback onRefresh;
  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;

  @override
  State<FullVendorRefreshIndicator> createState() =>
      _FullVendorRefreshIndicatorState();
}

class _FullVendorRefreshIndicatorState
    extends State<FullVendorRefreshIndicator> {
  late GlobalKey<RefreshIndicatorState> refreshIndicatorKey;

  @override
  void initState() {
    super.initState();
    refreshIndicatorKey =
        widget.refreshIndicatorKey ?? GlobalKey<RefreshIndicatorState>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      refreshIndicatorKey.currentState?.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      key: refreshIndicatorKey,
      child: widget.child,
    );
  }
}
