import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';


final AudioPlayer pemutarMusik = AudioPlayer();
final ValueNotifier<bool> globalIsDarkMode = ValueNotifier<bool>(true);
final ValueNotifier<bool> globalIsJJMode = ValueNotifier<bool>(true);
final ValueNotifier<List<String>> globalHistory = ValueNotifier<List<String>>([]);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  final prefs = await SharedPreferences.getInstance();
  final savedHistory = prefs.getStringList('calc_history_v1') ?? [];
  globalHistory.value = savedHistory;

  runApp(const UltimateGodTierJJApp());
}

class UltimateGodTierJJApp extends StatelessWidget {
  const UltimateGodTierJJApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: globalIsDarkMode,
      builder: (context, isDark, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Kalkulator mzkyzak',
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'Segoe UI',
            scaffoldBackgroundColor: const Color(0xFFE2E8F0),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'Segoe UI',
            scaffoldBackgroundColor: const Color(0xFF03050A),
          ),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: const IntroTypewriterWrapper(),
        );
      },
    );
  }
}

class IntroTypewriterWrapper extends StatefulWidget {
  const IntroTypewriterWrapper({super.key});

  @override
  State<IntroTypewriterWrapper> createState() => _IntroTypewriterWrapperState();
}

class _IntroTypewriterWrapperState extends State<IntroTypewriterWrapper> {
  bool _showIntro = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _showIntro = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const UltimateJJScreen(),
        if (_showIntro)
          Positioned.fill(
            child: Container(
              color: const Color(0xFF03050A),
              child: Center(
                child: const TypewriterTextWidget(
                  text: "Welcome to calculator...\nBY: MZKYZAK",
                ),
              ),
            ).animate().fadeOut(delay: 3000.ms, duration: 500.ms),
          ),
      ],
    );
  }
}

class TypewriterTextWidget extends StatefulWidget {
  final String text;
  const TypewriterTextWidget({super.key, required this.text});

  @override
  State<TypewriterTextWidget> createState() => _TypewriterTextWidgetState();
}

class _TypewriterTextWidgetState extends State<TypewriterTextWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _characterCount = StepTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _characterCount,
      builder: (context, child) {
        String visibleText = widget.text.substring(0, _characterCount.value);
        return Text(
          visibleText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 5,
            decoration: TextDecoration.none,
            shadows: [Shadow(color: Color(0xFF00E5FF), blurRadius: 15)],
          ),
        );
      },
    );
  }
}

class UltimateJJScreen extends StatefulWidget {
  const UltimateJJScreen({super.key});

  @override
  State<UltimateJJScreen> createState() => _UltimateJJScreenState();
}

class _UltimateJJScreenState extends State<UltimateJJScreen> {
  String _equation = '';
  String _liveResult = '';
  double _memoryValue = 0;
  bool _isShakeActive = false;

  final ScrollController _displayScrollController = ScrollController();

  void _playLightHaptic() {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  void _playHeavyHaptic() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  }

