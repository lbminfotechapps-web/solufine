// import 'package:flutter/material.dart';

// enum DialogType { success, error, warning, info }

// class AppDialog {
//   static void show({
//     required BuildContext context,
//     required String message,
//     DialogType type = DialogType.info,
//     String? title,
//     String buttonText = 'OK',
//   }) {
//     final config = _getConfig(type);

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           title: Row(
//             children: [
//               Icon(config.icon, color: config.color, size: 28),
//               const SizedBox(width: 10),
//               Text(
//                 title ?? config.title,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           content: Text(message, style: const TextStyle(fontSize: 15)),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(dialogContext).pop();
//               },
//               child: Text(
//                 buttonText,
//                 style: TextStyle(
//                   color: config.color,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   static _DialogConfig _getConfig(DialogType type) {
//     switch (type) {
//       case DialogType.success:
//         return const _DialogConfig(
//           title: 'Success',
//           icon: Icons.check_circle,
//           color: Colors.green,
//         );

//       case DialogType.error:
//         return const _DialogConfig(
//           title: 'Error',
//           icon: Icons.error,
//           color: Colors.red,
//         );

//       case DialogType.warning:
//         return const _DialogConfig(
//           title: 'Warning',
//           icon: Icons.warning,
//           color: Colors.orange,
//         );

//       case DialogType.info:
//         return const _DialogConfig(
//           title: 'Information',
//           icon: Icons.info,
//           color: Colors.blue,
//         );
//     }
//   }
// }

// class _DialogConfig {
//   final String title;
//   final IconData icon;
//   final Color color;

//   const _DialogConfig({
//     required this.title,
//     required this.icon,
//     required this.color,
//   });
// }

import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/utility/appname.dart';
import 'package:flutter/material.dart';

enum DialogType { success, error, warning, info }

class AppDialog {
  static void show({
    required BuildContext context,
    required String message,
    DialogType type = DialogType.info,
    String? title,
    String buttonText = 'OK',
    VoidCallback? onButtonPressed,
    bool allowBack = true,w
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final config = _getConfig(dialogContext, type);
        return PopScope(
          canPop: allowBack,
          child: AlertDialog(
            backgroundColor: dialogContext.cardBackgroundColor,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(config.icon, color: config.color, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title ?? config.title,
                    style: TextStyle(
                      color: dialogContext.cardTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: dialogContext.cardTextColor,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();

                  if (onButtonPressed != null) {
                    onButtonPressed();
                  }
                },
                child: Text(
                  buttonText,
                  style: TextStyle(
                    color: config.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static _DialogConfig _getConfig(BuildContext context, DialogType type) {
    switch (type) {
      case DialogType.success:
        return _DialogConfig(
          title: 'Success',
          icon: Icons.check_circle,
          color: context.primaryColor,
        );

      case DialogType.error:
        return _DialogConfig(
          title: 'Error',
          icon: Icons.error,
          color: context.appColors.error,
        );

      case DialogType.warning:
        return _DialogConfig(
          title: 'Warning',
          icon: Icons.warning,
          color: context.appColors.tertiary,
        );

      case DialogType.info:
        return _DialogConfig(
          title: appName,
          icon: Icons.info,
          color: context.appColors.secondary,
        );
    }
  }
}

class _DialogConfig {
  final String title;
  final IconData icon;
  final Color color;

  const _DialogConfig({
    required this.title,
    required this.icon,
    required this.color,
  });
}
