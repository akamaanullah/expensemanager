import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalculatorScreen extends StatefulWidget {
  final String? initialValue;
  
  const CalculatorScreen({super.key, this.initialValue});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _expression = '';
  double _result = 0;
  String _operation = '';
  bool _shouldReset = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _display = widget.initialValue!;
      _result = double.tryParse(widget.initialValue!) ?? 0;
    }
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_shouldReset) {
        _display = '0';
        _shouldReset = false;
      }
      
      if (_display == '0') {
        _display = number;
      } else {
        _display += number;
      }
    });
  }

  void _onOperationPressed(String operation) {
    setState(() {
      if (_operation.isNotEmpty && !_shouldReset) {
        _calculate();
      }
      
      _result = double.tryParse(_display) ?? 0;
      _operation = operation;
      _expression = '$_display $operation';
      _shouldReset = true;
    });
  }

  void _calculate() {
    if (_operation.isEmpty) return;
    
    final currentValue = double.tryParse(_display) ?? 0;
    double newResult = 0;

    switch (_operation) {
      case '+':
        newResult = _result + currentValue;
        break;
      case '-':
        newResult = _result - currentValue;
        break;
      case '×':
        newResult = _result * currentValue;
        break;
      case '÷':
        if (currentValue != 0) {
          newResult = _result / currentValue;
        } else {
          _showError('Cannot divide by zero');
          return;
        }
        break;
    }

    setState(() {
      _result = newResult;
      _display = _formatNumber(newResult);
      _operation = '';
      _expression = '';
      _shouldReset = true;
    });
  }

  void _onEqualsPressed() {
    if (_operation.isNotEmpty) {
      _calculate();
    }
  }

  void _onClearPressed() {
    setState(() {
      _display = '0';
      _result = 0;
      _operation = '';
      _expression = '';
      _shouldReset = false;
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
    });
  }

  void _onDecimalPressed() {
    setState(() {
      if (_shouldReset) {
        _display = '0.';
        _shouldReset = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatNumber(double number) {
    if (number % 1 == 0) {
      return number.toInt().toString();
    } else {
      return number.toStringAsFixed(10).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _display));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _useResult() {
    Navigator.pop(context, _display);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: themeColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Calculator',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            tooltip: 'Copy Result',
            onPressed: _copyToClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            tooltip: 'Use Result',
            onPressed: _useResult,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Display Section
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_expression.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _expression,
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            child: Text(
                              _display,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Buttons Section
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Row 1: Clear, Backspace, Divide
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('C', Colors.grey[700]!, Colors.white, _onClearPressed),
                          _buildButton('⌫', Colors.grey[700]!, Colors.white, _onBackspacePressed),
                          _buildButton('÷', themeColor, Colors.white, () => _onOperationPressed('÷')),
                        ],
                      ),
                    ),
                    // Row 2: 7, 8, 9, Multiply
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('7', Colors.grey[800]!, Colors.white, () => _onNumberPressed('7')),
                          _buildButton('8', Colors.grey[800]!, Colors.white, () => _onNumberPressed('8')),
                          _buildButton('9', Colors.grey[800]!, Colors.white, () => _onNumberPressed('9')),
                          _buildButton('×', themeColor, Colors.white, () => _onOperationPressed('×')),
                        ],
                      ),
                    ),
                    // Row 3: 4, 5, 6, Subtract
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('4', Colors.grey[800]!, Colors.white, () => _onNumberPressed('4')),
                          _buildButton('5', Colors.grey[800]!, Colors.white, () => _onNumberPressed('5')),
                          _buildButton('6', Colors.grey[800]!, Colors.white, () => _onNumberPressed('6')),
                          _buildButton('-', themeColor, Colors.white, () => _onOperationPressed('-')),
                        ],
                      ),
                    ),
                    // Row 4: 1, 2, 3, Add
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('1', Colors.grey[800]!, Colors.white, () => _onNumberPressed('1')),
                          _buildButton('2', Colors.grey[800]!, Colors.white, () => _onNumberPressed('2')),
                          _buildButton('3', Colors.grey[800]!, Colors.white, () => _onNumberPressed('3')),
                          _buildButton('+', themeColor, Colors.white, () => _onOperationPressed('+')),
                        ],
                      ),
                    ),
                    // Row 5: 0, Decimal, Equals
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildButton('0', Colors.grey[800]!, Colors.white, () => _onNumberPressed('0')),
                          ),
                          _buildButton('.', Colors.grey[800]!, Colors.white, _onDecimalPressed),
                          _buildButton('=', themeColor, Colors.white, _onEqualsPressed),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    String text,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

