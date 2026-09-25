import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/controllers/theme_controller.dart';
import 'package:nwt_app/services/support/support_contact_service.dart';
import 'package:nwt_app/utils/whatsapp_utils.dart';
import 'package:nwt_app/services/global_storage.dart';

class WhatsAppFloatingButton extends StatefulWidget {
  const WhatsAppFloatingButton({super.key});

  @override
  State<WhatsAppFloatingButton> createState() => _WhatsAppFloatingButtonState();
}

class _WhatsAppFloatingButtonState extends State<WhatsAppFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isWhatsAppAvailable = false;
  Offset? _position;
  bool _isMinimized = false;
  bool _isDragging = false;
  bool _showGuidance = false;
  Timer? _guidanceTimer;

  @override
  void initState() {
    super.initState();
    _loadState();
    _checkWhatsApp();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Show guidance if not shown before
    final userController = Get.find<UserController>();
    if (!userController.hasShownSupportGuidance) {
      _showGuidance = true;
      _guidanceTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) {
          setState(() => _showGuidance = false);
          userController.setGuidanceShown(true);
        }
      });
    }
  }

  @override
  void dispose() {
    _guidanceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _loadState() {
    final double? dx = StorageService.read('whatsapp_btn_dx');
    final double? dy = StorageService.read('whatsapp_btn_dy');
    if (dx != null && dy != null) {
      _position = Offset(dx, dy);
    }
    _isMinimized = StorageService.read('whatsapp_btn_minimized') ?? false;
  }

  void _saveState() {
    if (_position != null) {
      StorageService.write('whatsapp_btn_dx', _position!.dx);
      StorageService.write('whatsapp_btn_dy', _position!.dy);
    }
    StorageService.write('whatsapp_btn_minimized', _isMinimized);
  }

  Future<void> _checkWhatsApp() async {
    final available = await WhatsAppUtils.isWhatsAppInstalled();
    if (mounted) {
      setState(() {
        _isWhatsAppAvailable = available;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserController>(
      builder: (userController) {
        if (userController.isSupportButtonHidden)
          return const SizedBox.shrink();

        final size = MediaQuery.of(context).size;
        final padding = MediaQuery.of(context).padding;

        // Default position at bottom right if not set
        _position ??= Offset(
          size.width - 80,
          size.height - padding.bottom - 160,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (_showGuidance && !userController.hasShownSupportGuidance)
              Positioned(
                left: (_position!.dx - 40).clamp(20.0, size.width - 160),
                top: _position!.dy - 55,
                child: _buildGuidanceTooltip(userController),
              ),
            Positioned(
              left: _position!.dx,
              top: _position!.dy,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onPanStart: (_) => setState(() => _isDragging = true),
                    onPanUpdate: (details) {
                      setState(() {
                        _position = Offset(
                          (_position!.dx + details.delta.dx).clamp(
                            0.0,
                            size.width - (_isMinimized ? 40 : 60),
                          ),
                          (_position!.dy + details.delta.dy).clamp(
                            padding.top,
                            size.height -
                                padding.bottom -
                                (_isMinimized ? 40 : 60),
                          ),
                        );
                      });
                    },
                    onPanEnd: (_) {
                      setState(() => _isDragging = false);
                      _saveState();
                    },
                    onDoubleTap: () {
                      setState(() {
                        _isMinimized = !_isMinimized;
                        if (_isMinimized && _showGuidance) {
                          _showGuidance = false;
                          userController.setGuidanceShown(true);
                        }
                      });
                      _saveState();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isMinimized ? 40 : 56,
                      height: _isMinimized ? 40 : 56,
                      child: ScaleTransition(
                        scale:
                            _isMinimized
                                ? const AlwaysStoppedAnimation(1.0)
                                : _animation,
                        child: GetBuilder<ThemeController>(
                          builder: (themeController) {
                            final isDark = themeController.isDarkMode;

                            return FloatingActionButton(
                              heroTag: 'whatsapp_fab',
                              mini: _isMinimized,
                              onPressed: () async {
                                if (_isDragging) return;
                                debugPrint(
                                  'WhatsAppFloatingButton: FAB pressed',
                                );
                                await SupportContactService.contactSupport(
                                  context: SupportContext.generalSupport,
                                );
                              },
                              backgroundColor:
                                  isDark
                                      ? Colors.grey[900]
                                      : const Color(0xFF25D366),
                              elevation: _isDragging ? 12 : 8,
                              shape: const CircleBorder(),
                              child:
                                  _isWhatsAppAvailable
                                      ? Image.asset(
                                        'assets/svgs/dashboard/1881161.webp',
                                        color: Colors.white,
                                        width: _isMinimized ? 20 : 28,
                                        height: _isMinimized ? 20 : 28,
                                      )
                                      : Icon(
                                        Icons.mail_outline,
                                        color: Colors.white,
                                        size: _isMinimized ? 20 : 28,
                                      ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (!_isDragging)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: GestureDetector(
                        onTap: () {
                          userController.setSupportButtonHidden(true);
                          Get.snackbar(
                            'Support Button Hidden',
                            'You can re-enable it in your Profile settings.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.black.withOpacity(0.7),
                            colorText: Colors.white,
                            duration: const Duration(seconds: 2),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuidanceTooltip(UserController userController) {
    return GestureDetector(
      onTap: () {
        setState(() => _showGuidance = false);
        userController.setGuidanceShown(true);
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Double-tap to\nminimise',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Container(
                width: 0,
                height: 0,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      width: 6,
                      color: Colors.blue.withOpacity(0.9),
                    ),
                    left: const BorderSide(width: 6, color: Colors.transparent),
                    right: const BorderSide(
                      width: 6,
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
