import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/locale_provider.dart';
import 'auth_widgets.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _loginCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool  _obscure      = true;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _loginCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthProvider>().login(
      _loginCtrl.text,
      _passwordCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isRu = context.watch<LocaleProvider>().isRussian;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Center(
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.asset(
                                  'assets/icons/app_icon.png',
                                  width:  88,
                                  height: 88,
                                  fit:    BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Gryphone Invest',
                                style: Theme.of(context).textTheme.displayMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isRu
                                    ? 'Симулируй • Прогнозируй • Тестируй'
                                    : 'Simulate • Predict • Backtest',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        FieldLabel(text: isRu ? 'Логин' : 'Login'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller:      _loginCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText:   isRu ? 'Введите логин' : 'Enter login',
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? (isRu ? 'Введите логин' : 'Enter login')
                                  : null,
                        ),
                        const SizedBox(height: 14),

                        FieldLabel(text: isRu ? 'Пароль' : 'Password'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller:      _passwordCtrl,
                          obscureText:     _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText:   isRu ? 'Введите пароль' : 'Enter password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppColors.primaryLight,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.primaryLight,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty)
                                  ? (isRu ? 'Введите пароль' : 'Enter password')
                                  : null,
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              context.read<AuthProvider>().clearError();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 6),
                            ),
                            child: Text(
                              isRu ? 'Забыли пароль?' : 'Forgot password?',
                              style: const TextStyle(
                                color:      AppColors.primaryLight,
                                fontSize:   13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        if (auth.error != null)
                          ErrorBanner(error: auth.error!, isRu: isRu),

                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _submit,
                            child: auth.isLoading
                                ? const SizedBox(
                                    width:  20,
                                    height: 20,
                                    child:  CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(isRu ? 'Войти' : 'Sign In'),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Center(
                          child: GestureDetector(
                            onTap: () {
                              context.read<AuthProvider>().clearError();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: isRu
                                        ? 'Нет аккаунта? '
                                        : 'No account? ',
                                  ),
                                  TextSpan(
                                    text: isRu
                                        ? 'Зарегистрироваться'
                                        : 'Sign Up',
                                    style: const TextStyle(
                                      color:      AppColors.primaryLight,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        Center(
                          child: Text(
                            isRu
                                ? 'Только для образовательных целей'
                                : 'For educational purposes only',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
