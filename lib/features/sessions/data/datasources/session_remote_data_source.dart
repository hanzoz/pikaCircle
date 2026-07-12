import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';

import 'package:pikacircle/core/config/appwrite_config.dart';
import 'package:pikacircle/features/sessions/domain/entities/session_join_result.dart';

/// Calls the trusted `session-join` Appwrite Function.
///
/// Contract (verified against the deployed function):
/// - POST JSON `{ "sessionId": "<id>", "accessCode": "<code>"? }`.
/// - The caller's user id is injected by Appwrite via the session; the client
///   does not send it.
/// - Success body: `{ status, message, existing, participantId? }`.
/// - Error body: `{ "error": "message" }` with a non-2xx status code.
class SessionRemoteDataSource {
  const SessionRemoteDataSource(this._functions, this._config);

  final Functions _functions;
  final AppwriteConfig _config;

  Future<SessionJoinResult> joinSession({
    required String sessionId,
    String? accessCode,
  }) async {
    final payload = <String, Object?>{
      'sessionId': sessionId,
      if (accessCode != null && accessCode.isNotEmpty) 'accessCode': accessCode,
    };

    final execution = await _functions.createExecution(
      functionId: _config.sessionJoinFunctionId,
      body: jsonEncode(payload),
      method: ExecutionMethod.pOST,
      headers: const {'content-type': 'application/json'},
    );

    final body = _decodeBody(execution.responseBody);
    final statusCode = execution.responseStatusCode;

    if (statusCode >= 400) {
      final message = body['error'] as String? ?? 'Could not join this session.';
      throw AppwriteException(message, statusCode);
    }

    return SessionJoinResult(
      status: SessionJoinResult.statusFromWire(body['status'] as String?),
      message: body['message'] as String? ?? 'Session join request completed.',
      alreadyJoined: body['existing'] as bool? ?? false,
      participantId: body['participantId'] as String?,
    );
  }

  Map<String, dynamic> _decodeBody(String raw) {
    if (raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }
}
