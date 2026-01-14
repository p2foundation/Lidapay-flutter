// HOW TO USE CURRENCY PROVIDER IN OTHER SCREENS
// =============================================

// 1. Import the provider
import '../../../providers/currency_provider.dart';

// 2. In your ConsumerWidget, watch the currency provider
class YourScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCurrency = ref.watch(currencyProvider);
    final currencyNotifier = ref.read(currencyProvider.notifier);
    
    // 3. Use the currency symbol
    return Column(
      children: [
        Text(
          'Price: ${currencyNotifier.getCurrencySymbol(currentCurrency)}99.99',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        
        // Or create a helper method
        Text(
          formatCurrency(99.99, currentCurrency, currencyNotifier),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}

// Helper method to format currency
String formatCurrency(double amount, String currency, CurrencyNotifier notifier) {
  final symbol = notifier.getCurrencySymbol(currency);
  return '$symbol${amount.toStringAsFixed(2)}';
}

// 4. To change currency programmatically
ElevatedButton(
  onPressed: () {
    ref.read(currencyProvider.notifier).setCurrency('EUR');
  },
  child: Text('Change to EUR'),
),
