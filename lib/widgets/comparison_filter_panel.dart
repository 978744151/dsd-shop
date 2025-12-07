import 'package:flutter/material.dart';

class ComparisonFilterPanel extends StatelessWidget {
  final VoidCallback? onClose;
  final ValueChanged<int>? onStyleChanged;
  final int initialStyleIndex;
<<<<<<< HEAD
  // isola 表示是否计算奥莱店：true=计算，false=不计算
  final ValueChanged<bool>? onIsolaChanged;
  final bool initialIsola;
  final ValueChanged<double>? onRowHeightChanged;
  final double initialRowHeight;
  final ValueChanged<double>? onColumnWidthChanged;
  final double initialColumnWidth;
  final bool initialUseChineseName;
  final ValueChanged<bool>? onUseChineseNameChanged;
  final ValueChanged<double>? onFirstColumnWidthChanged;
  final double initialFirstColumnWidth;
  final bool initialIsCategory;
  final ValueChanged<bool>? onIsCategoryChanged;
  final List<Map<String, dynamic>> categoryOptions;
  final List<String> selectedCategoryNames;
  final ValueChanged<List<String>>? onCategorySelectionChanged;

  const ComparisonFilterPanel(
      {Key? key,
      this.onClose,
      this.onStyleChanged,
      this.initialStyleIndex = 0,
      this.onRowHeightChanged,
      this.initialRowHeight = 60,
      this.onColumnWidthChanged,
      this.initialColumnWidth = 110,
      this.initialUseChineseName = false,
      this.onUseChineseNameChanged,
      this.onFirstColumnWidthChanged,
      this.initialFirstColumnWidth = 140,
      this.initialIsCategory = false,
      this.onIsCategoryChanged,
      this.categoryOptions = const [],
      this.selectedCategoryNames = const [],
      this.onCategorySelectionChanged,
      this.onIsolaChanged,
      this.initialIsola = true})
=======

  const ComparisonFilterPanel(
      {Key? key, this.onClose, this.onStyleChanged, this.initialStyleIndex = 0})
>>>>>>> b48e7f0bd2e4176879c6662554d3236da64c22e0
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double panelWidth = 320;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: panelWidth,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(-4, 0),
            ),
          ],
          border: const Border(
            left: BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
<<<<<<< HEAD
              // padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
=======
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
>>>>>>> b48e7f0bd2e4176879c6662554d3236da64c22e0
              decoration: const BoxDecoration(
                  // color: Color(0xFF1E3A8A),
                  ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                  )
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilterRadioGroup(
                      title: '风格',
<<<<<<< HEAD
                      options: const ['暗黑', '标准', '商务', '深色'],
=======
                      options: const ['暗黑', '标准', '商务'],
>>>>>>> b48e7f0bd2e4176879c6662554d3236da64c22e0
                      initialIndex: initialStyleIndex,
                      onChanged: onStyleChanged,
                    ),
                    const SizedBox(height: 16),
<<<<<<< HEAD
                    _FilterSlider(
                      title: '行高',
                      min: 40,
                      max: 100,
                      initialValue: initialRowHeight,
                      onChanged: onRowHeightChanged,
                    ),
                    const SizedBox(height: 16),
                    _FilterSlider(
                      title: '列宽',
                      min: 80,
                      max: 180,
                      initialValue: initialColumnWidth,
                      onChanged: onColumnWidthChanged,
                    ),
                    const SizedBox(height: 16),
                    _FilterSlider(
                      title: '首列宽度',
                      min: 100,
                      max: 240,
                      initialValue: initialFirstColumnWidth,
                      onChanged: onFirstColumnWidthChanged,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    if (categoryOptions.isNotEmpty) ...[
                      const Text(
                        '分类',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _CategorySelector(
                        options: categoryOptions,
                        initialSelected: selectedCategoryNames,
                        onChanged: onCategorySelectionChanged,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _IsolaSwitch(
                      title: '分类排序',
                      initialValue: initialIsCategory,
                      onChanged: onIsCategoryChanged,
                    ),
                     const SizedBox(height: 16),
                    _IsolaSwitch(
                      title: '使用品牌中文名',
                      initialValue: initialUseChineseName,
                      onChanged: onUseChineseNameChanged,
                    ),
                    const SizedBox(height: 16),
                    _IsolaSwitch(
                      title: '是否计算奥莱店',
                      initialValue: initialIsola,
                      onChanged: onIsolaChanged,
                    ),
=======
                    const Divider(),
                    const SizedBox(height: 16),
                    // _FilterSwitch(title: '是否计算奥莱店'),
>>>>>>> b48e7f0bd2e4176879c6662554d3236da64c22e0
                  ],
                ),
              ),
            ),

            // Footer actions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          side: BorderSide(color: Colors.white)),
                      onPressed: onClose,
                      child: const Text('确定'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

<<<<<<< HEAD
// class _FilterSwitch extends StatefulWidget {
//   final String title;
//   const _FilterSwitch({Key? key, required this.title}) : super(key: key);
//   @override
//   State<_FilterSwitch> createState() => _FilterSwitchState();
// }

class _IsolaSwitch extends StatefulWidget {
  final String title;
  final bool initialValue;
  final ValueChanged<bool>? onChanged;
  const _IsolaSwitch({
    Key? key,
    required this.title,
    this.initialValue = true,
    this.onChanged,
  }) : super(key: key);

  @override
  State<_IsolaSwitch> createState() => _IsolaSwitchState();
}

class _IsolaSwitchState extends State<_IsolaSwitch> {
  late bool value;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue; // 默认计算奥莱店（true）
  }

=======
class _FilterSwitch extends StatefulWidget {
  final String title;
  const _FilterSwitch({Key? key, required this.title}) : super(key: key);
  @override
  State<_FilterSwitch> createState() => _FilterSwitchState();
}

class _FilterSwitchState extends State<_FilterSwitch> {
  bool value = false;
>>>>>>> b48e7f0bd2e4176879c6662554d3236da64c22e0
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(widget.title)),
        Switch(
<<<<<<< HEAD
          value: value,
          inactiveThumbColor: Theme.of(context).primaryColor,
          activeColor: Theme.of(context).primaryColor,
          onChanged: (v) {
            setState(() => value = v);
            widget.onChanged?.call(v); // 以 isola 参数传递 true/false
          },
        ),
=======
            value: value,
            inactiveThumbColor: Theme.of(context).primaryColor,
            // activeThumbColor: Theme.of(context).primaryColor,
            onChanged: (v) => setState(() => value = v)),
>>>>>>> b48e7f0bd2e4176879c6662554d3236da64c22e0
      ],
    );
  }
}

