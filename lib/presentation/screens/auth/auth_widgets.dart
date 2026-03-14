import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize:   13,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  final String error;
  final bool   isRu;
  const ErrorBanner({super.key, required this.error, required this.isRu});

  String _localise() {
    switch (error) {
      case 'invalid':
        return isRu
            ? 'Неверный логин или пароль'
            : 'Invalid login or password';
      case 'network':
        return isRu
            ? 'Нет соединения с сервером'
            : 'No connection to server';
      case 'email_not_found':
        return isRu
            ? 'Email не найден'
            : 'Email not found';
      case 'register_error':
        return isRu
            ? 'Ошибка регистрации. Попробуйте позже.'
            : 'Registration error. Try again later.';
      default:
        return error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      margin:  const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColors.danger.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withOpacity(0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _localise(),
              style: const TextStyle(
                color:    AppColors.danger,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
