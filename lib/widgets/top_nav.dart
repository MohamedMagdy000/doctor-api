import 'package:flutter/material.dart';
import '../models.dart'; // مهم جداً

class TopNavBar extends StatelessWidget {
  final List<CatParent> parents;
  final String? selectedParent;
  final void Function(String parentName, String? childName) onSelect;

  const TopNavBar({
    super.key,
    required this.parents,
    required this.selectedParent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = parents
        .map((p) => _ParentMenuItem(
              parent: p,
              isActive: selectedParent == p.name,
              onSelect: onSelect,
            ))
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: items),
    );
  }
}

class _ParentMenuItem extends StatelessWidget {
  const _ParentMenuItem({
    required this.parent,
    required this.isActive,
    required this.onSelect,
  });

  final CatParent parent;
  final bool isActive;
  final void Function(String parentName, String? childName) onSelect;

  static const List<Color> _accents = [
    Color(0xFF2C5282),
    Color(0xFF38A169),
    Color(0xFF805AD5),
    Color(0xFFDD6B20),
    Color(0xFF3182CE),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _accents[parent.id % _accents.length];

    if (parent.children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: TextButton.icon(
          onPressed: () => onSelect(parent.name, null),
          icon: Icon(Icons.circle, size: 8, color: color),
          label: Text(
            parent.name,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
              decoration: isActive ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: PopupMenuButton<CatChild>(
        tooltip: parent.name,
        offset: const Offset(0, 12),
        position: PopupMenuPosition.under,
        onSelected: (CatChild child) => onSelect(parent.name, child.name),
        itemBuilder: (_) => parent.children
            .map((c) => PopupMenuItem<CatChild>(
                  value: c,
                  child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                ))
            .toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? color : Colors.black26,
                width: isActive ? 2 : 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                parent.name,
                style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
              ),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
