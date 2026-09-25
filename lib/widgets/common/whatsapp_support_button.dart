import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/services/support/support_contact_service.dart';
import 'package:nwt_app/utils/whatsapp_utils.dart';

class WhatsAppSupportButton extends StatefulWidget {
  final Color? color;
  final double size;

  const WhatsAppSupportButton({super.key, this.color, this.size = 24.0});

  @override
  State<WhatsAppSupportButton> createState() => _WhatsAppSupportButtonState();
}

class _WhatsAppSupportButtonState extends State<WhatsAppSupportButton> {
  bool _isWhatsAppAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkWhatsApp();
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
        if (userController.isSupportButtonHidden) {
          return const SizedBox.shrink();
        }

        Widget iconWidget =
            _isWhatsAppAvailable
                ? Image.asset(
                  'assets/svgs/dashboard/1881161.webp',
                  color: widget.color ?? Colors.white,
                  width: widget.size,
                  height: widget.size,
                )
                : Icon(
                  Icons.mail_outline,
                  color: widget.color ?? Colors.white,
                  size: widget.size,
                );

        return InkWell(
          onTap: () async {
            await SupportContactService.contactSupport(
              context: SupportContext.generalSupport,
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: iconWidget,
                ),
                const SizedBox(height: 2),
                Text(
                  "Support",
                  style: TextStyle(
                    color: widget.color ?? Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:nwt_app/controllers/user_controller.dart';
// import 'package:nwt_app/services/support/support_contact_service.dart';
// import 'package:nwt_app/utils/whatsapp_utils.dart';

// class WhatsAppSupportButton extends StatefulWidget {
//   final Color? color;
//   final double size;

//   const WhatsAppSupportButton({
//     super.key,
//     this.color,
//     this.size = 24.0,
//   });

//   @override
//   State<WhatsAppSupportButton> createState() => _WhatsAppSupportButtonState();
// }

// class _WhatsAppSupportButtonState extends State<WhatsAppSupportButton> {
//   bool _isWhatsAppAvailable = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkWhatsApp();
//   }

//   Future<void> _checkWhatsApp() async {
//     final available = await WhatsAppUtils.isWhatsAppInstalled();
//     if (mounted) {
//       setState(() {
//         _isWhatsAppAvailable = available;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<UserController>(
//       builder: (userController) {
//         if (userController.isSupportButtonHidden) {
//           return const SizedBox.shrink();
//         }

//         return IconButton(
//           onPressed: () async {
//             await SupportContactService.contactSupport(
//               context: SupportContext.generalSupport,
//             );
//           },
//           icon: _isWhatsAppAvailable
//               ? Image.asset(
//                   'assets/svgs/dashboard/1881161.webp',
//                   color: widget.color ?? Colors.white,
//                   width: widget.size,
//                   height: widget.size,
//                 )
//               : Icon(
//                   Icons.mail_outline,
//                   color: widget.color ?? Colors.white,
//                   size: widget.size,
//                 ),
//           tooltip: 'Support',
//         );
//       },
//     );
//   }
// }
