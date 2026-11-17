import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:solufine/core/utility/app_toast.dart';
import 'package:solufine/core/router/app_router.dart';

// Add your existing AppRouter and AppToast imports.

class InternetStatusListener extends StatefulWidget {
  const InternetStatusListener({super.key, required this.child});

  final Widget child;

  @override
  State<InternetStatusListener> createState() => _InternetStatusListenerState();
}

class _InternetStatusListenerState extends State<InternetStatusListener>
    with WidgetsBindingObserver {
  late final InternetConnection _connection;

  StreamSubscription<InternetStatus>? _subscription;

  InternetStatus? _lastStatus;

  int _listenVersion = 0;

  bool _offlineDialogOpen = false;
  bool _isRetrying = false;

  BuildContext? _dialogContext;

  Timer? _offlineTimer;

  bool _checkingConnection = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _connection = InternetConnection.createInstance(
      triggerStream: Connectivity().onConnectivityChanged,
      checkInterval: const Duration(seconds: 15),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      unawaited(_startListening());
    });
  }

  // ============================================================
  // START INTERNET LISTENER
  // ============================================================

  Future<void> _startListening() async {
    final version = ++_listenVersion;

    _offlineTimer?.cancel();
    _offlineTimer = null;

    final previous = _subscription;
    _subscription = null;

    await previous?.cancel();

    if (!mounted || version != _listenVersion) return;

    _subscription = _connection.onStatusChange.listen(
      (status) {
        if (!mounted || version != _listenVersion) return;

        debugPrint('INTERNET STATUS: $status');

        _handleInternetStatus(status);
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('INTERNET LISTENER ERROR: $error');
      },
    );

    try {
      final hasInternet = await _connection.hasInternetAccess;

      if (!mounted || version != _listenVersion) return;

      _handleInternetStatus(
        hasInternet ? InternetStatus.connected : InternetStatus.disconnected,
      );
    } catch (e) {
      debugPrint('INITIAL INTERNET CHECK ERROR: $e');
    }
  }
  // ============================================================
  // HANDLE CONNECTION STATUS
  // ============================================================

  void _handleInternetStatus(InternetStatus status) {
    if (!mounted) return;

    debugPrint('NETWORK STATUS RECEIVED: $status');

    if (status == InternetStatus.connected) {
      _offlineTimer?.cancel();
      _offlineTimer = null;

      final wasOffline = _lastStatus == InternetStatus.disconnected;

      _lastStatus = InternetStatus.connected;

      if (_offlineDialogOpen) {
        _closeOfflineDialog();
      }

      if (wasOffline) {
        AppToast.success('Internet connection restored');
      }

      return;
    }

    // Disconnected status received.
    // Do not immediately show the dialog.
    if (_offlineDialogOpen || _offlineTimer != null) {
      return;
    }

    debugPrint('NETWORK MAY BE OFFLINE - WAITING 5 SECONDS');

    _offlineTimer = Timer(const Duration(seconds: 5), () async {
      _offlineTimer = null;

      if (!mounted || _offlineDialogOpen) return;

      await _confirmDisconnection();
    });
  }

  Future<void> _confirmDisconnection() async {
    if (!mounted || _checkingConnection) return;

    _checkingConnection = true;

    try {
      debugPrint('CONFIRMING INTERNET CONNECTION...');

      final hasInternet = await _connection.hasInternetAccess;

      if (!mounted) return;

      if (hasInternet) {
        debugPrint('INTERNET AVAILABLE - DIALOG CANCELLED');

        _handleInternetStatus(InternetStatus.connected);
      } else {
        debugPrint('INTERNET STILL UNAVAILABLE');

        if (_lastStatus != InternetStatus.disconnected) {
          _lastStatus = InternetStatus.disconnected;

          unawaited(_showOfflineDialog());
        }
      }
    } catch (e) {
      debugPrint('INTERNET CONFIRMATION ERROR: $e');

      // An exception alone is not enough to
      // declare that the device is offline.
    } finally {
      _checkingConnection = false;
    }
  }
  // ============================================================
  // SHOW OFFLINE DIALOG
  // ============================================================

  Future<void> _showOfflineDialog() async {
    if (!mounted || _offlineDialogOpen) return;

    final navigatorContext = AppRouter.navigatorKey.currentContext;

    if (navigatorContext == null) return;

    _offlineDialogOpen = true;

    try {
      await showDialog<void>(
        context: navigatorContext,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) {
          _dialogContext = dialogContext;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return PopScope(
                canPop: false,
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ======================================
                        // RED OFFLINE ICON
                        // ======================================
                        Container(
                          width: 94,
                          height: 94,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE8E8),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFFCCCC),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.wifi_off_rounded,
                            color: Color(0xFFDC2626),
                            size: 45,
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ======================================
                        // TITLE
                        // ======================================
                        const Text(
                          "Oops! You're Offline",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ======================================
                        // DESCRIPTION
                        // ======================================
                        const Text(
                          'It looks like your internet '
                          'connection was lost. Please '
                          'check your Wi-Fi or mobile data '
                          'and try again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: Color(0xFF64748B),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ======================================
                        // RED WARNING MESSAGE
                        // ======================================
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFDC2626),
                                size: 19,
                              ),
                              SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  'No internet connection detected',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ======================================
                        // TRY AGAIN BUTTON
                        // ======================================
                        SizedBox(
                          width: double.infinity,
                          height: 49,
                          child: ElevatedButton.icon(
                            onPressed: _isRetrying
                                ? null
                                : () async {
                                    setDialogState(() {
                                      _isRetrying = true;
                                    });

                                    try {
                                      final hasInternet =
                                          await _connection.hasInternetAccess;

                                      if (!mounted) return;

                                      if (hasInternet) {
                                        _handleInternetStatus(
                                          InternetStatus.connected,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          navigatorContext,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Still offline. Please check your connection.',
                                            ),
                                            backgroundColor: Color(0xFFDC2626),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint('Internet retry failed: $e');
                                    } finally {
                                      if (context.mounted) {
                                        setDialogState(() {
                                          _isRetrying = false;
                                        });
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFFCA5A5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            icon: _isRetrying
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 20),
                            label: Text(
                              _isRetrying ? 'Checking...' : 'Try Again',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ======================================
                        // CONNECTION STATUS
                        // ======================================
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF94A3B8),
                              size: 15,
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Waiting for network connection...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      _dialogContext = null;
      _offlineDialogOpen = false;
      _isRetrying = false;
    }
  }

  // ============================================================
  // AUTO CLOSE WHEN INTERNET RESTORED
  // ============================================================

  void _closeOfflineDialog() {
    final context = _dialogContext;

    if (context == null || !context.mounted) return;

    Navigator.of(context, rootNavigator: true).pop();
  }

  // ============================================================
  // STOP INTERNET LISTENER
  // ============================================================

  void _stopListening() {
    _listenVersion++;

    _offlineTimer?.cancel();
    _offlineTimer = null;

    final subscription = _subscription;
    _subscription = null;

    if (subscription != null) {
      unawaited(subscription.cancel());
    }
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_startListening());
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _stopListening();
        break;

      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _stopListening();

    unawaited(_connection.dispose());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
