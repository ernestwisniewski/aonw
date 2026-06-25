import 'package:flutter/material.dart';

class GameModalContentScrollView extends StatelessWidget {
  const GameModalContentScrollView({
    required this.children,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final EdgeInsetsGeometry padding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      primary: false,
      shrinkWrap: true,
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}
