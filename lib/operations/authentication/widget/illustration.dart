// lib/widgets/workspace_illustration.dart
import 'package:flutter/material.dart';

class WorkspaceIllustration extends StatelessWidget {
  const WorkspaceIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/workspace_illustration.jpg',
      height: 200,
      width: 600,
    );
  }
}