  void _triggerShakeJJ() async {
    if (!globalIsJJMode.value) return;
    setState(() => _isShakeActive = true);
    _playHeavyHaptic();
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _isShakeActive = false);
  }

  void _onButtonPressed(String text) {
    if (text == '=') {
      _triggerShakeJJ();
    } else {
      _playLightHaptic();
    }

    setState(() {
      if (text == 'MC') {
        _memoryValue = 0;
        return;
      } else if (text == 'MR') {
        _equation += _formatOutput(_memoryValue);
        _evaluateLiveResult();
        return;
      } else if (text == 'M+') {
        _evaluateLiveResult(forceEvaluate: true);
        if (_liveResult.isNotEmpty && _liveResult != 'Error') {
          _memoryValue += double.tryParse(_liveResult) ?? 0;
        }
        return;
      } else if (text == 'M-') {
        _evaluateLiveResult(forceEvaluate: true);
        if (_liveResult.isNotEmpty && _liveResult != 'Error') {
          _memoryValue -= double.tryParse(_liveResult) ?? 0;
        }
        return;
      }

      if (text == 'AC') {
        _equation = '';
        _liveResult = '';
      } else if (text == '⌫') {
        if (_equation.isNotEmpty) {
          _equation = _equation.substring(0, _equation.length - 1);
        }
      } else if (text == '=') {
        if (_liveResult.isNotEmpty && _liveResult != 'Error') {
          _saveToHistory(_equation, _liveResult);
          _equation = _liveResult;
          _liveResult = '';
        }
      } else {
        String appendText = text;
        if (['sin', 'cos', 'tan', 'log', 'ln'].contains(text)) {
          appendText = '$text(';
        } else if (text == '√') {
          appendText = 'sqrt(';
        } else if (text == 'π') {
          appendText = 'π';
        } else if (text == 'e') {
          appendText = 'e';
        }

        if (_isBasicOperator(text) && _equation.isNotEmpty && _isBasicOperator(_equation.characters.last)) {
          _equation = _equation.substring(0, _equation.length - 1) + text;
        } else {
          _equation += appendText;
        }
      }
      _evaluateLiveResult();
    });

    _autoScrollDisplay();
  }

  bool _isBasicOperator(String char) {
    return ['+', '-', 'x', '÷', '%', '^'].contains(char);
  }

  Future<void> _saveToHistory(String eq, String res) async {
    final newList = List<String>.from(globalHistory.value);
    newList.insert(0, "$eq = $res");
    if (newList.length > 50) newList.removeLast();
    globalHistory.value = newList;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('calc_history_v1', newList);
  }

  String _formatOutput(double value) {
    if (value == value.toInt()) return value.toInt().toString();
    return value.toStringAsFixed(6).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  void _evaluateLiveResult({bool forceEvaluate = false}) {
    if (_equation.isEmpty) {
      _liveResult = '';
      return;
    }
    try {
      String parsedEquation = _equation
          .replaceAll('x', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', math.pi.toString())
          .replaceAll('e', math.e.toString())
          .replaceAll('ln(', 'log(');

      Parser p = Parser();
      Expression exp = p.parse(parsedEquation);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      if (eval.isNaN || eval.isInfinite) {
        _liveResult = 'Error';
      } else {
        _liveResult = _formatOutput(eval);
      }
    } catch (e) {
      if (forceEvaluate) _liveResult = 'Error';
    }
  }

  void _autoScrollDisplay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_displayScrollController.hasClients) {
        _displayScrollController.animateTo(
          _displayScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
        );
      }
    });
  }

  void _showHistoryModal() {
    _playLightHaptic();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GlassmorphicHistoryDrawer(isDark: globalIsDarkMode.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: globalIsDarkMode,
      builder: (context, isDark, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: globalIsJJMode,
          builder: (context, isJJ, child) {
            return Scaffold(
              body: Stack(
                children: [
                  CyberLiveBackground(isDark: isDark, isJJ: isJJ),
                  SafeArea(
                    child: Column(
                      children: [
                        CalcHeader(
                          isDark: isDark,
                          isJJ: isJJ,
                          onHistoryTap: _showHistoryModal,
                        ),
                        Expanded(
                          flex: 30,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: AnimatedJJWrapper(
                              isJJ: isJJ,
                              isShakeActive: _isShakeActive,
                              child: GlassmorphicDisplay(
                                equation: _equation,
                                liveResult: _liveResult,
                                scrollController: _displayScrollController,
                                isDark: isDark,
                                isShakeActive: _isShakeActive,
                                memoryValue: _memoryValue,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 70,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                            child: AnimatedJJWrapper(
                              isJJ: isJJ,
                              isShakeActive: false,
                              child: SuperLiquidBorder(
                                isDark: isDark,
                                isJJ: isJJ,
                                child: UltimateKeypad(
                                  isDark: isDark,
                                  onButtonPressed: _onButtonPressed,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class CalcHeader extends StatelessWidget {
  final bool isDark;
  final bool isJJ;
  final VoidCallback onHistoryTap;

  const CalcHeader({super.key, required this.isDark, required this.isJJ, required this.onHistoryTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const LiveAnimationLogo(),
              const SizedBox(width: 10),
              NeonText(
                text: "by:mzkyzak",
                color: isDark ? Colors.white : Colors.black87,
                glowColor: const Color(0xFFD500F9),
                isDark: isDark,
              ),
            ],
          ),
          Row(
            children: [
              _buildIconButton(
                icon: Icons.history_rounded,
                color: isDark ? Colors.white70 : Colors.black54,
                onTap: onHistoryTap,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
             _buildIconButton(
                icon: isJJ ? Icons.music_note_rounded : Icons.music_off_rounded,
                color: isJJ ? const Color(0xFFFF2A55) : Colors.grey,
                onTap: () async {
                  HapticFeedback.heavyImpact();
                  bool statusBaru = !isJJ;
                  globalIsJJMode.value = statusBaru;
                  
                  // LOGIKA PLAY/PAUSE LAGU MP3 
                  if (statusBaru == true) {
                    pemutarMusik.setReleaseMode(ReleaseMode.loop); // Biar lagunya muter terus
                    await pemutarMusik.play(AssetSource('lagu_jj.mp3')); // Play lagu
                  } else {
                    await pemutarMusik.pause(); // Pause lagu
                  }
                 
                },
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildIconButton(
                icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? Colors.amber : Colors.indigo,
                onTap: () {
                  HapticFeedback.lightImpact();
                  globalIsDarkMode.value = !isDark;
                },
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required Color color, required VoidCallback onTap, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class LiveAnimationLogo extends StatelessWidget {
  const LiveAnimationLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final math.Random random = math.Random();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        return Container(
          width: 5,
          height: 18.0 + random.nextInt(10).toDouble(),
          margin: const EdgeInsets.only(left: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.8), blurRadius: 8)],
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleY(
              begin: 0.3, end: 1.0, duration: (200 + random.nextInt(300)).ms, curve: Curves.easeInOut,
            );
      }),
    );
  }
}

class GlassmorphicDisplay extends StatelessWidget {
  final String equation;
  final String liveResult;
  final ScrollController scrollController;
  final bool isDark;
  final bool isShakeActive;
  final double memoryValue;

  const GlassmorphicDisplay({
    super.key,
    required this.equation,
    required this.liveResult,
    required this.scrollController,
    required this.isDark,
    required this.isShakeActive,
    required this.memoryValue,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.4);
    final Color borderColor = isShakeActive 
        ? const Color(0xFFFF2A55) 
        : (isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1));
    final Color shadowColor = isShakeActive 
        ? const Color(0xFFFF2A55).withOpacity(0.6) 
        : (isDark ? const Color(0xFF00E5FF).withOpacity(0.1) : Colors.black.withOpacity(0.05));

    return ClipRRect(
      borderRadius: BorderRadius.circular(35),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: borderColor, width: isShakeActive ? 4.0 : 1.5),
            boxShadow: [
              BoxShadow(color: shadowColor, blurRadius: isShakeActive ? 40 : 20, spreadRadius: isShakeActive ? 10 : 0),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (memoryValue != 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.memory_rounded, size: 14, color: Colors.orangeAccent),
                    const SizedBox(width: 4),
                    Text(
                      "M = ${memoryValue.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '')}",
                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ).animate().fadeIn(),
              const Spacer(),
              Flexible(
                flex: 2,
                child: SingleChildScrollView(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: Text(
                      equation.isEmpty ? '0' : equation,
                      key: ValueKey<String>(equation),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 60,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  alignment: Alignment.centerRight,
                  height: liveResult.isEmpty ? 0 : 45,
                  child: Text(
                    liveResult == 'Error' ? 'CRITICAL ERROR' : '=$liveResult',
                    style: TextStyle(
                      color: liveResult == 'Error' ? Colors.redAccent : (isDark ? const Color(0xFFD500F9) : Colors.purple.shade700),
                      fontSize: 35,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: isDark ? const Color(0xFFD500F9).withOpacity(0.8) : Colors.transparent, 
                          blurRadius: 20
                        )
                      ],
                    ),
                  ).animate(target: liveResult.isNotEmpty ? 1 : 0).fadeIn().slideX(begin: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UltimateKeypad extends StatelessWidget {
  final bool isDark;
  final Function(String) onButtonPressed;

  const UltimateKeypad({super.key, required this.isDark, required this.onButtonPressed});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(43),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(43),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white, width: 2),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.black12))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTextBtn('MC'), _buildTextBtn('MR'), _buildTextBtn('M+'), _buildTextBtn('M-'),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.black12, width: 2))),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildSciBtn('sin'), _buildSciBtn('cos'), _buildSciBtn('tan'),
                      _buildSciBtn('log'), _buildSciBtn('ln'), _buildSciBtn('√'), 
                      _buildSciBtn('^'), _buildSciBtn('('), _buildSciBtn(')'), 
                      _buildSciBtn('π'), _buildSciBtn('e'),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Expanded(child: _buildNumRow(['AC', '⌫', '%', '÷'], isTopAction: true)),
                      Expanded(child: _buildNumRow(['7', '8', '9', 'x'])),
                      Expanded(child: _buildNumRow(['4', '5', '6', '-'])),
                      Expanded(child: _buildNumRow(['1', '2', '3', '+'])),
                      Expanded(child: _buildNumRow(['0', '.', '='], isLastRow: true)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextBtn(String text) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onButtonPressed(text),
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Text(
            text, 
            style: TextStyle(
              color: isDark ? Colors.orangeAccent : Colors.deepOrange, 
              fontSize: 16, 
              fontWeight: FontWeight.bold
            )
          ),
        ),
      ),
    );
  }

  Widget _buildSciBtn(String text) {
    return GestureDetector(
      onTap: () => onButtonPressed(text),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isDark ? const Color(0xFF00E5FF).withOpacity(0.5) : Colors.blue.withOpacity(0.5), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          text, 
          style: TextStyle(
            color: isDark ? const Color(0xFF00E5FF) : Colors.blue.shade800, 
            fontSize: 18, 
            fontWeight: FontWeight.w600
          )
        ),
      ),
    );
  }

  Widget _buildNumRow(List<String> buttons, {bool isTopAction = false, bool isLastRow = false}) {
    return Row(
      children: buttons.map((text) {
        int flex = (text == '0') ? 2 : 1;
        return Expanded(
          flex: flex,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: UltimateGlassButton(
              text: text, 
              onTap: () => onButtonPressed(text), 
              isTopAction: isTopAction,
              isDark: isDark,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class UltimateGlassButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isTopAction;
  final bool isDark;

  const UltimateGlassButton({super.key, required this.text, required this.onTap, this.isTopAction = false, required this.isDark});

  @override
  State<UltimateGlassButton> createState() => _UltimateGlassButtonState();
}

class _UltimateGlassButtonState extends State<UltimateGlassButton> with SingleTickerProviderStateMixin {
  late AnimationController _btnController;

  @override
  void initState() {
    super.initState();
    _btnController = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
  }

  @override
  void dispose() {
    _btnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isOperator = ['+', '-', 'x', '÷'].contains(widget.text);
    final bool isEqual = widget.text == '=';

    Color textColor = widget.isDark ? Colors.white : Colors.black87;
    Color bgColor = widget.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04);
    Color borderColor = widget.isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1);

    if (widget.isTopAction) {
      textColor = widget.isDark ? const Color(0xFFFF2A55) : Colors.red.shade700;
      bgColor = widget.isDark ? const Color(0xFFFF2A55).withOpacity(0.15) : Colors.red.withOpacity(0.1);
      borderColor = widget.isDark ? const Color(0xFFFF2A55).withOpacity(0.5) : Colors.red.withOpacity(0.3);
    } else if (isOperator) {
      textColor = widget.isDark ? const Color(0xFF00E5FF) : Colors.blue.shade700;
      bgColor = widget.isDark ? const Color(0xFF00E5FF).withOpacity(0.15) : Colors.blue.withOpacity(0.1);
      borderColor = widget.isDark ? const Color(0xFF00E5FF).withOpacity(0.5) : Colors.blue.withOpacity(0.3);
    } else if (isEqual) {
      textColor = Colors.white;
      bgColor = const Color(0xFFD500F9);
      borderColor = widget.isDark ? Colors.white.withOpacity(0.8) : Colors.purple.shade300;
    }

    return GestureDetector(
      onTapDown: (_) => _btnController.forward(),
      onTapUp: (_) {
        _btnController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _btnController.reverse(),
      child: AnimatedBuilder(
        animation: _btnController,
        builder: (context, child) {
          final scale = 1.0 - (_btnController.value * 0.15);
          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: bgColor,
                border: Border.all(color: borderColor, width: isEqual ? 3.0 : 1.5),
                gradient: isEqual
                    ? const LinearGradient(colors: [Color(0xFFFF2A55), Color(0xFF7C4DFF)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                boxShadow: isEqual
                    ? [BoxShadow(color: const Color(0xFFD500F9).withOpacity(widget.isDark ? 0.8 : 0.4), blurRadius: 20, spreadRadius: 2)]
                    : (widget.isDark ? [] : [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(2, 2))]),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.text,
                style: TextStyle(
                  color: textColor,
                  fontSize: widget.text == '.' ? 45 : 32,
                  fontWeight: isOperator || widget.isTopAction || isEqual ? FontWeight.w800 : FontWeight.w400,
                  shadows: widget.isDark ? [Shadow(color: textColor.withOpacity(0.6), blurRadius: 15)] : [],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SuperLiquidBorder extends StatefulWidget {
  final Widget child;
  final bool isDark;
  final bool isJJ;

  const SuperLiquidBorder({super.key, required this.child, required this.isDark, required this.isJJ});

  @override
  State<SuperLiquidBorder> createState() => _SuperLiquidBorderState();
}

class _SuperLiquidBorderState extends State<SuperLiquidBorder> with SingleTickerProviderStateMixin {
  late AnimationController _borderController;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
  }

  @override
  void dispose() {
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _borderController,
      builder: (context, child) {
        _borderController.duration = widget.isJJ ? const Duration(milliseconds: 1000) : const Duration(milliseconds: 4000);
        
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(46),
            gradient: SweepGradient(
              center: FractionalOffset.center,
              startAngle: 0.0,
              endAngle: math.pi * 2,
              colors: widget.isDark
                ? const [Color(0xFF00E5FF), Color(0xFFD500F9), Color(0xFFFF2A55), Color(0xFF00FF00), Color(0xFF00E5FF)]
                : [Colors.blue, Colors.purple, Colors.pink, Colors.orange, Colors.blue],
              transform: GradientRotation(_borderController.value * math.pi * 2),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isDark ? const Color(0xFF00E5FF).withOpacity(0.3) : Colors.blue.withOpacity(0.2), 
                blurRadius: widget.isJJ ? 40 : 20, 
                spreadRadius: widget.isJJ ? 8 : 2
              ),
            ],
          ),
          padding: EdgeInsets.all(widget.isJJ ? 5 : 3),
          child: widget.child,
        );
      },
    );
  }
}

class GlassmorphicHistoryDrawer extends StatelessWidget {
  final bool isDark;
  const GlassmorphicHistoryDrawer({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: globalHistory,
      builder: (context, history, child) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(top: BorderSide(color: isDark ? Colors.white24 : Colors.black12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50, height: 5,
                      decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("History", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                        onPressed: () async {
                          globalHistory.value = [];
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('calc_history_v1');
                        },
                      )
                    ],
                  ),
                  const Divider(color: Colors.grey),
                  Expanded(
                    child: history.isEmpty
                        ? Center(child: Text("Tidak ada", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)))
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: history.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  history[index],
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF00E5FF) : Colors.blue.shade700, 
                                    fontSize: 22, 
                                    fontWeight: FontWeight.w600
                                  ),
                                  textAlign: TextAlign.right,
                                ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}

class AnimatedJJWrapper extends StatelessWidget {
  final Widget child;
  final bool isJJ;
  final bool isShakeActive;

  const AnimatedJJWrapper({super.key, required this.child, required this.isJJ, required this.isShakeActive});

  @override
  Widget build(BuildContext context) {
    Widget animatedChild = child;

    if (isJJ) {
      animatedChild = animatedChild
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.015, duration: 400.ms, curve: Curves.easeInOutSine);
    }

    if (isShakeActive) {
      animatedChild = animatedChild.animate().shake(hz: 12, curve: Curves.bounceOut, duration: 300.ms);
    }

    return animatedChild;
  }
}

class CyberLiveBackground extends StatelessWidget {
  final bool isDark;
  final bool isJJ;

  const CyberLiveBackground({super.key, required this.isDark, required this.isJJ});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: CyberGridPainter(isDark: isDark)),
        ).animate(target: isJJ ? 1 : 0).fade(begin: 0.2, end: 0.8, duration: 500.ms),
        
        HyperOrb(color: const Color(0xFF00E5FF), size: 550, startX: -180, startY: -120, moveX: 350, moveY: 450, duration: isJJ ? 5 : 10, isDark: isDark),
        HyperOrb(color: const Color(0xFFFF2A55), size: 450, startX: 350, startY: 120, moveX: -350, moveY: 350, duration: isJJ ? 4 : 8, isDark: isDark),
        HyperOrb(color: const Color(0xFFD500F9), size: 650, startX: 120, startY: 650, moveX: -250, moveY: -450, duration: isJJ ? 6 : 12, isDark: isDark),

        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: isDark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.5)),
        ),
      ],
    );
  }
}

class HyperOrb extends StatelessWidget {
  final Color color;
  final double size, startX, startY, moveX, moveY;
  final int duration;
  final bool isDark;

  const HyperOrb({super.key, required this.color, required this.size, required this.startX, required this.startY, required this.moveX, required this.moveY, required this.duration, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: startX,
      top: startY,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(isDark ? 0.8 : 0.4)),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .move(end: Offset(moveX, moveY), duration: duration.seconds, curve: Curves.easeInOutBack)
          .scaleXY(end: 1.5, duration: (duration - 1).seconds, curve: Curves.bounceIn)
          .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.5)),
    );
  }
}

class CyberGridPainter extends CustomPainter {
  final bool isDark;
  CyberGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)..strokeWidth = 2.0;
    for (double i = 0; i < size.width; i += 50) canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += 50) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NeonText extends StatelessWidget {
  final String text;
  final Color color;
  final Color glowColor;
  final bool isDark;

  const NeonText({super.key, required this.text, required this.color, required this.glowColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 18,
        letterSpacing: 4,
        fontWeight: FontWeight.w900,
        shadows: isDark ? [
          Shadow(color: glowColor.withOpacity(0.8), blurRadius: 15),
          Shadow(color: const Color(0xFF00E5FF).withOpacity(0.8), blurRadius: 30),
        ] : [],
      ),
    );
  }
}