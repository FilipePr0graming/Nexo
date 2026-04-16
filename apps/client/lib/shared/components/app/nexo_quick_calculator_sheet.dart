import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_colors.dart';
import '../../../core/design_system/nexo_radius.dart';
import '../../../core/design_system/nexo_spacing.dart';
import '../actions/nexo_icon_button.dart';
import '../cards/nexo_card.dart';

class NexoQuickCalculatorSheet extends StatefulWidget {
  const NexoQuickCalculatorSheet({super.key});

  @override
  State<NexoQuickCalculatorSheet> createState() => _NexoQuickCalculatorSheetState();
}

class _NexoQuickCalculatorSheetState extends State<NexoQuickCalculatorSheet> {
  String _expression = '';
  String? _preview;
  final List<_CalculatorHistoryItem> _history = [];

  void _append(String value) {
    setState(() {
      _expression += value;
      _preview = _tryEvaluate(_expression);
    });
  }

  void _clear() {
    setState(() {
      _expression = '';
      _preview = null;
    });
  }

  void _backspace() {
    if (_expression.isEmpty) {
      return;
    }

    setState(() {
      _expression = _expression.substring(0, _expression.length - 1);
      _preview = _expression.isEmpty ? null : _tryEvaluate(_expression);
    });
  }

  void _submit() {
    final result = _tryEvaluate(_expression);
    if (result == null) {
      return;
    }

    setState(() {
      _history.insert(
        0,
        _CalculatorHistoryItem(expression: _expression, result: result),
      );
      _expression = result;
      _preview = null;
    });
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
    });
  }

  static String? _tryEvaluate(String raw) {
    final expression = raw.trim();
    if (expression.isEmpty) {
      return null;
    }

    try {
      final value = _ExpressionEvaluator.evaluate(expression);
      if (value.isNaN || value.isInfinite) {
        return null;
      }

      return _formatNumber(value);
    } catch (_) {
      return null;
    }
  }

  static String _formatNumber(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    var text = value.toStringAsFixed(6);
    text = text.replaceAll(RegExp(r'0+$'), '');
    text = text.replaceAll(RegExp(r'\\.$'), '');
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 520;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NexoSpacing.md,
        NexoSpacing.sm,
        NexoSpacing.md,
        NexoSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Calculadora',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (_history.isNotEmpty)
                NexoIconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Limpar historico',
                  onPressed: _clearHistory,
                ),
            ],
          ),
          const SizedBox(height: NexoSpacing.md),
          NexoCard(
            padding: const EdgeInsets.all(NexoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _expression.isEmpty ? '0' : _expression,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          letterSpacing: -0.2,
                        ),
                  ),
                ),
                if (_preview != null) ...[
                  const SizedBox(height: NexoSpacing.xs),
                  Text(
                    _preview!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: NexoColors.inkLow,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: NexoSpacing.md),
          Flexible(
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _CalculatorPad(onAppend: _append, onBackspace: _backspace, onClear: _clear, onSubmit: _submit)),
                      const SizedBox(width: NexoSpacing.md),
                      SizedBox(width: 240, child: _CalculatorHistory(items: _history)),
                    ],
                  )
                : Column(
                    children: [
                      _CalculatorPad(onAppend: _append, onBackspace: _backspace, onClear: _clear, onSubmit: _submit),
                      const SizedBox(height: NexoSpacing.md),
                      _CalculatorHistory(items: _history),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CalculatorPad extends StatelessWidget {
  const _CalculatorPad({
    required this.onAppend,
    required this.onBackspace,
    required this.onClear,
    required this.onSubmit,
  });

  final ValueChanged<String> onAppend;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final buttons = <_CalcButtonSpec>[
      const _CalcButtonSpec('C', kind: _CalcButtonKind.utility),
      const _CalcButtonSpec('(', kind: _CalcButtonKind.utility),
      const _CalcButtonSpec(')', kind: _CalcButtonKind.utility),
      const _CalcButtonSpec('÷', kind: _CalcButtonKind.operator),
      const _CalcButtonSpec('7'),
      const _CalcButtonSpec('8'),
      const _CalcButtonSpec('9'),
      const _CalcButtonSpec('×', kind: _CalcButtonKind.operator),
      const _CalcButtonSpec('4'),
      const _CalcButtonSpec('5'),
      const _CalcButtonSpec('6'),
      const _CalcButtonSpec('-', kind: _CalcButtonKind.operator),
      const _CalcButtonSpec('1'),
      const _CalcButtonSpec('2'),
      const _CalcButtonSpec('3'),
      const _CalcButtonSpec('+', kind: _CalcButtonKind.operator),
      const _CalcButtonSpec('⌫', kind: _CalcButtonKind.utility),
      const _CalcButtonSpec('0'),
      const _CalcButtonSpec('.', kind: _CalcButtonKind.utility),
      const _CalcButtonSpec('=', kind: _CalcButtonKind.submit),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = (constraints.maxWidth - (NexoSpacing.sm * 3)) / 4;

        return Wrap(
          spacing: NexoSpacing.sm,
          runSpacing: NexoSpacing.sm,
          children: buttons.map((spec) {
            return SizedBox(
              width: cellSize,
              height: 52,
              child: _CalcButton(
                label: spec.label,
                kind: spec.kind,
                onTap: () {
                  switch (spec.label) {
                    case 'C':
                      onClear();
                      break;
                    case '⌫':
                      onBackspace();
                      break;
                    case '=':
                      onSubmit();
                      break;
                    default:
                      onAppend(spec.label);
                  }
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CalcButton extends StatelessWidget {
  const _CalcButton({
    required this.label,
    required this.kind,
    required this.onTap,
  });

  final String label;
  final _CalcButtonKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    final FontWeight weight;

    switch (kind) {
      case _CalcButtonKind.operator:
        background = NexoColors.surfaceElevated;
        foreground = NexoColors.inkHigh;
        weight = FontWeight.w700;
        break;
      case _CalcButtonKind.submit:
        background = NexoColors.accent;
        foreground = Colors.black;
        weight = FontWeight.w800;
        break;
      case _CalcButtonKind.utility:
        background = NexoColors.surface;
        foreground = NexoColors.ink;
        weight = FontWeight.w700;
        break;
      case _CalcButtonKind.number:
        background = NexoColors.surface;
        foreground = NexoColors.ink;
        weight = FontWeight.w600;
        break;
    }

    return Material(
      color: background.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NexoRadius.md),
        side: BorderSide(color: NexoColors.border.withValues(alpha: 0.8)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(NexoRadius.md),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: weight,
                ),
          ),
        ),
      ),
    );
  }
}

class _CalculatorHistory extends StatelessWidget {
  const _CalculatorHistory({required this.items});

  final List<_CalculatorHistoryItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return NexoCard(
        padding: const EdgeInsets.all(NexoSpacing.md),
        child: Text(
          'Sem historico ainda.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NexoColors.inkLow,
              ),
        ),
      );
    }

    return NexoCard(
      padding: const EdgeInsets.all(NexoSpacing.md),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(color: NexoColors.divider.withValues(alpha: 0.7)),
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.expression,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: NexoColors.inkLow,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.result,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum _CalcButtonKind {
  number,
  operator,
  utility,
  submit,
}

class _CalcButtonSpec {
  const _CalcButtonSpec(this.label, {this.kind = _CalcButtonKind.number});

  final String label;
  final _CalcButtonKind kind;
}

class _CalculatorHistoryItem {
  const _CalculatorHistoryItem({required this.expression, required this.result});

  final String expression;
  final String result;
}

abstract final class _ExpressionEvaluator {
  static double evaluate(String expression) {
    final tokens = _tokenize(expression);
    final rpn = _toRpn(tokens);
    return _evalRpn(rpn);
  }

  static List<String> _tokenize(String input) {
    final cleaned = input
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll(' ', '');

    final tokens = <String>[];
    final buffer = StringBuffer();

    bool flushNumber() {
      if (buffer.isEmpty) {
        return false;
      }
      tokens.add(buffer.toString());
      buffer.clear();
      return true;
    }

    for (var i = 0; i < cleaned.length; i++) {
      final c = cleaned[i];

      if (RegExp(r'[0-9.]').hasMatch(c)) {
        buffer.write(c);
        continue;
      }

      flushNumber();

      if ('+-*/()'.contains(c)) {
        tokens.add(c);
        continue;
      }

      throw FormatException('Invalid character');
    }

    flushNumber();
    return tokens;
  }

  static int _precedence(String op) {
    return switch (op) {
      '+' || '-' => 1,
      '*' || '/' => 2,
      _ => 0,
    };
  }

  static bool _isOperator(String token) {
    return token == '+' || token == '-' || token == '*' || token == '/';
  }

  static List<String> _toRpn(List<String> tokens) {
    final output = <String>[];
    final ops = <String>[];

    for (var i = 0; i < tokens.length; i++) {
      var token = tokens[i];

      if (_isOperator(token)) {
        if (token == '-' && (i == 0 || tokens[i - 1] == '(' || _isOperator(tokens[i - 1]))) {
          output.add('0');
        }

        while (ops.isNotEmpty && _isOperator(ops.last) && _precedence(ops.last) >= _precedence(token)) {
          output.add(ops.removeLast());
        }
        ops.add(token);
        continue;
      }

      if (token == '(') {
        ops.add(token);
        continue;
      }

      if (token == ')') {
        while (ops.isNotEmpty && ops.last != '(') {
          output.add(ops.removeLast());
        }
        if (ops.isEmpty) {
          throw FormatException('Mismatched parentheses');
        }
        ops.removeLast();
        continue;
      }

      output.add(token);
    }

    while (ops.isNotEmpty) {
      final op = ops.removeLast();
      if (op == '(') {
        throw FormatException('Mismatched parentheses');
      }
      output.add(op);
    }

    return output;
  }

  static double _evalRpn(List<String> rpn) {
    final stack = <double>[];

    for (final token in rpn) {
      if (_isOperator(token)) {
        if (stack.length < 2) {
          throw FormatException('Invalid expression');
        }
        final b = stack.removeLast();
        final a = stack.removeLast();
        final result = switch (token) {
          '+' => a + b,
          '-' => a - b,
          '*' => a * b,
          '/' => a / b,
          _ => throw FormatException('Unknown operator'),
        };
        stack.add(result);
        continue;
      }

      stack.add(double.parse(token));
    }

    if (stack.length != 1) {
      throw FormatException('Invalid expression');
    }

    return stack.single;
  }
}
