import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/app/nexo_scope.dart';
import '../../../../core/design_system/nexo_colors.dart';
import '../../../../core/design_system/nexo_icons.dart';
import '../../../../core/design_system/nexo_spacing.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../features/finance/models/expense_model.dart';
import '../../../../features/finance/models/sale_model.dart';
import '../../../../shared/components/app/nexo_page_scaffold.dart';
import '../../../../shared/components/cards/nexo_card.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  static const _storageKey = 'nexo.calculator.history';
  String _expression = '';
  String _display = '0';
  final List<_CalculationEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const [];
    setState(() {
      _history
        ..clear()
        ..addAll(raw.map(_CalculationEntry.fromJson));
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      _history.map((item) => item.toJson()).toList(growable: false),
    );
  }

  void _tap(String value) {
    setState(() {
      if (value == 'C') {
        _expression = '';
        _display = '0';
        return;
      }
      if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
        _display = _expression.isEmpty ? '0' : _expression;
        return;
      }
      if (value == '=') {
        final result = _evaluate(_expression);
        _display = _formatResult(result);
        _history.insert(
          0,
          _CalculationEntry(
            expression: _expression,
            result: result,
            createdAt: DateTime.now(),
          ),
        );
        if (_history.length > 20) {
          _history.removeRange(20, _history.length);
        }
        _expression = _display;
        _saveHistory();
        return;
      }
      _expression += value == '×'
          ? '*'
          : value == '÷'
              ? '/'
              : value == ','
                  ? '.'
                  : value;
      _display = _expression;
    });
  }

  Future<void> _saveAsExpense() async {
    final value = MoneyUtils.parseInput(_display);
    if (value <= 0) {
      return;
    }
    final confirmed = await _confirm(
      title: 'Registrar como gasto?',
      message:
          'Isso vai criar uma saida financeira de ${MoneyUtils.format(value)}.',
    );
    if (!confirmed || !mounted) {
      return;
    }
    await NexoScope.of(context).expenses.createExpense(
          title: 'Calculo salvo',
          category: 'Calculadora',
          amount: value,
          scope: ExpenseScope.personal,
          accountName: 'Indefinido',
          expenseDate: DateTime.now().toUtc(),
          notes: 'Criado pela calculadora: $_display',
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resultado transformado em gasto.')),
      );
    }
  }

  Future<void> _saveAsIncome() async {
    final value = MoneyUtils.parseInput(_display);
    if (value <= 0) {
      return;
    }
    final confirmed = await _confirm(
      title: 'Registrar como recebimento?',
      message:
          'Isso vai criar uma entrada financeira de ${MoneyUtils.format(value)}.',
    );
    if (!confirmed || !mounted) {
      return;
    }
    final now = DateTime.now().toUtc();
    await NexoScope.of(context).sales.createSale(
          clientName: 'Recebimento da calculadora',
          serviceName: 'Valor calculado',
          grossAmount: value,
          platform: 'Manual',
          paymentMethod: 'Pix',
          installments: 1,
          saleDate: now,
          expectedDate: now,
          receivedDate: now,
          status: SaleStatus.received,
          platformFee: 0,
          paymentFee: 0,
          hasDanielParticipation: false,
          danielPercent: 0,
          notes: 'Criado pela calculadora: $_display',
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resultado transformado em recebimento.')),
      );
    }
  }

  Future<void> _saveAsGoal() async {
    final value = MoneyUtils.parseInput(_display);
    if (value <= 0) {
      return;
    }
    final confirmed = await _confirm(
      title: 'Criar meta com este valor?',
      message:
          'Isso vai criar uma meta planejada de ${MoneyUtils.format(value)}.',
    );
    if (!confirmed || !mounted) {
      return;
    }
    await NexoScope.of(context).goals.createGoal(
          title: 'Meta calculada',
          targetAmount: value,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resultado transformado em meta.')),
      );
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    const buttons = [
      'C',
      '⌫',
      '%',
      '÷',
      '7',
      '8',
      '9',
      '×',
      '4',
      '5',
      '6',
      '-',
      '1',
      '2',
      '3',
      '+',
      '0',
      ',',
      '=',
    ];

    return NexoPageScaffold(
      title: 'Calculadora',
      subtitle: 'Calcule juros, compras e valores antes de registrar.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NexoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: NexoColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: NexoSpacing.lg),
                GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: NexoSpacing.sm,
                  crossAxisSpacing: NexoSpacing.sm,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: buttons
                      .map(
                        (button) => FilledButton(
                          onPressed: () => _tap(button),
                          child: Text(button),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: NexoSpacing.md),
                Wrap(
                  spacing: NexoSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Clipboard.setData(
                        ClipboardData(text: _display),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copiar resultado'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _saveAsExpense,
                      icon: const Icon(NexoIcons.newExpense, size: 18),
                      label: const Text('Transformar em gasto'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _saveAsIncome,
                      icon: const Icon(NexoIcons.newSale, size: 18),
                      label: const Text('Transformar em recebimento'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _saveAsGoal,
                      icon: const Icon(NexoIcons.goals, size: 18),
                      label: const Text('Transformar em meta'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: NexoSpacing.xl),
          Text('Historico', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: NexoSpacing.md),
          if (_history.isEmpty)
            Text(
              'Sem calculos salvos ainda.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ..._history.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: NexoSpacing.sm),
                child: NexoCard(
                  padding: const EdgeInsets.all(NexoSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.expression} = ${_formatResult(item.result)}',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Excluir historico',
                        onPressed: () {
                          setState(() => _history.remove(item));
                          _saveHistory();
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _evaluate(String expression) {
    final clean = expression.replaceAll('%', '/100');
    final tokens = RegExp(r'(\d+(?:\.\d+)?|[+\-*/])')
        .allMatches(clean)
        .map((match) => match.group(0)!)
        .toList();
    if (tokens.isEmpty) {
      return 0;
    }
    var total = double.tryParse(tokens.first) ?? 0;
    for (var index = 1; index < tokens.length - 1; index += 2) {
      final operator = tokens[index];
      final value = double.tryParse(tokens[index + 1]) ?? 0;
      total = switch (operator) {
        '+' => total + value,
        '-' => total - value,
        '*' => total * value,
        '/' => value == 0 ? total : total / value,
        _ => total,
      };
    }
    return MoneyUtils.roundMoney(total);
  }

  String _formatResult(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }
}

class _CalculationEntry {
  const _CalculationEntry({
    required this.expression,
    required this.result,
    required this.createdAt,
  });

  final String expression;
  final double result;
  final DateTime createdAt;

  String toJson() {
    return jsonEncode({
      'expression': expression,
      'result': result,
      'created_at': createdAt.toIso8601String(),
    });
  }

  factory _CalculationEntry.fromJson(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return _CalculationEntry(
      expression: (json['expression'] as String?) ?? '',
      result: (json['result'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}