<<<<<<< HEAD
class _CategorySelector extends StatefulWidget {
  final List<Map<String, dynamic>> options;
  final List<String> initialSelected;
  final ValueChanged<List<String>>? onChanged;
  const _CategorySelector({
    Key? key,
    required this.options,
    this.initialSelected = const [],
    this.onChanged,
  }) : super(key: key);

  @override
  State<_CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<_CategorySelector> {
  late List<String> selected;

  @override
  void initState() {
    super.initState();
    selected = List<String>.from(widget.initialSelected);
  }

  void _toggle(String name) {
    setState(() {
      if (selected.contains(name)) {
        selected.remove(name);
      } else {
        selected.add(name);
      }
    });
    widget.onChanged?.call(List<String>.from(selected));
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: widget.options.map((opt) {
        final String name = opt['name']?.toString() ?? '未命名';
        final bool isSelected = selected.contains(name);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: ChoiceChip(
            label: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => _toggle(name),
            backgroundColor: Colors.white,
            selectedColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            elevation: isSelected ? 4 : 0,
            pressElevation: 8,
          ),
        );
      }).toList(),
    );
  }
}

=======
>>>>>>> b48e7f0bd2e4176879c6662554d3236da64c22e0
class _FilterRadioGroup extends StatefulWidget {
  final String title;
  final List<String> options;
  final ValueChanged<int>? onChanged;
  final int initialIndex;
  const _FilterRadioGroup(
      {Key? key,
      required this.title,
      required this.options,
      this.onChanged,
      this.initialIndex = 0})
      : super(key: key);
  @override
  State<_FilterRadioGroup> createState() => _FilterRadioGroupState();
}

class _FilterRadioGroupState extends State<_FilterRadioGroup> {
  late int selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title),
<<<<<<< HEAD
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
=======
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
>>>>>>> b48e7f0bd2e4176879c6662554d3236da64c22e0
          children: [
            for (int i = 0; i < widget.options.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: ChoiceChip(
                  label: Text(
                    widget.options[i],
                    style: TextStyle(
<<<<<<< HEAD
                      fontSize: 12,
                      fontWeight:
                          selected == i ? FontWeight.w600 : FontWeight.w400,
=======
                      fontSize: 14,
                      fontWeight:
                          selected == i ? FontWeight.bold : FontWeight.normal,
>>>>>>> b48e7f0bd2e4176879c6662554d3236da64c22e0
                      color: selected == i ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: selected == i,
                  onSelected: (_) {
                    setState(() => selected = i);
                    widget.onChanged?.call(i);
                  },
                  backgroundColor: Colors.white,
                  selectedColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
<<<<<<< HEAD
                    borderRadius: BorderRadius.circular(16),
=======
                    borderRadius: BorderRadius.circular(20),
>>>>>>> b48e7f0bd2e4176879c6662554d3236da64c22e0
                    side: BorderSide(
                      color: selected == i
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
<<<<<<< HEAD
                      width: 1.0,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  elevation: 0,
                  pressElevation: 0,
=======
                      width: 1.5,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: selected == i ? 4 : 0,
                  pressElevation: 8,
>>>>>>> b48e7f0bd2e4176879c6662554d3236da64c22e0
                ),
              ),
          ],
        ),
      ],
    );
  }
<<<<<<< HEAD
}

class _FilterSlider extends StatefulWidget {
  final String title;
  final double min;
  final double max;
  final double initialValue;
  final ValueChanged<double>? onChanged;
  const _FilterSlider({
    Key? key,
    required this.title,
    required this.min,
    required this.max,
    required this.initialValue,
    this.onChanged,
  }) : super(key: key);

  @override
  State<_FilterSlider> createState() => _FilterSliderState();
}

class _FilterSliderState extends State<_FilterSlider> {
  late double value;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue.clamp(widget.min, widget.max);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title),
            Text('${value.toStringAsFixed(0)}'),
          ],
        ),
        Slider(
          min: widget.min,
          max: widget.max,
          divisions: (widget.max - widget.min).round(),
          value: value,
          label: '${value.toStringAsFixed(0)}',
          activeColor: Theme.of(context).primaryColor,
          onChanged: (v) {
            setState(() => value = v);
            widget.onChanged?.call(v);
          },
        ),
      ],
    );
  }
}
=======
}
>>>>>>> b48e7f0bd2e4176879c6662554d3236da64c22e0
