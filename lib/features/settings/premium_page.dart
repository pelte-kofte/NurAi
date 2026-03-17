import 'package:flutter/material.dart';

import '../../data/premium_service.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  @override
  void initState() {
    super.initState();
    PremiumService.loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duada Premium'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: ValueListenableBuilder<bool>(
            valueListenable: PremiumService.isPremium,
            builder: (context, isPremium, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: PremiumService.isLoading,
                builder: (context, isLoading, _) {
                  return ValueListenableBuilder<String?>(
                    valueListenable: PremiumService.errorMessage,
                    builder: (context, errorMessage, _) {
                      return ValueListenableBuilder(
                        valueListenable: PremiumService.productNotifier,
                        builder: (context, product, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Removes ads and supports the app.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: colorScheme.onSurface,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (isPremium)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Premium is active.',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                )
                              else if (product != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.title,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        product.price,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.72),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Text(
                                  'Monthly subscription is currently unavailable.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.72),
                                  ),
                                ),
                              if (errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  errorMessage,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: colorScheme.error,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              if (isLoading)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: 16),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isPremium || isLoading || product == null
                                      ? null
                                      : PremiumService.buyMonthly,
                                  child: const Text('Subscribe Monthly'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : PremiumService.restorePurchases,
                                  child: const Text('Restore Purchases'),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
