import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/news_article.dart';
import '../../../data/providers/locale_provider.dart';
import '../../../data/services/news_service.dart';
import '../../../responsive.dart';
import '../predictions/predictions_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  List<NewsArticle> _articles = [];
  bool _newsLoading = true;
  bool _newsError = false;
  String? _newsErrorMsg;
  String? _lastLangCode;

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
        _newsErrorMsg = articles.isEmpty ? (isRu ? 'Новости не получены от сервера' : 'No articles returned') : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _articles = [];
        _newsLoading = false;
        _newsError = true;
        _newsErrorMsg = e.toString();
      });
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
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          tabs: [
            Tab(icon: const Icon(Icons.newspaper_outlined, size: 18), text: isRu ? 'Новости' : 'News'),
            Tab(icon: const Icon(Icons.auto_awesome_outlined, size: 18), text: isRu ? 'ИИ Прогнозы' : 'AI Signals'),
          ],
        ),
      ),
      body: ResponsiveContent(
        child: TabBarView(
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
      ),
    );
  }
}

class _NewsTab extends StatelessWidget {
  final List<NewsArticle> articles;
  final bool isLoading;
  final bool isError;
  final String? errorMsg;
  final bool isDark;
  final bool isRu;
  final VoidCallback onRefresh;

  const _NewsTab({required this.articles, required this.isLoading, required this.isError, required this.errorMsg, required this.isDark, required this.isRu, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (isError || articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.primaryLight, size: 52),
            const SizedBox(height: 16),
            Text(isRu ? 'Не удалось загрузить новости' : 'Could not load news', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            if (errorMsg != null) ...[const SizedBox(height: 8), Text(errorMsg!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12))],
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded), label: Text(isRu ? 'Попробовать снова' : 'Retry')),
          ]),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1300 ? 3 : constraints.maxWidth >= 800 ? 2 : 1;
        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: GridView.builder(
            padding: AppBreakpoints.pagePadding(context),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: columns == 1 ? 1.7 : 0.95,
            ),
            itemCount: articles.length,
            itemBuilder: (context, index) => _NewsCard(article: articles[index], isDark: isDark, isRu: isRu),
          ),
        );
      },
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsArticle article;
  final bool isDark;
  final bool isRu;

  const _NewsCard({required this.article, required this.isDark, required this.isRu});

  Future<void> _open() async {
    final uri = Uri.tryParse(article.url);
    if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (article.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(article.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 0)),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(article.source, style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  Text(isRu ? article.timeAgoRu : article.timeAgo, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
                ]),
                const SizedBox(height: 10),
                Text(article.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15, height: 1.35)),
                const SizedBox(height: 8),
                if (article.description.isNotEmpty && article.description != article.title)
                  Expanded(
                    child: Text(article.description, maxLines: 5, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.4)),
                  ),
                const SizedBox(height: 10),
                const Row(children: [Text('Read more', style: TextStyle(color: AppColors.primaryLight, fontSize: 13, fontWeight: FontWeight.w600)), SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, color: AppColors.primaryLight, size: 14)]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
