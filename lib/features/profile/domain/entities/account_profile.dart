import 'package:pikacircle/features/profile/domain/entities/app_workflow.dart';
import 'package:pikacircle/features/profile/domain/entities/user_profile.dart';
import 'package:pikacircle/features/profile/domain/entities/wallet.dart';

/// The top-level account aggregate the app shell and profile UI read.
///
/// Bundles the [UserProfile] with the user's [Wallet] (nullable until the
/// wallet row exists). Immutable value object with value equality.
/// Domain-only: no Flutter or Appwrite imports.
class AccountProfile {
  const AccountProfile({
    required this.user,
    this.wallet,
  });

  final UserProfile user;
  final Wallet? wallet;

  /// The app shell to show for this account, derived from the user's roles.
  AppWorkflow get workflow => user.workflow;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountProfile &&
        other.user == user &&
        other.wallet == wallet;
  }

  @override
  int get hashCode => Object.hash(user, wallet);

  @override
  String toString() => 'AccountProfile(user: $user, wallet: $wallet)';
}
