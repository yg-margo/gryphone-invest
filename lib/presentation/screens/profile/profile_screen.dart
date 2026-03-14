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
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _surnameCtrl;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl    = TextEditingController(text: auth.name);
    _surnameCtrl = TextEditingController(text: auth.surname);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      await _pickFromSource(ImageSource.gallery);
      return;
    }
    final isRu = context.read<LocaleProvider>().isRussian;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: AppColors.primaryLight),
                ),
                title: Text(isRu ? 'Сделать фото' : 'Take photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromSource(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: AppColors.primaryLight),
                ),
                title: Text(isRu ? 'Выбрать из галереи' : 'Choose from gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromSource(ImageSource.gallery);
                },
              ),
              if (context.read<AuthProvider>().avatarBytes != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline, color: AppColors.danger),
                  ),
                  title: Text(
                    isRu ? 'Удалить фото' : 'Remove photo',
                    style: const TextStyle(color: AppColors.danger),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<AuthProvider>().removeAvatar();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromSource(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source:       source,
        maxWidth:     512,
        maxHeight:    512,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) context.read<AuthProvider>().updateAvatar(bytes);
    } catch (_) {
      if (mounted) {
        final isRu = context.read<LocaleProvider>().isRussian;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isRu
              ? 'Не удалось загрузить фото. Проверьте разрешения.'
              : 'Could not load photo. Check permissions.'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  void _toggleEdit() {
    if (_isEditing) {
      context.read<AuthProvider>().updateProfile(
        name:    _nameCtrl.text.trim(),
        surname: _surnameCtrl.text.trim(),
      );
    }
    setState(() => _isEditing = !_isEditing);
  }

  @override
  Widget build(BuildContext context) {
    final isDark            = Theme.of(context).brightness == Brightness.dark;
    final auth              = context.watch<AuthProvider>();
    final themeProvider     = context.watch<ThemeProvider>();
    final localeProvider    = context.watch<LocaleProvider>();
    final portfolioProvider = context.read<PortfolioProvider>();
    final isRu              = localeProvider.isRussian;

    return Scaffold(
      appBar: AppBar(title: Text(isRu ? 'Профиль' : 'Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileCard(
            auth:         auth,
            isDark:       isDark,
            isRu:         isRu,
            isEditing:    _isEditing,
            nameCtrl:     _nameCtrl,
            surnameCtrl:  _surnameCtrl,
            onPickImage:  _pickImage,
            onEditToggle: _toggleEdit,
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: AppStrings.get('appearance', isRussian: isRu)),
          _SettingsTile(
            isDark:   isDark,
            icon:     Icons.dark_mode_outlined,
            title:    AppStrings.get('darkMode', isRussian: isRu),
            subtitle: themeProvider.isDark
                ? AppStrings.get('darkModeOn',  isRussian: isRu)
                : AppStrings.get('darkModeOff', isRussian: isRu),
            trailing: Switch(
              value:     themeProvider.isDark,
              onChanged: (_) => themeProvider.toggleTheme(),
              activeThumbColor: AppColors.primary,
            ),
          ),
          _LanguageSwitcherTile(
            isDark:    isDark,
            isRussian: isRu,
            onToggle:  () => localeProvider.toggleLocale(),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: AppStrings.get('portfolioSection', isRussian: isRu)),
          _SettingsTile(
            isDark:   isDark,
            icon:     Icons.refresh,
            title:    AppStrings.get('resetPortfolioTitle', isRussian: isRu),
            subtitle: AppStrings.get('resetPortfolioDesc',  isRussian: isRu),
            trailing: const Icon(Icons.chevron_right),
            onTap:    () => _showResetDialog(context, portfolioProvider, isRu),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: AppStrings.get('about', isRussian: isRu)),
          _SettingsTile(
            isDark:   isDark,
            icon:     Icons.info_outline,
            title:    AppStrings.get('appVersion', isRussian: isRu),
            subtitle: AppConstants.appVersion,
            trailing: const SizedBox.shrink(),
          ),
          _SettingsTile(
            isDark:   isDark,
            icon:     Icons.warning_amber_outlined,
            title:    AppStrings.get('disclaimer',     isRussian: isRu),
            subtitle: AppStrings.get('disclaimerText', isRussian: isRu),
            trailing: const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: isRu ? 'Аккаунт' : 'Account'),
          _SettingsTile(
            isDark:    isDark,
            icon:      Icons.logout,
            iconColor: AppColors.danger,
            title:     isRu ? 'Выйти из аккаунта' : 'Sign Out',
            subtitle:  isRu ? 'Вернуться к экрану входа' : 'Return to login screen',
            trailing:  const Icon(Icons.chevron_right),
            onTap:     () => _showLogoutDialog(context, auth, isRu),
          ),
          const SizedBox(height: 28),
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    width: 52, height: 52, fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppStrings.get('appName', isRussian: isRu),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.get('appTagline', isRussian: isRu),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showResetDialog(
    BuildContext context,
    PortfolioProvider provider,
    bool isRu,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:   Text(AppStrings.get('resetPortfolioTitle',    isRussian: isRu)),
        content: Text(AppStrings.get('resetPortfolioSubtitle', isRussian: isRu)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.get('cancel', isRussian: isRu)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.resetPortfolio();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:         Text(AppStrings.get('resetSuccess', isRussian: isRu)),
                backgroundColor: AppColors.success,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(AppStrings.get('reset', isRussian: isRu)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    AuthProvider auth,
    bool isRu,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:   Text(isRu ? 'Выйти?' : 'Sign out?'),
        content: Text(
          isRu
              ? 'Вы будете перенаправлены на экран входа.'
              : 'You will be redirected to the login screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.get('cancel', isRussian: isRu)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(isRu ? 'Выйти' : 'Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final AuthProvider          auth;
  final bool                  isDark;
  final bool                  isRu;
  final bool                  isEditing;
  final TextEditingController nameCtrl;
  final TextEditingController surnameCtrl;
  final VoidCallback          onPickImage;
  final VoidCallback          onEditToggle;

  const _ProfileCard({
    required this.auth,
    required this.isDark,
    required this.isRu,
    required this.isEditing,
    required this.nameCtrl,
    required this.surnameCtrl,
    required this.onPickImage,
    required this.onEditToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color:        isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: auth.avatarBytes == null
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin:  Alignment.topLeft,
                          end:    Alignment.bottomRight,
                        )
                      : null,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.45),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:      AppColors.primary.withOpacity(0.25),
                      blurRadius: 16,
                      offset:     const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: auth.avatarBytes != null
                      ? Image.memory(auth.avatarBytes!, fit: BoxFit.cover)
                      : Center(
                          child: Text(
                            auth.initials,
                            style: const TextStyle(
                              color:      Colors.white,
                              fontSize:   30,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
              ),
              GestureDetector(
                onTap: onPickImage,
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color:  AppColors.primary,
                    shape:  BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:      AppColors.primary.withOpacity(0.4),
                        blurRadius: 6,
                        offset:     const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white, size: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isEditing) ...[
            TextField(
              controller: nameCtrl,
              textAlign:  TextAlign.center,
              style:      Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19),
              decoration: InputDecoration(
                hintText: isRu ? 'Имя' : 'First name',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: surnameCtrl,
              textAlign:  TextAlign.center,
              style:      Theme.of(context).textTheme.titleMedium,
              decoration: InputDecoration(
                hintText: isRu ? 'Фамилия' : 'Last name',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ] else ...[
            Text(
              auth.fullName.isEmpty ? (isRu ? 'Без имени' : 'No name') : auth.fullName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color:        AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '@${AuthProvider.defaultLogin}',
                style: const TextStyle(
                  color:      AppColors.primaryLight,
                  fontSize:   13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onEditToggle,
            icon:  Icon(isEditing ? Icons.check_rounded : Icons.edit_outlined, size: 16),
            label: Text(
              isEditing
                  ? (isRu ? 'Сохранить'     : 'Save')
                  : (isRu ? 'Редактировать' : 'Edit profile'),
              style: const TextStyle(fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side:    const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 11, fontWeight: FontWeight.w700,
              letterSpacing: 1.2, color: AppColors.primaryLight,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final bool       isDark;
  final IconData   icon;
  final Color?     iconColor;
  final String     title;
  final String     subtitle;
  final Widget     trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primaryLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:  const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        isDark ? AppColors.darkCard : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:        (iconColor ?? AppColors.primary).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14)),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _LanguageSwitcherTile extends StatelessWidget {
  final bool         isDark;
  final bool         isRussian;
  final VoidCallback onToggle;

  const _LanguageSwitcherTile({
    required this.isDark,
    required this.isRussian,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:        AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.language, color: AppColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isRussian ? 'Язык' : 'Language',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14)),
                Text(isRussian ? 'Русский' : 'English',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color:        isDark ? AppColors.darkElevated : AppColors.lightCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _LangButton(label: 'RU', isSelected: isRussian,  onTap: isRussian  ? null : onToggle),
                const SizedBox(width: 4),
                _LangButton(label: 'EN', isSelected: !isRussian, onTap: !isRussian ? null : onToggle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String        label;
  final bool          isSelected;
  final VoidCallback? onTap;

  const _LangButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:        isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:      isSelected ? Colors.white : AppColors.primaryLight,
            fontWeight: FontWeight.w700,
            fontSize:   13,
          ),
        ),
      ),
    );
  }
}
