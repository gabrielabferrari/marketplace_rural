import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import 'state_views.dart';

/// Versão compacta do [AsyncView] para blocos dentro de uma tela (ex.: uma
/// vitrine na página inicial). Falhas aparecem como um aviso discreto, sem
/// ocupar a tela inteira.
class InlineAsync<T> extends StatefulWidget {
  const InlineAsync({
    super.key,
    required this.load,
    required this.builder,
    this.height = 120,
    this.emptyMessage,
    this.isEmpty,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;
  final double height;
  final String? emptyMessage;
  final bool Function(T data)? isEmpty;

  @override
  State<InlineAsync<T>> createState() => InlineAsyncState<T>();
}

class InlineAsyncState<T> extends State<InlineAsync<T>> {
  late Future<T> _future = widget.load();

  void reload() => setState(() => _future = widget.load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            height: widget.height,
            child: const Center(
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
            ),
          );
        }
        if (snapshot.hasError) {
          final e = ApiException.from(snapshot.error!);
          return _Notice(
            icon: e.isPendingBackend ? Icons.construction_rounded : Icons.cloud_off_rounded,
            color: e.isPendingBackend ? context.palette.info : context.palette.danger,
            text: e.isPendingBackend
                ? 'Aguardando o serviço no servidor (${e.endpoint ?? 'API'}).'
                : e.message,
            onRetry: reload,
          );
        }
        final data = snapshot.data as T;
        if (widget.isEmpty?.call(data) ?? false) {
          return _Notice(
            icon: Icons.inbox_outlined,
            color: context.palette.earth,
            text: widget.emptyMessage ?? 'Nada por aqui ainda.',
          );
        }
        return widget.builder(context, data);
      },
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.text, this.onRetry});

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: context.text.bodySmall)),
          if (onRetry != null)
            IconButton(
              tooltip: 'Tentar novamente',
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
            ),
        ],
      ),
    );
  }
}

/// Carrega dados de forma assíncrona e trata carregamento, erro, vazio e
/// atualização (puxar para baixo) de forma padronizada.
///
/// Use uma [GlobalKey<AsyncViewState>] para recarregar de fora.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.isEmpty,
    this.empty,
    this.feature,
    this.loadingMessage,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload)
      builder;

  /// Quando retorna `true`, exibe [empty] no lugar do conteúdo.
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final String? feature;
  final String? loadingMessage;

  @override
  State<AsyncView<T>> createState() => AsyncViewState<T>();
}

class AsyncViewState<T> extends State<AsyncView<T>> {
  T? _data;
  Object? _error;
  bool _loading = true;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final request = ++_request;
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final data = await widget.load();
      if (!mounted || request != _request) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_loading) {
      child = LoadingView(key: const ValueKey('loading'), message: widget.loadingMessage);
    } else if (_error != null && _data == null) {
      child = _scrollable(ErrorView(
        key: const ValueKey('error'),
        error: _error!,
        onRetry: reload,
        feature: widget.feature,
      ));
    } else {
      final data = _data as T;
      final empty = widget.isEmpty?.call(data) ?? false;
      child = empty && widget.empty != null
          ? _scrollable(KeyedSubtree(key: const ValueKey('empty'), child: widget.empty!))
          : KeyedSubtree(
              key: const ValueKey('data'),
              child: widget.builder(context, data, reload),
            );
    }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: child);
  }

  /// Permite "puxar para atualizar" também nos estados de erro e vazio.
  Widget _scrollable(Widget child) => RefreshIndicator(
        onRefresh: reload,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: child,
            ),
          ),
        ),
      );
}
