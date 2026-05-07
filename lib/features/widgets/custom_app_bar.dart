import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  
  const CustomAppBar({super.key, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: showBackButton 
        ? IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context))
        : const Padding(
            padding: EdgeInsets.all(10.0),
            child: CircleAvatar(backgroundImage: AssetImage('assets/images/avatar/user.png')),
          ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/favicon.png', width: 22, errorBuilder: (c,e,s) => const Icon(Icons.bolt, color: Color(0xFFFFD400))),
          const SizedBox(width: 8),
          const Text("FONAQO", style: TextStyle(color: Color(0xFFFFD400), fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.black54), onPressed: () {}),
        IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black54), onPressed: () => Navigator.pushNamed(context, '/chat')),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}