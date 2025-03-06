import 'package:flutter/material.dart';

class ResponsiveBuilder extends StatelessWidget {
  final Widget mobileView;
  final Widget? tabletView;
  final Widget? desktopView;

  const ResponsiveBuilder({
    super.key,
    required this.mobileView,
    this.tabletView,
    this.desktopView,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 1200 && desktopView != null) {
      return desktopView!;
    } else if (screenWidth >= 600 && tabletView != null) {
      return tabletView!;
    } else {
      return mobileView;
    }
  }
}

class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool showBackButton;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    this.actions = const [],
    required this.body,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobileView: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
          leading: showBackButton && Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          actions: actions,
        ),
        body: SafeArea(
          child: body,
        ),
        floatingActionButton: floatingActionButton,
        drawer: drawer,
        endDrawer: endDrawer,
      ),
      tabletView: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
          leading: showBackButton && Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          actions: [
            ...actions,
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: body,
        ),
        floatingActionButton: floatingActionButton,
        drawer: drawer,
        endDrawer: endDrawer,
      ),
      desktopView: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
          leading: showBackButton && Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          actions: [
            ...actions,
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: body,
        ),
        floatingActionButton: floatingActionButton,
        drawer: drawer,
        endDrawer: endDrawer,
      ),
    );
  }
}
