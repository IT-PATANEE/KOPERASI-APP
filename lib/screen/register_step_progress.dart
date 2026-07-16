import 'package:flutter/material.dart';

class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isEven) {
          int stepIndex = index ~/ 2 + 1;
          bool isActive = stepIndex <= currentStep;

          return Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stepIndex',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        } else {
          return Expanded(
            child: Container(
              height: 2,
              color: (index ~/ 2 + 1) < currentStep
                  ? Colors.green
                  : Colors.grey[300],
            ),
          );
        }
      }),
    );
  }
}
