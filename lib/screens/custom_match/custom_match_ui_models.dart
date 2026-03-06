import 'package:flutter/material.dart';

enum MatchStatus {
  open,
  requested,
  confirmed,
  completed,
  rejected,
  expired,
  cancelled,
}

enum MatchRole { creator, joiner }

class MatchRequest {
  final String id;
  final String name;
  final String avatar;
  final int level;

  const MatchRequest({
    required this.id,
    required this.name,
    required this.avatar,
    required this.level,
  });
}

class ResultClaim {
  final String id;
  final String submittedBy;
  final String submitterName;
  final String submitterAvatar;
  final String claimedWinnerId;
  final String claimedWinnerName;
  final String claimedWinnerAvatar;
  final String proofUrl;
  final String note;
  final String status;
  final String rejectionReason;
  final DateTime createdAt;

  const ResultClaim({
    required this.id,
    required this.submittedBy,
    required this.submitterName,
    required this.submitterAvatar,
    required this.claimedWinnerId,
    required this.claimedWinnerName,
    required this.claimedWinnerAvatar,
    required this.proofUrl,
    required this.note,
    required this.status,
    required this.rejectionReason,
    required this.createdAt,
  });
}

class CustomMatchUiModel {
  final String id;
  final String gameName;
  final String roomType;
  final String matchType;
  final int rounds;
  final int defaultCoin;
  final bool throwableLimit;
  final bool characterSkill;
  final bool allSkillsAllowed;
  final List<String> selectedSkills;
  final bool headshotOnly;
  final bool gunAttributes;
  final double entryFee;
  final double prizePool;
  final String creatorUserId;
  final String creatorName;
  final String creatorAvatar;
  final String joinerUserId;
  final String joinerName;
  final String joinerAvatar;
  final MatchStatus status;
  final MatchRole role;
  final String subtitle;
  final DateTime? requestExpiryAt;
  final bool chatEnabled;
  final bool insufficientBalance;
  final bool unavailable;
  final String roomId;
  final String roomPassword;
  final String winnerName;
  final String submittedWinnerUserId;
  final String submittedProofUrl;
  final String resultSubmittedByName;
  final String verifiedWinnerUserId;
  final bool resultSubmittedForVerification;
  final String resultSubmissionStatus;
  final String resultSubmissionNote;
  final List<MatchRequest> joinRequests;
  final List<ResultClaim> resultClaims;

  const CustomMatchUiModel({
    required this.id,
    required this.gameName,
    required this.roomType,
    required this.matchType,
    required this.rounds,
    required this.defaultCoin,
    required this.throwableLimit,
    required this.characterSkill,
    required this.allSkillsAllowed,
    required this.selectedSkills,
    required this.headshotOnly,
    required this.gunAttributes,
    required this.entryFee,
    required this.prizePool,
    required this.creatorUserId,
    required this.creatorName,
    required this.creatorAvatar,
    required this.joinerUserId,
    required this.joinerName,
    required this.joinerAvatar,
    required this.status,
    required this.role,
    required this.subtitle,
    required this.requestExpiryAt,
    required this.chatEnabled,
    required this.insufficientBalance,
    required this.unavailable,
    required this.roomId,
    required this.roomPassword,
    required this.winnerName,
    required this.submittedWinnerUserId,
    required this.submittedProofUrl,
    required this.resultSubmittedByName,
    required this.verifiedWinnerUserId,
    required this.resultSubmittedForVerification,
    required this.resultSubmissionStatus,
    required this.resultSubmissionNote,
    required this.joinRequests,
    required this.resultClaims,
  });

  bool get isCreator => role == MatchRole.creator;

