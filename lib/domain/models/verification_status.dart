import 'package:freezed_annotation/freezed_annotation.dart';

part 'verification_status.freezed.dart';

/// Aggregated verification state for a profile.
@freezed
class VerificationStatus with _$VerificationStatus {
  const factory VerificationStatus({
    @Default(false) bool photoVerified,
    @Default(false) bool idVerified,
    @Default(false) bool emailVerified,
    @Default(false) bool phoneVerified,
    @Default(false) bool linkedInVerified,
    @Default(false) bool educationVerified,
    /// 0.0 to 1.0; derived or stored
    @Default(0.0) double score,
    // ID verification status string: none | pending | approved | rejected
    String? idVerificationStatus,
    // Rejection reason shown to user when idVerificationStatus == "rejected"
    String? idVerificationRejectionReason,
    // Education verification status string: none | pending | approved | rejected
    String? educationVerificationStatus,
    // Rejection reason shown to user when educationVerificationStatus == "rejected"
    String? educationRejectionReason,
  }) = _VerificationStatus;
}
