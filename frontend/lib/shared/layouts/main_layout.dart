import 'package:flutter/material.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool showBackButton;
  final Color? backgroundColor;
  final PreferredSizeWidget? customAppBar;
  final EdgeInsetsGeometry? padding;
  final bool resizeToAvoidBottomInset;
  final String? semanticsLabel;

  const MainLayout({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.showBackButton = true,
    this.backgroundColor,
    this.customAppBar,
    this.padding,
    this.resizeToAvoidBottomInset = true,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    // Responsive padding calculation
    final horizontalPadding = screenWidth > 600 ? 32.0 : 16.0;
    final defaultPadding = EdgeInsets.symmetric(horizontal: horizontalPadding);

    return Semantics(
      label: semanticsLabel ?? 'Main layout screen',
      child: Scaffold(
        backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        appBar: customAppBar ??
            (title != null
                ? AppBar(
                    title: Text(
                      title!,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    actions: actions,
                    leading: showBackButton && Navigator.of(context).canPop()
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back),
                            tooltip: 'Back',
                            onPressed: () => Navigator.of(context).pop(),
                          )
                        : null,
                    backgroundColor: theme.colorScheme.surface,
                    elevation: 0,
                    centerTitle: true,
                  )
                : null),
        drawer: drawer != null
            ? Drawer(
                backgroundColor: theme.colorScheme.surface,
                elevation: 1,
                child: drawer!,
              )
            : null,
        endDrawer: endDrawer != null
            ? Drawer(
                backgroundColor: theme.colorScheme.surface,
                elevation: 1,
                child: endDrawer!,
              )
            : null,
        body: SafeArea(
          child: Padding(
            padding: padding ?? defaultPadding,
            child: child,
          ),
        ),
        floatingActionButton: floatingActionButton != null
            ? Semantics(
                button: true,
                label: 'Floating action button',
                child: floatingActionButton!,
              )
            : null,
        bottomNavigationBar: bottomNavigationBar != null
            ? Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: bottomNavigationBar!,
                ),
              )
            : null,
      ),
    );
  }
}