import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/category_style.dart';
import '../../core/widgets/amount_field.dart';
import '../../core/widgets/sheet.dart';
import '../../core/widgets/category_color_picker.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import '../../data/providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _type = EntryType.expense;

  @override
  Widget build(BuildContext context) {
    final colors = context.hisab;
    final categories = ref.watch(pickableCategoriesProvider(_type));

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, type: _type),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New category'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: EntryType.expense, label: Text('Expense')),
                  ButtonSegment(value: EntryType.income, label: Text('Income')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = categories[i];
                return Material(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: Color(c.colorValue), borderRadius: BorderRadius.circular(12)),
                      child: Icon(iconForKey(c.iconKey), color: Colors.white, size: 22),
                    ),
                    title: Text(c.name),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () => _showEditor(context, type: _type, existing: c),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditor(BuildContext context, {required String type, Category? existing}) {
    return showAppSheet<void>(
      context,
      builder: (_) => _CategoryEditor(type: type, existing: existing),
    );
  }
}

class _CategoryEditor extends ConsumerStatefulWidget {
  const _CategoryEditor({required this.type, this.existing});

  final String type;
  final Category? existing;

  @override
  ConsumerState<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<_CategoryEditor> {
  late final TextEditingController _name;
  late String _iconKey;
  late int _colorValue;
  bool _moreSymbols = false;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _name = TextEditingController(text: c?.name ?? '');
    _iconKey = c?.iconKey ?? 'dots';
    _colorValue = c?.colorValue ?? categoryPalette.first.toARGB32();
    _moreSymbols = extraCategoryIconKeys.contains(_iconKey);
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty;

  Future<void> _save() async {
    final db = ref.read(databaseProvider);
    final name = _name.text.trim();
    final existing = widget.existing;
    if (existing == null) {
      await db.addCategory(name: name, type: widget.type, iconKey: _iconKey, colorValue: _colorValue);
    } else {
      await db.updateCategory(existing.copyWith(name: name, iconKey: _iconKey, colorValue: _colorValue));
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    final existing = widget.existing!;
    final db = ref.read(databaseProvider);
    final used = await db.entryCountForCategory(existing.id);
    await db.removeCategory(existing.id);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            used == 0 ? 'Deleted ${existing.name}' : 'Hidden ${existing.name}. Your $used old entries keep it.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.hisab;
    final scheme = theme.colorScheme;

    return SheetScaffold(
      footer: FilledButton(onPressed: _canSave ? _save : null, child: const Text('Save')),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.existing == null ? 'New category' : 'Edit category',
                style: theme.textTheme.titleLarge,
              ),
            ),
            if (widget.existing != null)
              IconButton(
                tooltip: 'Delete',
                onPressed: _remove,
                icon: Icon(Icons.delete_outline_rounded, color: colors.spending),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          maxLength: 24,
          autofocus: widget.existing == null,
          textCapitalization: TextCapitalization.words,
          decoration: fieldDecoration(context, label: 'Name'),
        ),
        const SizedBox(height: 16),
        Text('Icon', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in categoryIcons.entries)
              if (_moreSymbols || !extraCategoryIconKeys.contains(entry.key))
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _iconKey = entry.key),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: entry.key == _iconKey ? scheme.primaryContainer : colors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: entry.key == _iconKey ? scheme.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(entry.value, color: scheme.onSurface),
                  ),
                ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _moreSymbols = !_moreSymbols),
            child: Text(_moreSymbols ? 'Fewer symbols' : 'More symbols'),
          ),
        ),
        const SizedBox(height: 16),
        Text('Colour', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in categoryPalette)
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => setState(() => _colorValue = c.toARGB32()),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c.toARGB32() == _colorValue ? scheme.onSurface : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: c.toARGB32() == _colorValue
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                      : null,
                ),
              ),
            Semantics(
              label: 'Choose a custom colour',
              button: true,
              child: InkWell(
                key: const ValueKey('custom-category-colour'),
                customBorder: const CircleBorder(),
                onTap: () async {
                  final color = await showCategoryColorPicker(context, initialColor: Color(_colorValue));
                  if (color != null && mounted) setState(() => _colorValue = color.toARGB32());
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: categoryPalette.any((c) => c.toARGB32() == _colorValue) ? null : Color(_colorValue),
                    gradient: categoryPalette.any((c) => c.toARGB32() == _colorValue)
                        ? const SweepGradient(
                            colors: [
                              Colors.red,
                              Colors.yellow,
                              Colors.green,
                              Colors.cyan,
                              Colors.blue,
                              Colors.purple,
                              Colors.red,
                            ],
                          )
                        : null,
                    border: Border.all(
                      color: categoryPalette.any((c) => c.toARGB32() == _colorValue)
                          ? Colors.transparent
                          : scheme.onSurface,
                      width: 2.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(color: colors.card, shape: BoxShape.circle),
                      child: Icon(Icons.add_rounded, size: 20, color: scheme.onSurface),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
