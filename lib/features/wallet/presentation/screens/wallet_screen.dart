import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pikacircle/features/wallet/domain/entities/wallet_transaction.dart';
import 'package:pikacircle/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:pikacircle/shared/widgets/pika_app_bar.dart';

/// Wallet tab — balance summary and recent credit history.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletControllerProvider);

    return walletState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _WalletErrorState(
        message: error.toString(),
        onRetry: () => ref.read(walletControllerProvider.notifier).reload(),
      ),
      data: (data) {
        final wallet = data?.wallet;
        final transactions = data?.transactions ?? const <WalletTransaction>[];
        final totalCredits = wallet?.totalCredits ?? 0;
        final freeCredits = wallet?.freeCredits ?? 0;
        final paidCredits = wallet?.paidCredits ?? 0;
        final freeCreditsExpiryText = wallet?.freeCreditsExpiryDate;
        final freeCreditsExpiryDate =
            (freeCreditsExpiryText != null && freeCreditsExpiryText.isNotEmpty)
            ? DateTime.tryParse(freeCreditsExpiryText)
            : null;
        final daysUntilExpiry = freeCreditsExpiryDate
            ?.difference(DateTime.now())
            .inDays;
        final hasCredits = totalCredits > 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PikaAppBar(leading: PikaAppBarLeading.back, initials: 'P'),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9FA),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color(0xFFF0F1F5)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x19000000),
                                blurRadius: 28,
                                offset: Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF23262D),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.creditcard_fill,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Wallet Balance',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: const Color(0xFF1D2230),
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Free credits refresh monthly.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: const Color.fromARGB(
                                                  255,
                                                  209,
                                                  73,
                                                  85,
                                                ),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Total Balance',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF6F7482),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_formatCredits(totalCredits)} Credits',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: const Color(0xFF1D2230),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _CreditStatTile(
                                      title: 'Free Credits',
                                      value: _formatCredits(freeCredits),
                                      accentColor: const Color(0xFFE11D48),
                                      bottomLabel: daysUntilExpiry != null
                                          ? 'Expired in ${daysUntilExpiry.clamp(0, 999)} ${daysUntilExpiry == 1 ? 'day' : 'days'}'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _CreditStatTile(
                                      title: 'Paid Credits',
                                      value: _formatCredits(paidCredits),
                                      accentColor: const Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2B2E36),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      CupertinoIcons.star_fill,
                                      size: 17,
                                      color: Color(0xFFD6D8DF),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            hasCredits
                                                ? '${_formatCredits(totalCredits)} Credits'
                                                : 'Out of Credits!',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Text(
                                            hasCredits
                                                ? '${_formatCredits(freeCredits)} free · ${_formatCredits(paidCredits)} paid'
                                                : 'Top up to keep playing.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFFD6D8DF,
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Transactions',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: const Color(0xFF1D2230),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            IconButton(
                              onPressed: () => ref
                                  .read(walletControllerProvider.notifier)
                                  .reload(),
                              tooltip: 'Refresh transactions',
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (transactions.isEmpty)
                          _EmptyTransactionsState(hasCredits: hasCredits)
                        else
                          Column(
                            children: [
                              for (final transaction in transactions)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _TransactionCard(
                                    transaction: transaction,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CreditStatTile extends StatelessWidget {
  const _CreditStatTile({
    required this.title,
    required this.value,
    required this.accentColor,
    this.bottomLabel,
  });

  final String title;
  final String value;
  final Color accentColor;
  final String? bottomLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6F7482),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          bottomLabel != null
              ? Text(
                  bottomLabel!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F7482),
                    fontWeight: FontWeight.w500,
                  ),
                )
              : const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final amountColor = isCredit
        ? const Color(0xFF16A34A)
        : const Color(0xFFE11D48);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F1F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _TransactionIcon(transaction: transaction),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF1D2230),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  transaction.displayType,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6F7482),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.amountLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTransactionTimestamp(transaction.transactionDate),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6F7482)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionIcon extends StatelessWidget {
  const _TransactionIcon({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = transaction.isCredit
        ? const Color(0xFFE7F8EE)
        : const Color(0xFFFDE8EC);
    final iconColor = transaction.isCredit
        ? const Color(0xFF16A34A)
        : const Color(0xFFE11D48);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(_iconFor(transaction), color: iconColor, size: 22),
    );
  }

  IconData _iconFor(WalletTransaction transaction) {
    if (transaction.displayType == 'Reward') {
      return CupertinoIcons.gift_fill;
    }
    return switch (transaction.type) {
      'session_charge' => Icons.swap_horiz_rounded,
      'refund' => CupertinoIcons.arrow_counterclockwise,
      'purchase' => CupertinoIcons.cart_fill,
      'free_credit_reset' => CupertinoIcons.repeat,
      'adjustment' =>
        transaction.isCredit
            ? CupertinoIcons.plus_circle_fill
            : CupertinoIcons.minus_circle_fill,
      _ => CupertinoIcons.creditcard_fill,
    };
  }
}

class _EmptyTransactionsState extends StatelessWidget {
  const _EmptyTransactionsState({required this.hasCredits});

  final bool hasCredits;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F1F5)),
      ),
      child: Text(
        hasCredits
            ? 'Recent rewards, referral credits, and session charges will appear here.'
            : 'No wallet activity yet.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6F7482)),
      ),
    );
  }
}

class _WalletErrorState extends StatelessWidget {
  const _WalletErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 44),
            const SizedBox(height: 12),
            Text(
              'Wallet unavailable',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

String _formatCredits(num value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(2);
}

String _formatTransactionTimestamp(DateTime dateTime) {
  final local = dateTime.toLocal();
  final month = _monthName(local.month);
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day} $month ${local.year}, $hour:$minute $suffix';
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}
