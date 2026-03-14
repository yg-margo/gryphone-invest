import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/locale_provider.dart';
import '../../../data/providers/portfolio_provider.dart';
import '../../../data/providers/theme_provider.dart';
import '../../../responsive.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  late final TextEditingController _nameCtrl, _surnameCtrl;
  final _picker = ImagePicker();

  @override
  void initState() { super.initState(); final auth = context.read<AuthProvider>(); _nameCtrl = TextEditingController(text: auth.name); _surnameCtrl = TextEditingController(text: auth.surname); }
  @override
  void dispose() { _nameCtrl.dispose(); _surnameCtrl.dispose(); super.dispose(); }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
      if (file == null || !mounted) return;
      context.read<AuthProvider>().updateAvatar(await file.readAsBytes());
    } catch (_) {}
  }

  void _toggleEdit() {
    final auth = context.read<AuthProvider>();
    if (_editing) auth.updateProfile(name: _nameCtrl.text.trim(), surname: _surnameCtrl.text.trim());
    setState(() => _editing = !_editing);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();
    final portfolio = context.read<PortfolioProvider>();
    final isRu = locale.isRussian, isDark = Theme.of(context).brightness == Brightness.dark, desktop = AppBreakpoints.isDesktop(context);
    final settings = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _section(isRu ? 'Настройки' : 'Settings'),
      _tile(isDark, Icons.dark_mode_outlined, AppStrings.get('darkMode', isRussian: isRu), theme.isDark ? AppStrings.get('darkModeOn', isRussian: isRu) : AppStrings.get('darkModeOff', isRussian: isRu), Switch(value: theme.isDark, onChanged: (_) => theme.toggleTheme(), activeThumbColor: AppColors.primary)),
      _tile(isDark, Icons.language, AppStrings.get('language', isRussian: isRu), isRu ? 'Русский' : 'English', FilledButton.tonal(onPressed: locale.toggleLocale, child: Text(isRu ? 'EN' : 'RU'))),
      const SizedBox(height: 12),
      _section(AppStrings.get('portfolioSection', isRussian: isRu)),
      _tile(isDark, Icons.refresh, AppStrings.get('resetPortfolioTitle', isRussian: isRu), AppStrings.get('resetPortfolioDesc', isRussian: isRu), const Icon(Icons.chevron_right), onTap: () => _showResetDialog(portfolio, isRu)),
      const SizedBox(height: 12),
      _section(AppStrings.get('about', isRussian: isRu)),
      _tile(isDark, Icons.info_outline, AppStrings.get('appVersion', isRussian: isRu), AppConstants.appVersion, const SizedBox.shrink()),
      _tile(isDark, Icons.warning_amber_outlined, AppStrings.get('disclaimer', isRussian: isRu), AppStrings.get('disclaimerText', isRussian: isRu), const SizedBox.shrink()),
      const SizedBox(height: 12),
      _section(isRu ? 'Аккаунт' : 'Account'),
      _tile(isDark, Icons.logout, isRu ? 'Выйти из аккаунта' : 'Sign Out', isRu ? 'Вернуться к экрану входа' : 'Return to login screen', const Icon(Icons.chevron_right), onTap: () => _showLogoutDialog(auth, isRu), iconColor: AppColors.danger),
    ]);

    return Scaffold(
      appBar: AppBar(title: Text(isRu ? 'Профиль' : 'Profile')),
      body: SingleChildScrollView(
        padding: AppBreakpoints.pagePadding(context),
        child: ResponsiveContent(
          child: desktop ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 4, child: _profileCard(auth, isDark, isRu)), const SizedBox(width: 20), Expanded(flex: 6, child: settings)]) : Column(children: [_profileCard(auth, isDark, isRu), const SizedBox(height: 20), settings]),
        ),
      ),
    );
  }

  Widget _profileCard(AuthProvider auth, bool isDark, bool isRu) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: isDark ? AppColors.darkCard : AppColors.lightSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
    child: Column(children: [
      Stack(alignment: Alignment.bottomRight, children: [
        Container(
          width: 110, height: 110,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: auth.avatarBytes == null ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]) : null),
          child: ClipOval(child: auth.avatarBytes != null ? Image.memory(auth.avatarBytes!, fit: BoxFit.cover) : Center(child: Text(auth.initials, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700)))),
        ),
        PopupMenuButton<String>(
          onSelected: (value) { if (value == 'camera') _pick(ImageSource.camera); if (value == 'gallery') _pick(ImageSource.gallery); if (value == 'remove') auth.removeAvatar(); },
          itemBuilder: (_) => [
            if (!kIsWeb) PopupMenuItem(value: 'camera', child: Text(isRu ? 'Сделать фото' : 'Take photo')),
            PopupMenuItem(value: 'gallery', child: Text(isRu ? 'Выбрать из галереи' : 'Choose from gallery')),
            if (auth.avatarBytes != null) PopupMenuItem(value: 'remove', child: Text(isRu ? 'Удалить фото' : 'Remove photo')),
          ],
          child: Container(width: 34, height: 34, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18)),
        )
      ]),
      const SizedBox(height: 18),
      if (_editing) ...[
        TextField(controller: _nameCtrl, textAlign: TextAlign.center, decoration: InputDecoration(hintText: isRu ? 'Имя' : 'First name')),
        const SizedBox(height: 10),
        TextField(controller: _surnameCtrl, textAlign: TextAlign.center, decoration: InputDecoration(hintText: isRu ? 'Фамилия' : 'Last name')),
      ] else ...[
        Text(auth.fullName.isEmpty ? (isRu ? 'Без имени' : 'No name') : auth.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withOpacity(.12), borderRadius: BorderRadius.circular(20)), child: Text(auth.loginName.isNotEmpty ? '@${auth.loginName}' : '@${AuthProvider.defaultLogin}', style: const TextStyle(color: AppColors.primaryLight))),
      ],
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _toggleEdit, icon: Icon(_editing ? Icons.check_rounded : Icons.edit_outlined), label: Text(_editing ? (isRu ? 'Сохранить' : 'Save') : (isRu ? 'Редактировать' : 'Edit profile')))),
    ]),
  );

  Widget _section(String title) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.primaryLight)));

  Widget _tile(bool isDark, IconData icon, String title, String subtitle, Widget trailing, {VoidCallback? onTap, Color? iconColor}) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: isDark ? AppColors.darkCard : AppColors.lightSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (iconColor ?? AppColors.primary).withOpacity(.12), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor ?? AppColors.primaryLight)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title), Text(subtitle, style: const TextStyle(fontSize: 12))])),
        trailing,
      ]),
    ),
  );

  void _showResetDialog(PortfolioProvider provider, bool isRu) => showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(AppStrings.get('resetPortfolioTitle', isRussian: isRu)), content: Text(AppStrings.get('resetPortfolioSubtitle', isRussian: isRu)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.get('cancel', isRussian: isRu))), ElevatedButton(onPressed: () { provider.resetPortfolio(); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), child: Text(AppStrings.get('reset', isRussian: isRu)))]));

  void _showLogoutDialog(AuthProvider auth, bool isRu) => showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(isRu ? 'Выйти?' : 'Sign out?'), content: Text(isRu ? 'Вы будете перенаправлены на экран входа.' : 'You will be redirected to the login screen.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.get('cancel', isRussian: isRu))), ElevatedButton(onPressed: () async { Navigator.pop(ctx); await auth.logout(); if (!mounted) return; Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), child: Text(isRu ? 'Выйти' : 'Sign Out'))]));
}
