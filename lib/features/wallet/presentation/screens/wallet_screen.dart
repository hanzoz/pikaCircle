import 'package:flutter/material.dart';

import 'package:pikacircle/shared/widgets/empty_state_card.dart';

/// Wallet tab — credit balance, packs, and transaction history.
///
/// Placeholder for now. Balance reads and top-ups are added in this feature's
/// data/domain layers.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateCard(
      title: 'Wallet',
      message: 'Payments and passes will appear here.',
      icon: Icons.account_balance_wallet_rounded,
    );
  }
}
