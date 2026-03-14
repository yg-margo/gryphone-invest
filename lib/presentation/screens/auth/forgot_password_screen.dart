import 'auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/locale_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  bool  _sent       = false;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

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
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok   = await auth.forgotPassword(_emailCtrl.text.trim());
    if (ok && mounted) {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isRu = context.watch<LocaleProvider>().isRussian;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRu ? 'Восстановление' : 'Recovery'),
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
                  child: _sent
                      ? _SuccessState(isRu: isRu, email: _emailCtrl.text.trim())
                      : Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width:  80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.lock_reset_rounded,
                                    color: AppColors.primaryLight,
                                    size:  40,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              Center(
                                child: Text(
                                  isRu
                                      ? 'Забыли пароль?'
                                      : 'Forgot password?',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: Text(
                                  isRu
                                      ? 'Введите email, привязанный к аккаунту.\nМы пришлём ссылку для сброса пароля.'
                                      : 'Enter the email linked to your account.\nWe\'ll send a reset link.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 36),

                              const FieldLabel(text: 'Email'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller:      _emailCtrl,
                                keyboardType:    TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: const InputDecoration(
                                  hintText:   'example@mail.com',
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return isRu
                                        ? 'Введите email' : 'Enter email';
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
                                      : Text(isRu
                                          ? 'Отправить ссылку'
                                          : 'Send reset link'),
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
                                              ? 'Вспомнили пароль? '
                                              : 'Remember it? ',
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

class _SuccessState extends StatelessWidget {
  final bool   isRu;
  final String email;
  const _SuccessState({required this.isRu, required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          width:  96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.success,
            size:  48,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isRu ? 'Письмо отправлено!' : 'Email sent!',
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          isRu
              ? 'Мы отправили ссылку для сброса пароля на\n$email\n\nПроверьте папку «Спам», если письмо не пришло.'
              : 'We sent a password reset link to\n$email\n\nCheck your spam folder if you don\'t see it.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRu ? 'Вернуться ко входу' : 'Back to Sign In'),
          ),
        ),
      ],
    );
  }
}
