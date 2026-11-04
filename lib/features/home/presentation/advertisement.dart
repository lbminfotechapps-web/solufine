import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/theme/app_dynamic_colors.dart';
import '../doman/home_entity/advertisement_entity.dart';
import 'quick_aceess_bloc/quick_acess_bloc.dart';
import 'quick_aceess_bloc/quick_access_event.dart';
import 'quick_aceess_bloc/quick_access_state.dart';

class Advertisement extends StatefulWidget {
  const Advertisement({super.key});

  @override
  State<Advertisement> createState() => _AdvertisementState();
}

class _AdvertisementState extends State<Advertisement> {
  final _search = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _searchDebounce?.cancel();
    context.read<QuickAcessBloc>().add(
      AdvertisementEvent('', _search.text.trim()),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _load();
    });
  }

  Future<void> _refresh() async {
    final bloc = context.read<QuickAcessBloc>();
    final completed = bloc.stream.firstWhere(
      (state) =>
          state.advertisementStatus == QuickAccessStatus.success ||
          state.advertisementStatus == QuickAccessStatus.failure,
      orElse: () => bloc.state,
    );
    _load();
    await completed;
  }

  Widget _scrollableStatus(Widget child) => CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      SliverFillRemaining(hasScrollBody: false, child: Center(child: child)),
    ],
  );

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Uri? _mediaUri(String path) {
    final value = path.trim();
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    if (uri.hasScheme)
      return ['http', 'https'].contains(uri.scheme) ? uri : null;
    final uploads = Uri.parse(ApiClient.imageBaseUrl);
    if (value.startsWith('/')) return uploads.resolve(value);
    if (value.startsWith('uploads/')) return uploads.resolve('../$value');
    return uploads.resolve(value);
  }

  Future<void> _open(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      /* Show the same feedback when launching fails. */
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open advertisement')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: CustomAppBar(
        title: 'Advertisements',

        showBackButton: true,

        onBackTap: () {
          context.go(AppRouter.home);
        },
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search advertisements',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (_) => _load(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: BlocBuilder<QuickAcessBloc, QuickAccessState>(
                buildWhen: (p, c) =>
                    p.advertisementStatus != c.advertisementStatus ||
                    p.advertisementData != c.advertisementData ||
                    p.advertisementError != c.advertisementError,
                builder: (context, state) {
                  if (state.advertisementStatus == QuickAccessStatus.initial ||
                      state.advertisementStatus == QuickAccessStatus.loading) {
                    return _scrollableStatus(const CircularProgressIndicator());
                  }
                  if (state.advertisementStatus == QuickAccessStatus.failure) {
                    return _scrollableStatus(
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.advertisementError.isEmpty
                                  ? 'Unable to load advertisements'
                                  : state.advertisementError,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _load,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final items =
                      state.advertisementData?.result ??
                      const <AdvertisementItemEntity>[];
                  if (items.isEmpty)
                    return _scrollableStatus(
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No advertisements found'),
                          TextButton(
                            onPressed: _load,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    );
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _advertisementCard(items[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _advertisementCard(AdvertisementItemEntity item) {
    final uri = _mediaUri(item.advertisementPath);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (uri != null && !item.isVideo && !item.isNews)
            Image.network(
              uri.toString(),
              height: 180,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox(
                height: 100,
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ListTile(
            leading: Icon(
              item.isVideo
                  ? Icons.play_circle_outline
                  : item.isNews
                  ? Icons.newspaper
                  : Icons.campaign_outlined,
            ),
            title: Text(
              item.advertisementTitle.isEmpty
                  ? 'Advertisement'
                  : item.advertisementTitle,
            ),
            subtitle: item.advertisementType.isEmpty
                ? null
                : Text(item.advertisementType),
            trailing: uri == null ? null : const Icon(Icons.open_in_new),
            onTap: uri == null ? null : () => _open(uri),
          ),
        ],
      ),
    );
  }
}
