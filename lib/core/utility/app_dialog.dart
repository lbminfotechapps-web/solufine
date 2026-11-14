import 'package:flutter/material.dart';

class AppDialog {
  static void show({
    required BuildContext context,
    required String message,
    required DialogType type,
    VoidCallback? onOkPressed,
    bool allowBack = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xffe8f5e9), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// LOGO
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset("assets/icons/logo.png"),
                  ),
                ),

                const SizedBox(height: 15),

                /// MESSAGE
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black),
                ),

                const SizedBox(height: 20),

                /// BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: type == DialogType.success
                          ? Colors.green
                          : Colors.red,
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);

                      if (onOkPressed != null) {
                        onOkPressed();
                      }
                    },
                    child: const Text("OK"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🔹 LOADING DIALOG
  static void showLoading(
    BuildContext context, {
    String message = "Please wait...",
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: Text(message, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 CLOSE ANY DIALOG (IMPORTANT)
  static void hide(BuildContext context) {
    Navigator.pop(context);
  }
}

/// 🔹 ENUM
enum DialogType { success, error }
