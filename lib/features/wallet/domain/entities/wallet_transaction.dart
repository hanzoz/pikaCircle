/// A credit wallet transaction row from Appwrite.
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.creditsDelta,
    required this.transactionDate,
    this.remarks,
    this.sessionId,
  });

  final String id;
  final String type;
  final num creditsDelta;
  final DateTime transactionDate;
  final String? remarks;
  final String? sessionId;

  bool get isCredit => creditsDelta >= 0;

  String get displayName => _displayNameFor(type, remarks);

  String get displayType => _displayTypeFor(type, remarks);

  String get amountLabel =>
      '${isCredit ? '+' : '-'}${_formatCredits(creditsDelta.abs())} credits';
}

String _displayNameFor(String type, String? remarks) {
  final normalizedRemarks = remarks?.trim().toLowerCase();
  if (normalizedRemarks != null && normalizedRemarks.isNotEmpty) {
    if (normalizedRemarks == 'wallet_provision') {
      return 'Wallet provision';
    }
    if (normalizedRemarks == 'monthly_reset_grant') {
      return 'Monthly free credits';
    }
    if (normalizedRemarks == 'monthly_reset_expiry') {
      return 'Unused free credits expired';
    }
    if (normalizedRemarks.startsWith('reward_referral')) {
      return 'Referral reward';
    }
    if (normalizedRemarks.startsWith('reward_profile')) {
      return 'Profile reward';
    }
    if (normalizedRemarks.startsWith('reward_hosted_session')) {
      return 'Hosted session reward';
    }
    if (normalizedRemarks.startsWith('reward_')) {
      return 'Gamification reward';
    }
  }

  return switch (type) {
    'session_charge' => 'Session charge',
    'purchase' => 'Credit purchase',
    'refund' => 'Refund',
    'free_credit_reset' => 'Free credit reset',
    'adjustment' => 'Credit adjustment',
    _ => 'Wallet activity',
  };
}

String _displayTypeFor(String type, String? remarks) {
  final normalizedRemarks = remarks?.trim().toLowerCase();
  if (normalizedRemarks != null && normalizedRemarks.startsWith('reward_')) {
    return 'Reward';
  }
  return switch (type) {
    'session_charge' => 'Session',
    'purchase' => 'Top up',
    'refund' => 'Refund',
    'free_credit_reset' => 'Reset',
    'adjustment' => 'Adjustment',
    _ => 'Transaction',
  };
}

String _formatCredits(num value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(2);
}
