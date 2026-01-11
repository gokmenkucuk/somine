import 'package:flutter/material.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/widgets/loading_indicator.dart';

class SoMineLoadingWidget extends StatelessWidget {
  const SoMineLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: LoadingIndicator(size: 32),
      ),
    );
  }
}