  String get badgeLabel {
    switch (status) {
      case MatchStatus.open:
        return 'OPEN';
      case MatchStatus.requested:
        return 'REQUESTED';
      case MatchStatus.confirmed:
        return 'CONFIRMED';
      case MatchStatus.completed:
        return 'COMPLETED';
      case MatchStatus.rejected:
        return 'REJECTED';
      case MatchStatus.expired:
        return 'EXPIRED';
      case MatchStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Color get badgeColor {
    switch (status) {
      case MatchStatus.open:
        return Colors.blue;
      case MatchStatus.requested:
        return Colors.orange;
      case MatchStatus.confirmed:
        return Colors.green;
      case MatchStatus.completed:
        return Colors.purple;
      case MatchStatus.rejected:
        return Colors.red;
      case MatchStatus.expired:
        return Colors.grey;
      case MatchStatus.cancelled:
        return Colors.blueGrey;
    }
  }

  CustomMatchUiModel copyWith({
    MatchStatus? status,
    MatchRole? role,
    String? subtitle,
    DateTime? requestExpiryAt,
    bool? chatEnabled,
    bool? insufficientBalance,
    bool? unavailable,
    String? roomId,
    String? roomPassword,
    String? winnerName,
    String? submittedWinnerUserId,
    String? submittedProofUrl,
    String? resultSubmittedByName,
    String? verifiedWinnerUserId,
    bool? resultSubmittedForVerification,
    String? resultSubmissionStatus,
    String? resultSubmissionNote,
    List<MatchRequest>? joinRequests,
    List<ResultClaim>? resultClaims,
  }) {
    return CustomMatchUiModel(
      id: id,
      gameName: gameName,
      roomType: roomType,
      matchType: matchType,
      rounds: rounds,
      defaultCoin: defaultCoin,
      throwableLimit: throwableLimit,
      characterSkill: characterSkill,
      allSkillsAllowed: allSkillsAllowed,
      selectedSkills: selectedSkills,
      headshotOnly: headshotOnly,
      gunAttributes: gunAttributes,
      entryFee: entryFee,
      prizePool: prizePool,
      creatorUserId: creatorUserId,
      creatorName: creatorName,
      creatorAvatar: creatorAvatar,
      joinerUserId: joinerUserId,
      joinerName: joinerName,
      joinerAvatar: joinerAvatar,
      status: status ?? this.status,
      role: role ?? this.role,
      subtitle: subtitle ?? this.subtitle,
      requestExpiryAt: requestExpiryAt ?? this.requestExpiryAt,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      insufficientBalance: insufficientBalance ?? this.insufficientBalance,
      unavailable: unavailable ?? this.unavailable,
      roomId: roomId ?? this.roomId,
      roomPassword: roomPassword ?? this.roomPassword,
      winnerName: winnerName ?? this.winnerName,
      submittedWinnerUserId: submittedWinnerUserId ?? this.submittedWinnerUserId,
      submittedProofUrl: submittedProofUrl ?? this.submittedProofUrl,
      resultSubmittedByName: resultSubmittedByName ?? this.resultSubmittedByName,
      verifiedWinnerUserId: verifiedWinnerUserId ?? this.verifiedWinnerUserId,
      resultSubmittedForVerification:
          resultSubmittedForVerification ?? this.resultSubmittedForVerification,
      resultSubmissionStatus: resultSubmissionStatus ?? this.resultSubmissionStatus,
      resultSubmissionNote: resultSubmissionNote ?? this.resultSubmissionNote,
      joinRequests: joinRequests ?? this.joinRequests,
      resultClaims: resultClaims ?? this.resultClaims,
    );
  }
}

MatchStatus parseBackendStatus(String raw) {
  switch (raw.toUpperCase()) {
    case 'OPEN':
      return MatchStatus.open;
    case 'PENDING_APPROVAL':
      return MatchStatus.requested;
    case 'CONFIRMED':
      return MatchStatus.confirmed;
    case 'COMPLETED':
      return MatchStatus.completed;
    case 'CANCELLED':
      return MatchStatus.cancelled;
    case 'EXPIRED':
      return MatchStatus.expired;
    default:
      return MatchStatus.open;
  }
}

String _initials(String name) {
  final parts = name
      .split(' ')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

CustomMatchUiModel matchFromApi({
  required Map<String, dynamic> raw,
  required MatchRole role,
  required String currentUserId,
}) {
  final creator = raw['creator'] is Map
      ? Map<String, dynamic>.from(raw['creator'] as Map)
      : <String, dynamic>{};
  final joiner = raw['joiner'] is Map
      ? Map<String, dynamic>.from(raw['joiner'] as Map)
      : <String, dynamic>{};
  final status = parseBackendStatus((raw['status'] ?? '').toString());
  final joinerId = (raw['joinerId'] ?? '').toString();
  final creatorId = (raw['creatorId'] ?? '').toString();
  final creatorName = (creator['name'] ?? 'Creator').toString();
  final joinerName = (joiner['name'] ?? 'Joiner').toString();
  final joinerUserId = (joiner['id'] ?? joinerId).toString();
  final expiresAtRaw = (raw['expiresAt'] ?? '').toString().trim();
  final expiresAt = expiresAtRaw.isEmpty
      ? null
      : DateTime.tryParse(expiresAtRaw)?.toLocal();
  final resultSubmission = raw['resultSubmission'] is Map
      ? Map<String, dynamic>.from(raw['resultSubmission'] as Map)
      : <String, dynamic>{};
  final submittedBy = resultSubmission['submittedBy'] is Map
      ? Map<String, dynamic>.from(resultSubmission['submittedBy'] as Map)
      : <String, dynamic>{};
  final completion = raw['completion'] is Map
      ? Map<String, dynamic>.from(raw['completion'] as Map)
      : <String, dynamic>{};
  final verifiedWinnerUserId = (completion['winnerUserId'] ?? '').toString();
  final submittedWinnerUserId = (resultSubmission['winnerUserId'] ?? '').toString();
  final submittedProofUrl = (resultSubmission['proofUrl'] ?? '').toString();
  final submittedByName = (submittedBy['name'] ?? '').toString();
  final hasSubmittedForVerification = resultSubmission.isNotEmpty;
  final submissionStatus = (resultSubmission['status'] ?? '').toString();
  final submissionNote = (resultSubmission['note'] ?? '').toString();

  // Parse result claims
  final resultClaimsRaw = raw['resultClaims'] is List
      ? (raw['resultClaims'] as List)
      : [];
  final resultClaims = resultClaimsRaw.map((claim) {
    final claimMap = claim is Map ? Map<String, dynamic>.from(claim) : <String, dynamic>{};
    final submitter = claimMap['submitter'] is Map
        ? Map<String, dynamic>.from(claimMap['submitter'] as Map)
        : <String, dynamic>{};
    final claimedWinner = claimMap['claimedWinner'] is Map
        ? Map<String, dynamic>.from(claimMap['claimedWinner'] as Map)
        : <String, dynamic>{};
    
    return ResultClaim(
      id: (claimMap['id'] ?? '').toString(),
      submittedBy: (claimMap['submittedBy'] ?? '').toString(),
      submitterName: (submitter['name'] ?? '').toString(),
      submitterAvatar: (submitter['avatar'] ?? '').toString(),
      claimedWinnerId: (claimMap['claimedWinnerId'] ?? '').toString(),
      claimedWinnerName: (claimedWinner['name'] ?? '').toString(),
      claimedWinnerAvatar: (claimedWinner['avatar'] ?? '').toString(),
      proofUrl: (claimMap['proofUrl'] ?? '').toString(),
      note: (claimMap['note'] ?? '').toString(),
      status: (claimMap['status'] ?? 'PENDING').toString(),
      rejectionReason: (claimMap['rejectionReason'] ?? '').toString(),
      createdAt: DateTime.tryParse((claimMap['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }).toList();

  final winnerName = verifiedWinnerUserId.isNotEmpty
      ? (verifiedWinnerUserId == creatorId ? creatorName : joinerName)
      : '';

  String subtitle;
  if (status == MatchStatus.open && role == MatchRole.creator) {
    subtitle = 'Waiting for players';
  } else if (status == MatchStatus.requested && role == MatchRole.joiner) {
    subtitle = 'Waiting for approval';
  } else if (status == MatchStatus.requested && role == MatchRole.creator) {
    subtitle = 'Join Request Received';
  } else if (status == MatchStatus.confirmed) {
    subtitle = 'Match confirmed. Room and chat enabled.';
  } else if (status == MatchStatus.completed) {
    subtitle = 'Completed match summary available';
  } else if (status == MatchStatus.cancelled) {
    subtitle = 'This match was cancelled';
  } else if (joinerId == currentUserId && role == MatchRole.joiner) {
    subtitle = 'You are assigned as joiner';
  } else {
    subtitle = 'Custom 1v1 room';
  }

  return CustomMatchUiModel(
    id: (raw['id'] ?? '').toString(),
    gameName: (raw['gameName'] ?? 'Free Fire').toString(),
    roomType: (raw['roomType'] ?? 'CUSTOM_ROOM').toString(),
    matchType: (raw['matchType'] ?? '1v1').toString(),
    rounds: ((raw['rounds'] ?? 7) as num).toInt(),
    defaultCoin: ((raw['defaultCoin'] ?? 9950) as num).toInt(),
    throwableLimit: raw['throwableLimit'] == true,
    characterSkill: raw['characterSkill'] == true,
    allSkillsAllowed: raw['allSkillsAllowed'] != false,
    selectedSkills: (raw['selectedSkills'] is List)
        ? List<String>.from((raw['selectedSkills'] as List).map((e) => e.toString()))
        : const [],
    headshotOnly: raw['headshotOnly'] != false,
    gunAttributes: raw['gunAttributes'] == true,
    entryFee: _parseDouble(raw['entryFee']),
    prizePool: _parseDouble(raw['prizePool']),
    creatorUserId: creatorId,
    creatorName: creatorName,
    creatorAvatar: _initials(
      (creator['avatar'] ?? creatorName).toString(),
    ),
    joinerUserId: joinerUserId,
    joinerName: joinerName,
    joinerAvatar: (joiner['avatar'] ?? '').toString(),
    status: status,
    role: role,
    subtitle: subtitle,
    requestExpiryAt: expiresAt,
    chatEnabled: status == MatchStatus.confirmed,
    insufficientBalance: false,
    unavailable: false,
    roomId: (raw['roomIdMasked'] ?? raw['roomId'] ?? '').toString(),
    roomPassword:
        (raw['roomPasswordMasked'] ?? raw['roomPassword'] ?? '').toString(),
    winnerName: winnerName,
    submittedWinnerUserId: submittedWinnerUserId,
    submittedProofUrl: submittedProofUrl,
    resultSubmittedByName: submittedByName,
    verifiedWinnerUserId: verifiedWinnerUserId,
    resultSubmittedForVerification: hasSubmittedForVerification,
    resultSubmissionStatus: submissionStatus,
    resultSubmissionNote: submissionNote,
    joinRequests: const [],
    resultClaims: resultClaims,
  );
}


