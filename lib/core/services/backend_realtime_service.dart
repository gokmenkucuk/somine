import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';

class BackendRealtimeService {
  factory BackendRealtimeService() => _instance;

  BackendRealtimeService._();

  static final BackendRealtimeService _instance = BackendRealtimeService._();

  final BackendAuthService _backendAuthService = BackendAuthService();
  final StreamController<Map<String, dynamic>> _itemsChangedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _categoriesChangedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _notificationsChangedController =
      StreamController<Map<String, dynamic>>.broadcast();

  HubConnection? _itemsConnection;
  HubConnection? _categoriesConnection;
  HubConnection? _notificationsConnection;
  Future<void>? _connectOperation;
  String? _connectedUserId;

  Stream<Map<String, dynamic>> get itemsChanges =>
      _itemsChangedController.stream;
  Stream<Map<String, dynamic>> get categoriesChanges =>
      _categoriesChangedController.stream;
  Stream<Map<String, dynamic>> get notificationsChanges =>
      _notificationsChangedController.stream;

  Future<void> connectForCurrentUser() {
    if (!ApiConfig.isBackendAuthEnabled) {
      return Future.value();
    }

    return _connectOperation ??=
        _connectForCurrentUserInternal().whenComplete(() {
          _connectOperation = null;
        });
  }

  Future<void> disconnect() async {
    _connectedUserId = null;

    final itemsConnection = _itemsConnection;
    final categoriesConnection = _categoriesConnection;
    final notificationsConnection = _notificationsConnection;

    _itemsConnection = null;
    _categoriesConnection = null;
    _notificationsConnection = null;

    if (itemsConnection != null) {
      try {
        await itemsConnection.stop();
      } catch (error) {
        debugPrint(
          '⚠️ [BackendRealtimeService] Failed to stop items hub: $error',
        );
      }
    }

    if (categoriesConnection != null) {
      try {
        await categoriesConnection.stop();
      } catch (error) {
        debugPrint(
          '⚠️ [BackendRealtimeService] Failed to stop categories hub: $error',
        );
      }
    }

    if (notificationsConnection != null) {
      try {
        await notificationsConnection.stop();
      } catch (error) {
        debugPrint(
          '⚠️ [BackendRealtimeService] Failed to stop notifications hub: $error',
        );
      }
    }
  }

  Future<void> _connectForCurrentUserInternal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await disconnect();
      return;
    }

    final userId = user.uid;
    if (_connectedUserId != userId) {
      await disconnect();
    } else if (_hasActiveConnection(_itemsConnection) &&
        _hasActiveConnection(_categoriesConnection) &&
        _hasActiveConnection(_notificationsConnection)) {
      return;
    }

    final accessToken = await _backendAuthService.getValidAccessToken(
      firebaseUser: user,
    );
    if (accessToken == null || accessToken.isEmpty) {
      debugPrint(
        '⚠️ [BackendRealtimeService] Backend access token missing. Realtime disabled.',
      );
      return;
    }

    _connectedUserId = userId;
    _itemsConnection ??= _buildConnection(
      path: '/hub/items',
      eventName: 'items_changed',
      onEvent: (payload) => _itemsChangedController.add(payload),
    );
    _categoriesConnection ??= _buildConnection(
      path: '/hub/categories',
      eventName: 'categories_changed',
      onEvent: (payload) => _categoriesChangedController.add(payload),
    );
    _notificationsConnection ??= _buildConnection(
      path: '/hub/notifications',
      eventName: 'notifications_changed',
      onEvent: (payload) => _notificationsChangedController.add(payload),
    );

    await _startConnection(_itemsConnection, label: 'items');
    await _startConnection(_categoriesConnection, label: 'categories');
    await _startConnection(_notificationsConnection, label: 'notifications');
  }

  HubConnection _buildConnection({
    required String path,
    required String eventName,
    required void Function(Map<String, dynamic> payload) onEvent,
  }) {
    final connection = HubConnectionBuilder()
        .withUrl(
          _buildHubUrl(path),
          options: HttpConnectionOptions(
            accessTokenFactory: () async {
              final user = FirebaseAuth.instance.currentUser;
              final accessToken = await _backendAuthService.getValidAccessToken(
                firebaseUser: user,
              );
              return accessToken ?? '';
            },
          ),
        )
        .withAutomaticReconnect(retryDelays: const [0, 2000, 5000, 10000])
        .build();

    connection.on(eventName, (arguments) {
      final payload = _extractPayload(arguments);
      if (payload != null) {
        onEvent(payload);
      }
    });

    connection.onclose(({Exception? error}) {
      debugPrint(
        '⚠️ [BackendRealtimeService] $eventName hub closed: ${error ?? 'no error'}',
      );
    });

    connection.onreconnected(({String? connectionId}) {
      debugPrint(
        '✅ [BackendRealtimeService] $eventName hub reconnected: $connectionId',
      );
    });

    connection.onreconnecting(({Exception? error}) {
      debugPrint(
        '⚠️ [BackendRealtimeService] $eventName hub reconnecting: ${error ?? 'no error'}',
      );
    });

    return connection;
  }

  Future<void> _startConnection(
    HubConnection? connection, {
    required String label,
  }) async {
    if (connection == null || _hasActiveConnection(connection)) {
      return;
    }

    try {
      await connection.start();
      debugPrint('✅ [BackendRealtimeService] Connected $label hub.');
    } catch (error) {
      debugPrint(
        '⚠️ [BackendRealtimeService] Failed to connect $label hub: $error',
      );
    }
  }

  bool _hasActiveConnection(HubConnection? connection) {
    return connection != null &&
        connection.state != HubConnectionState.Disconnected &&
        connection.state != HubConnectionState.Disconnecting;
  }

  String _buildHubUrl(String path) {
    final baseUrl = ApiConfig.baseUrl;
    final normalizedBase =
        baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
    return '$normalizedBase$path';
  }

  Map<String, dynamic>? _extractPayload(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      return null;
    }

    final first = arguments.first;
    if (first is Map<String, dynamic>) {
      return first;
    }

    if (first is Map) {
      return first.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    return null;
  }
}
