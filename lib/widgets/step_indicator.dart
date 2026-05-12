import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class StepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final List<String> titles;

  const StepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    required this.titles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Indicateur de progression
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: currentStep / totalSteps,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: AppTheme.primaryGradient,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Titres des étapes
        Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index + 1 <= currentStep;
            final isCurrent = index + 1 == currentStep;
            
            return Expanded(
              child: Column(
                children: [
                  // Numéro de l'étape
                  AnimatedContainer(
                    duration: AppTheme.fastAnimation,
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive 
                          ? AppTheme.primaryColor 
                          : Colors.grey.withValues(alpha: 0.3),
                      boxShadow: isCurrent ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ] : null,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isActive 
                              ? AppTheme.secondaryColor 
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Titre de l'étape
                  Text(
                    titles[index],
                    style: TextStyle(
                      color: isActive 
                          ? AppTheme.secondaryColor 
                          : Colors.grey.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
