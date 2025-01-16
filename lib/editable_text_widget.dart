import 'dart:math';
import 'package:flutter/material.dart';

class EditableTextWidget extends StatefulWidget {
  final String inputString;
  final double hiddenWordPercentage;

  const EditableTextWidget({
    super.key,
    required this.inputString,
    required this.hiddenWordPercentage,
  });

  @override
  State<EditableTextWidget> createState() => _EditableTextWidgetState();
}

class _EditableTextWidgetState extends State<EditableTextWidget> {
  late TextEditingController _textController;
  late List<Color> _textColors;
  late List<String> _displayText;
  late List<bool> _hiddenWords;
  String _defaultText = '';
  int _cursorLogicalPosition = 0;

  // Добавляем GlobalKey для RichText
  final GlobalKey _richTextKey = GlobalKey();
  // Добавляем ScrollController для управления скроллингом
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    _defaultText = widget.inputString;

    _textController = TextEditingController();
    _textColors = List.generate(_defaultText.length, (_) => Colors.white);
    _displayText = List.generate(_defaultText.length, (i) => _defaultText[i]);

    _hiddenWords = _getHiddenWordsList(_defaultText, widget.hiddenWordPercentage);
    _applyHiddenWords();

    _cursorLogicalPosition = 0;

    _textController.addListener(() {
      setState(() {
        _cursorLogicalPosition = _calculateLogicalCursorPosition(
          _textController.selection.base.offset,
        );
      });
        _scrollToLastEnteredCharacter(); // Вызываем скроллинг при изменении текста
    });
  }

  @override
  void didUpdateWidget(covariant EditableTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inputString != oldWidget.inputString ||
        widget.hiddenWordPercentage != oldWidget.hiddenWordPercentage) {
      setState(() {
        _initializeState();
      });
    }
  }

  List<bool> _getHiddenWordsList(String text, double percentage) {
    final List<String> tokens = [];
    final List<bool> isWord = [];

    String currentWord = '';

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      if (RegExp(r'[a-zA-Zа-яА-Я]').hasMatch(char)) {
        currentWord += char;
      } else {
        if (currentWord.isNotEmpty) {
          tokens.add(currentWord);
          isWord.add(true);
          currentWord = '';
        }
        tokens.add(char);
        isWord.add(false);
      }
    }

    if (currentWord.isNotEmpty) {
      tokens.add(currentWord);
      isWord.add(true);
    }

    final wordCount = isWord.where((element) => element).length;
    final hiddenCount = (wordCount * percentage).round();

    final wordIndexes = List<int>.generate(
      tokens.length,
      (i) => i,
    ).where((i) => isWord[i]).toList();

    final random = Random();
    for (int i = wordIndexes.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = wordIndexes[i];
      wordIndexes[i] = wordIndexes[j];
      wordIndexes[j] = temp;
    }

    final hiddenTokens = List<bool>.filled(tokens.length, false);
    for (int i = 0; i < hiddenCount; i++) {
      if (i < wordIndexes.length) {
        hiddenTokens[wordIndexes[i]] = true;
      }
    }

    final hiddenList = <bool>[];
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (isWord[i]) {
        hiddenList.addAll(List<bool>.filled(token.length, hiddenTokens[i]));
      } else {
        hiddenList.addAll(List<bool>.filled(token.length, false));
      }
    }

    return hiddenList;
  }

  void _applyHiddenWords() {
    for (int i = 0; i < _defaultText.length; i++) {
      if (!_hiddenWords[i]) {
        _displayText[i] = _defaultText[i];
        _textColors[i] = Colors.white;
      } else {
        _displayText[i] = '_';
        _textColors[i] = Colors.grey;
      }
    }
  }

  int _calculateLogicalCursorPosition(int actualPosition) {
    int count = 0;
    for (int i = 0; i < _defaultText.length; i++) {
      if (_hiddenWords[i]) {
        if (count == actualPosition) {
          return i;
        }
        count++;
      }
    }
    return _defaultText.length;
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged(String inputText) {
    setState(() {
      int inputPos = 0;
      for (int i = 0; i < _defaultText.length; i++) {
        if (_hiddenWords[i]) {
          if (inputPos < inputText.length && inputText[inputPos] == _defaultText[i]) {
            _displayText[i] = _defaultText[i];
            _textColors[i] = Colors.green;
          } else {
            if (inputPos < inputText.length) {
              _displayText[i] = inputText[inputPos];
              _textColors[i] = Colors.red;
            } else {
              _displayText[i] = '_';
              _textColors[i] = Colors.grey;
              
            }
          }
          inputPos++;
        }
      }
    });
  }

  void _scrollToLastEnteredCharacter() {
  // Ждем завершения текущего кадра перед вычислением координат
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Ждем еще один кадр, чтобы убедиться, что RichText обновился
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Получаем RenderObject для RichText
      final RenderBox renderBox = _richTextKey.currentContext?.findRenderObject() as RenderBox;

      // Получаем координаты последнего введенного символа
      final double lastEnteredCharOffset = _getLastEnteredCharacterOffset(renderBox);
      print(lastEnteredCharOffset);

      // Прокручиваем до позиции последнего введенного символа
      _scrollController.animateTo(
        lastEnteredCharOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  });
}

  double _getLastEnteredCharacterOffset(RenderBox renderBox) {
    final richText = _richTextKey.currentWidget as RichText;
    final textSpan = richText.text as TextSpan;

    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: renderBox.size.width);
    final offset = textPainter.getOffsetForCaret(
      TextPosition(offset: _cursorLogicalPosition),
      Rect.zero,
    );

    return offset.dy;
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    resizeToAvoidBottomInset: false, // Отключаем автоматическое изменение размера
    body: Container(
      decoration: const BoxDecoration(color: Colors.black),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const NeverScrollableScrollPhysics(), // Запрещаем скроллинг, если контент не выходит за пределы
          child: Stack(
            children: [
              RichText(
                key: _richTextKey, // Добавляем GlobalKey
                text: TextSpan(
                  children: List.generate(
                    _defaultText.length,
                    (i) => TextSpan(
                      text: _displayText[i],
                      style: TextStyle(
                        backgroundColor: i == _cursorLogicalPosition && i != 0
                            ? Colors.white
                            : Colors.transparent,
                        color: _textColors[i],
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 18,
                    height: 1.2,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  maxLines: null,
                  cursorColor: Colors.transparent,
                  onChanged: (value) {
                    final filteredValue = value.replaceAll(RegExp(r'[\s\n\r]'), '');
                    if (filteredValue != value) {
                      _textController.text = filteredValue;
                      _textController.selection = TextSelection.fromPosition(
                        TextPosition(offset: filteredValue.length),
                      );
                    }
                    _onTextChanged(filteredValue);
                  },
                  showCursor: false,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}