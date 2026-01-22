import 'package:flutter/material.dart';

Widget settingItem({
  required String text,
  required VoidCallback action,
  required IconData icon,
  Color? color,
  Widget? trailing,
  String? subtitle,
}) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Container(
      decoration: BoxDecoration(
        color: color ?? Colors.black45,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Icon(icon, color: Colors.white),
    ),
    title: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    subtitle: subtitle != null ? Text(subtitle) : null,
    trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
    onTap: action,
  );
}
