import 'package:flutter/material.dart';

class ComparisonFilterPanel extends StatelessWidget {
  final VoidCallback? onClose;
  final ValueChanged<int>? onStyleChanged;
  final int initialStyleIndex;

  const ComparisonFilterPanel(
      {Key? key, this.onClose, this.onStyleChanged, this.initialStyleIndex = 0})
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      options: const ['暗黑', '标准', '商务'],
                      initialIndex: initialStyleIndex,
                      onChanged: onStyleChanged,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    _FilterSwitch(title: '是否计算奥莱店'),
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
                      child: const Text('关闭'),
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

class _FilterSwitch extends StatefulWidget {
  final String title;
  const _FilterSwitch({Key? key, required this.title}) : super(key: key);
  @override
  State<_FilterSwitch> createState() => _FilterSwitchState();
}

class _FilterSwitchState extends State<_FilterSwitch> {
  bool value = false;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(widget.title)),
        Switch(
            value: value,
            inactiveThumbColor: Theme.of(context).primaryColor,
            activeThumbColor: Theme.of(context).primaryColor,
            onChanged: (v) => setState(() => value = v)),
      ],
    );
  }
}

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
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            for (int i = 0; i < widget.options.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: ChoiceChip(
                  label: Text(
                    widget.options[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          selected == i ? FontWeight.bold : FontWeight.normal,
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
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: selected == i
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: selected == i ? 4 : 0,
                  pressElevation: 8,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
