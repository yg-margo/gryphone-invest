import 'auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/locale_provider.dart';
import '../main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey         = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _surnameCtrl     = TextEditingController();
  final _loginCtrl       = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  final _confirmCtrl     = TextEditingController();
  bool  _obscurePass     = true;
  bool  _obscureConfirm  = true;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  final _nameFocus     = FocusNode();
  final _surnameFocus  = FocusNode();
  final _loginFocus    = FocusNode();
  final _emailFocus    = FocusNode();
  final _passFocus     = FocusNode();
  final _confirmFocus  = FocusNode();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [
      _nameCtrl, _surnameCtrl, _loginCtrl,
      _emailCtrl, _passwordCtrl, _confirmCtrl,
    ]) {
      c.dispose();
    }
    for (final f in [
      _nameFocus, _surnameFocus, _loginFocus,
      _emailFocus, _passFocus, _confirmFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final isRu = context.read<LocaleProvider>().isRussian;

    final ok = await auth.register(
      name:     _nameCtrl.text.trim(),
      surname:  _surnameCtrl.text.trim(),
      login:    _loginCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;

    if (ok) {
      if (auth.isAuthenticated) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRu
                  ? 'Регистрация прошла успешно! Войдите в аккаунт.'
                  : 'Registration successful! Please sign in.',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) {
      return context.read<LocaleProvider>().isRussian
          ? 'Введите пароль' : 'Enter password';
    }
    if (v.length < 6) {
      return context.read<LocaleProvider>().isRussian
          ? 'Минимум 6 символов' : 'Minimum 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isRu = context.watch<LocaleProvider>().isRussian;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRu ? 'Регистрация' : 'Sign Up'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                        Text(
                          isRu ? 'Создать аккаунт' : 'Create account',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isRu
                              ? 'Заполните данные для регистрации'
                              : 'Fill in your details to get started',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 32),

                        FieldLabel(text: isRu ? 'Имя' : 'First Name'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller:      _nameCtrl,
                          focusNode:       _nameFocus,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_surnameFocus),
                          decoration: InputDecoration(
                            hintText:   isRu ? 'Маргарита' : 'Margaret',
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? (isRu ? 'Введите имя' : 'Enter first name')
                                  : null,
                        ),
                        const SizedBox(height: 14),

                        FieldLabel(text: isRu ? 'Фамилия' : 'Last Name'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller:      _surnameCtrl,
                          focusNode:       _surnameFocus,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_loginFocus),
                          decoration: InputDecoration(
                            hintText:   isRu ? 'Яганова' : 'Yaganova',
                            prefixIcon: const Icon(
                              Icons.badge_outlined,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? (isRu ? 'Введите фамилию' : 'Enter last name')
                                  : null,
                        ),
                        const SizedBox(height: 14),

                        FieldLabel(text: isRu ? 'Логин' : 'Username'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller:      _loginCtrl,
                          focusNode:       _loginFocus,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_emailFocus),
                          decoration: InputDecoration(
                            hintText:   isRu ? 'например: user123' : 'e.g. user123',
                            prefixIcon: const Icon(
                              Icons.alternate_email_rounded,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return isRu ? 'Введите логин' : 'Enter username';
                            }
                            if (v.trim().length < 3) {
                              return isRu
                                  ? 'Минимум 3 символа' : 'Minimum 3 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        const FieldLabel(text: 'Email'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller:      _emailCtrl,
                          focusNode:       _emailFocus,
                          textInputAction: TextInputAction.next,
                          keyboardType:    TextInputType.emailAddress,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_passFocus),
                          decoration: const InputDecoration(
                            hintText:   'example@mail.com',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return isRu ? 'Введите email' : 'Enter email';
                            }
                            if (!RegExp(
                                    r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$')
                                .hasMatch(v.trim())) {
                              return isRu
                                  ? 'Некорректный email' : 'Invalid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        FieldLabel(text: isRu ? 'Пароль' : 'Password'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller:      _passwordCtrl,
                          focusNode:       _passFocus,
                          obscureText:     _obscurePass,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_confirmFocus),
                          decoration: InputDecoration(
                            hintText:   isRu ? 'Минимум 6 символов' : 'Min 6 characters',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppColors.primaryLight,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.primaryLight,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 14),

                        FieldLabel(
                            text: isRu
                                ? 'Подтвердить пароль'
                                : 'Confirm Password'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller:      _confirmCtrl,
                          focusNode:       _confirmFocus,
                          obscureText:     _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText:   isRu ? 'Повторите пароль' : 'Repeat password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppColors.primaryLight,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.primaryLight,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return isRu
                                  ? 'Подтвердите пароль'
                                  : 'Confirm your password';
                            }
                            if (v != _passwordCtrl.text) {
                              return isRu
                                  ? 'Пароли не совпадают'
                                  : 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

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
                                : Text(
                                    isRu ? 'Зарегистрироваться' : 'Sign Up'),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: isRu
                                        ? 'Уже есть аккаунт? '
                                        : 'Already have an account? ',
                                  ),
                                  TextSpan(
                                    text: isRu ? 'Войти' : 'Sign In',
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
                        const SizedBox(height: 32),
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
