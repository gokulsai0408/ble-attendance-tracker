import 'dart:developer';

import '../../../core/network/api_client.dart';
import '../../auth/services/auth_state.dart';

class AttendanceApiService {
  AttendanceApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// Legacy method name
  Future<bool> markAttendance(
      {required String userId,
      required String courseId,
      required String beaconId}) async {
    final token = AuthState.instance.token;
    if (token == null) {
      throw ApiException('You must be logged in before marking attendance.',
          statusCode: 401);
    }

    final response = await _apiClient.post(
      '/attendance/report',
      token: token,
      body: {
        'sessionId': courseId,
        'studentUid': userId,
        'scanResults': [
          {
            'anchorId': beaconId,
            'rssi': -60, // Fixed high RSSI for testing "enrolled" logic
          }
        ],
      },
    );
    log('Attendance report response: $response');
    return response is Map<String, dynamic> && response['present'] == true;
  }

  /// New method for tracked sessions
  Future<bool> markFinalAttendance({
    required String userId,
    required String courseId,
    required int validMinutes,
    required bool isPresent,
  }) async {
    final token = AuthState.instance.token;
    if (token == null) {
      throw ApiException('You must be logged in before marking attendance.',
          statusCode: 401);
    }

    if (!isPresent) {
      log('Skipping check-in for $userId in $courseId: only $validMinutes valid minutes.');
      return false;
    }

    await _apiClient.post(
      '/attendance/checkin',
      token: token,
      body: {'sessionId': courseId},
    );
    await _apiClient.post(
      '/attendance/checkout',
      token: token,
      body: {'sessionId': courseId},
    );
    return true;
  }
}
