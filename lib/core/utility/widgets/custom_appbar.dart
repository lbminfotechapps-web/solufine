import 'package:flutter/material.dart';

import 'package:solufine/core/theme/theme_picker_sheet.dart';
import 'package:solufine/core/theme/typography/app_typography_extension.dart';
import 'package:solufine/core/utility/screen_shot.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;

  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  final String? userName;
  final String? initials;

  // Login / Logout
  final bool showLogin;
  final bool showLogout;
  final VoidCallback? onLoginTap;
  final VoidCallback? onLogOutTap;

  // Generic right-side action
  final IconData? actionIcon;
  final VoidCallback? onActionIconTap;

  // Back button
  final bool showBackButton;
  final VoidCallback? onBackTap;

  // Optional widgets
  final Widget? leading;
  final Widget? action;

  // Appearance
  final Color? backgroundColor;
  final double toolbarHeight;

  // Theme selection
  final bool showThemeButton;

  const CustomAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    this.userName,
    this.initials,
    this.showLogin = false,
    this.showLogout = false,
    this.onLoginTap,
    this.onLogOutTap,
    this.actionIcon,
    this.onActionIconTap,
    this.showBackButton = false,
    this.onBackTap,
    this.leading,
    this.action,
    this.backgroundColor,
    this.toolbarHeight = 60,
    this.showThemeButton = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final appBarTheme = theme.appBarTheme;

    // ==========================================================
    // DYNAMIC APPBAR COLORS
    // ==========================================================

    final Color effectiveBackground =
        backgroundColor ?? appBarTheme.backgroundColor ?? colors.surface;

    final bool isDarkAppBar =
        ThemeData.estimateBrightnessForColor(effectiveBackground) ==
        Brightness.dark;

    // Respect the palette's AppBar foreground for normal themes.
    // If a custom background was provided, calculate contrast.
    final Color foreground = backgroundColor == null
        ? (appBarTheme.foregroundColor ??
              (isDarkAppBar ? Colors.white : Colors.black))
        : (isDarkAppBar ? Colors.white : Colors.black);

    final Color primaryColor = colors.primary;
    final Color onPrimaryColor = colors.onPrimary;

    // ==========================================================
    // ICON COLORS
    // ==========================================================

    final Color iconBackground = foreground.withValues(alpha: 0.12);

    // Palette icon should contrast with the actual AppBar.
    final Color paletteIconColor = isDarkAppBar ? Colors.white : primaryColor;

    final Color paletteIconBackground = isDarkAppBar
        ? Colors.white.withValues(alpha: 0.16)
        : primaryColor.withValues(alpha: 0.12);

    // ==========================================================
    // PROFILE COLORS
    // ==========================================================

    final Color profileBackground = foreground.withValues(alpha: 0.12);

    final Color profileBorder = foreground.withValues(alpha: 0.25);

    // ==========================================================
    // LOGIN BUTTON COLORS
    // ==========================================================

    // If AppBar and primary are similar, use contrasting
    // palette foreground with a translucent background.
    final bool primaryMatchesAppBar = effectiveBackground == primaryColor;

    final Color loginBackground = primaryMatchesAppBar
        ? foreground.withValues(alpha: 0.15)
        : primaryColor;

    final Color loginForeground = primaryMatchesAppBar
        ? foreground
        : onPrimaryColor;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: effectiveBackground,
      foregroundColor: foreground,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      toolbarHeight: toolbarHeight,
      titleSpacing: 12,
      shadowColor: colors.shadow.withValues(alpha: 0.12),

      shape: Border(
        bottom: BorderSide(
          color: foreground.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),

      title: Row(
        children: [
          // ====================================================
          // LEADING / BACK BUTTON
          // ====================================================
          if (leading != null)
            leading!
          else if (showBackButton)
            IconButton(
              tooltip: 'Back',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
              onPressed:
                  onBackTap ??
                  () {
                    Navigator.maybePop(context);
                  },
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: foreground,
              ),
            ),

          if (leading != null || showBackButton) const SizedBox(width: 8),

          // ====================================================
          // PROFILE INITIALS
          // ====================================================
          if (initials != null) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: profileBackground,
                border: Border.all(color: profileBorder),
              ),
              alignment: Alignment.center,
              child: Text(
                initials!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.appTextStyles.headingMedium.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // ====================================================
          // TITLE / SUBTITLE / USERNAME
          // ====================================================
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.appTextStyles.appBarTitle
                        .copyWith(color: foreground)
                        .merge(titleStyle),
                  ),

                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.appTextStyles.appBarSubtitle
                        .copyWith(color: foreground.withValues(alpha: 0.80))
                        .merge(subtitleStyle),
                  ),
                ],

                if (userName != null)
                  Text(
                    userName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.appTextStyles.appBarTitle
                        .copyWith(color: foreground)
                        .merge(titleStyle),
                  ),
              ],
            ),
          ),

          // ====================================================
          // CUSTOM ACTION WIDGET
          // ====================================================
          if (action != null) ...[const SizedBox(width: 4), action!],

          // ====================================================
          // GENERIC ACTION ICON
          // ====================================================
          if (actionIcon != null && onActionIconTap != null) ...[
            const SizedBox(width: 4),
            _AppBarCircleButton(
              icon: actionIcon!,
              tooltip: 'Action',
              backgroundColor: iconBackground,
              foregroundColor: foreground,
              onTap: onActionIconTap!,
            ),
          ],

          // ====================================================
          // LOGIN BUTTON
          // ====================================================
          if (showLogin) ...[
            const SizedBox(width: 4),
            Material(
              color: loginBackground,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onLoginTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.login_rounded,
                        size: 17,
                        color: loginForeground,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Login',
                        style: context.appTextStyles.buttonSmall.copyWith(
                          color: loginForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],



           
const SizedBox(width: 4),

Builder(
  builder: (buttonContext) {
    return _AppBarCircleButton(
      icon: Icons.screenshot_rounded,
      tooltip: 'Take Screenshot',
      backgroundColor: iconBackground,
      foregroundColor: foreground,
      onTap: () async {
        await NextScreen.captureFromContext(buttonContext);
      },
    );
  },
),


          // ====================================================
          // LOGOUT BUTTON
          // ====================================================
          if (showLogout) ...[
            const SizedBox(width: 4),
            _AppBarCircleButton(
              icon: Icons.logout_outlined,
              tooltip: 'Logout',
              backgroundColor: iconBackground,
              foregroundColor: foreground,
              onTap: onLogOutTap ?? () {},
            ),
          ],

          // ====================================================
          // THEME CHANGE BUTTON
          // ====================================================
          if (showThemeButton) ...[
            const SizedBox(width: 4),
            _AppBarCircleButton(
              icon: Icons.palette_outlined,
              tooltip: 'Change Theme',
              backgroundColor: paletteIconBackground,
              foregroundColor: paletteIconColor,
              onTap: () {
                ThemePickerSheet.show(context);
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// REUSABLE CIRCULAR ICON BUTTON
// ============================================================

class _AppBarCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _AppBarCircleButton({
    required this.icon,
    required this.tooltip,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Center(child: Icon(icon, size: 20, color: foregroundColor)),
          ),
        ),
      ),
    );
  }
}
