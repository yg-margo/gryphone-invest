import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/news_article.dart';
import '../../../../data/providers/locale_provider.dart';
import '../../../../data/services/news_service.dart';
import '../predictions/predictions_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _newsErrorLogCooldown = Duration(seconds: 30);

  late TabController _tabCtrl;

  List<NewsArticle> _articles = [];
  bool _newsLoading = true;
  bool _newsError = false;
  String? _newsErrorMsg;
  String? _lastLangCode;

  String? _lastNewsErrorSignature;
  DateTime? _lastNewsErrorAt;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final langCode = context.read<LocaleProvider>().locale.languageCode;
    if (_lastLangCode != langCode) {
      _lastLangCode = langCode;
      _loadNews();
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _logNewsErrorThrottled(Object error) {
    final signature = error.toString();
    final now = DateTime.now();

    final shouldLog = _lastNewsErrorSignature != signature ||
        _lastNewsErrorAt == null ||
        now.difference(_lastNewsErrorAt!) >= _newsErrorLogCooldown;

    if (!shouldLog) {
      return;
    }

    _lastNewsErrorSignature = signature;
    _lastNewsErrorAt = now;

    debugPrint('[DiscoverScreen] news error: $error');
  }

  Future<void> _loadNews() async {
    if (!mounted) return;

    final isRu = context.read<LocaleProvider>().isRussian;

    setState(() {
      _newsLoading = true;
      _newsError = false;
      _newsErrorMsg = null;
    });

    try {
      final articles = await NewsService.fetchNews(isRussian: isRu);
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _newsLoading = false;
        _newsError = articles.isEmpty;
        _newsErrorMsg = articles.isEmpty
            ? (isRu ? 'Новости не получены от сервера' : 'No articles returned')
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _articles = [];
        _newsLoading = false;
        _newsError = true;
        _newsErrorMsg = e.toString();
      });
      _logNewsErrorThrottled(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRu = context.watch<LocaleProvider>().isRussian;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRu ? 'Обзор' : 'Discover'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor:
              isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          tabs: [
            Tab(
              icon: const Icon(Icons.newspaper_outlined, size: 18),
              text: isRu ? 'Новости' : 'News',
            ),
            Tab(
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              text: isRu ? 'ИИ Прогнозы' : 'AI Signals',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _NewsTab(
            articles: _articles,
            isLoading: _newsLoading,
            isError: _newsError,
            errorMsg: _newsErrorMsg,
            isDark: isDark,
            isRu: isRu,
            onRefresh: _loadNews,
          ),
          const PredictionsScreen(),
        ],
      ),
    );
  }
}

// ─── News Tab ─────────────────────────────────────────────────────────────────

class _NewsTab extends StatelessWidget {
  final List<NewsArticle> articles;
  final bool isLoading;
  final bool isError;
  final String? errorMsg;
  final bool isDark;
  final bool isRu;
  final VoidCallback onRefresh;

  const _NewsTab({
    required this.articles,
    required this.isLoading,
    required this.isError,
    required this.errorMsg,
    required this.isDark,
    required this.isRu,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              isRu ? 'Загрузка новостей…' : 'Loading news…',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (isError || articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.primaryLight,
                size: 52,
              ),
              const SizedBox(height: 16),
              Text(
                isRu ? 'Не удалось загрузить новости' : 'Could not load news',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMsg!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(isRu ? 'Попробовать снова' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: articles.length,
        itemBuilder: (context, index) => _NewsCard(
          article: articles[index],
          isDark: isDark,
          isRu: isRu,
        ),
      ),
    );
  }
}

// ─── News Card ────────────────────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  final NewsArticle article;
  final bool isDark;
  final bool isRu;

  const _NewsCard({
    required this.article,
    required this.isDark,
    required this.isRu,
  });

  Future<void> _open() async {
    final uri = Uri.tryParse(article.url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────────────────
            if (article.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  article.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 180,
                      color:
                          isDark ? AppColors.darkElevated : AppColors.lightCard,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
              ),

            // ── Content ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source + time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          article.source,
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        isRu ? article.timeAgoRu : article.timeAgo,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          height: 1.35,
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Description
                  if (article.description.isNotEmpty &&
                      article.description != article.title)
                    Text(
                      article.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            height: 1.4,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 10),

                  // Read more
                  Row(
                    children: [
                      Text(
                        isRu ? 'Читать далее' : 'Read more',
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primaryLight,
                        size: 14,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
