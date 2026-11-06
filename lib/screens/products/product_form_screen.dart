import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/preferences_controller.dart';
import '../../controllers/session_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';

/// Cadastro e edição de produto (somente produtores — verificado na rota
/// e no repositório).
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.nome);
  late final _description = TextEditingController(text: widget.product?.descricao);
  late final _price = TextEditingController(
      text: widget.product == null ? '' : Formatters.decimalInput(widget.product!.preco));
  late final _quantity = TextEditingController(
      text: widget.product == null ? '' : Formatters.quantity(widget.product!.quantidade));
  late final _location = TextEditingController(text: widget.product?.localizacao);

  late ProductCategory? _category = widget.product?.categoria;
  late String _unit = widget.product?.unidade ?? 'kg';
  late bool _available = widget.product?.disponivel ?? true;
  late final List<String> _images = [...?widget.product?.imagens];
  /// Foto escolhida e ainda não enviada: vai junto com o cadastro/edição.
  UploadFile? _pendingImage;
  bool _saving = false;
  bool _dirty = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_location.text.isEmpty) {
      final user = context.read<SessionController>().user;
      _location.text = user?.cidade ?? context.read<PreferencesController>().region;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _price, _quantity, _location]) {
      c.dispose();
    }
    super.dispose();
  }

  /// O backend guarda uma foto por produto: a nova foto substitui a anterior.
  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 82,
    );
    if (file == null || !mounted) return;
    try {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _images.clear();
        _pendingImage = UploadFile(field: 'imagem', bytes: bytes, filename: file.name);
        _dirty = true;
      });
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      AppFeedback.info(context, 'Revise os campos destacados.');
      return;
    }
    setState(() => _saving = true);
    final base = widget.product;
    final product = Product(
      id: base?.id ?? '',
      produtorId: base?.produtorId ?? context.read<SessionController>().user!.id,
      nome: _name.text.trim(),
      descricao: _description.text.trim(),
      categoria: _category!,
      preco: Validators.parseDecimal(_price.text)!,
      unidade: _unit,
      quantidade: Validators.parseDecimal(_quantity.text)!,
      localizacao: _location.text.trim().isEmpty ? null : _location.text.trim(),
      disponivel: _available,
      imagens: _images,
    );
    try {
      await context.read<ProductRepository>().save(product, imagem: _pendingImage);
      if (!mounted) return;
      AppFeedback.success(context, _isEdit ? 'Produto atualizado.' : 'Produto cadastrado.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    return AppFeedback.confirm(
      context,
      title: 'Descartar alterações?',
      message: 'As informações preenchidas serão perdidas.',
      confirmLabel: 'Descartar',
      destructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Editar produto' : 'Novo produto')),
        body: Form(
          key: _formKey,
          onChanged: () {
            if (!_dirty) setState(() => _dirty = true);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              PageContainer(
                maxWidth: 720,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ImagesField(
                      images: _images,
                      pendingName: _pendingImage?.filename,
                      onAdd: _pickImage,
                      onRemove: (i) => setState(() {
                        if (i < _images.length) {
                          _images.removeAt(i);
                        } else {
                          _pendingImage = null;
                        }
                        _dirty = true;
                      }),
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Nome do produto',
                      controller: _name,
                      hint: 'Ex.: Tomate orgânico',
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => Validators.required(v, 'O nome'),
                      maxLength: 120,
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      label: 'Descrição',
                      controller: _description,
                      hint: 'Como é produzido, variedade, colheita, formas de entrega…',
                      maxLines: 4,
                      minLines: 3,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 8),
                    _LabeledDropdown<ProductCategory>(
                      label: 'Categoria',
                      value: _category,
                      hint: 'Selecione',
                      items: {for (final c in ProductCategory.values) c: c.label},
                      onChanged: (v) => setState(() {
                        _category = v;
                        _dirty = true;
                      }),
                      validator: (v) => v == null ? 'Selecione a categoria.' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Preço',
                            controller: _price,
                            prefixText: 'R\$ ',
                            hint: '0,00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: decimalInputFormatters,
                            validator: Validators.price,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LabeledDropdown<String>(
                            label: 'Unidade de venda',
                            value: _unit,
                            items: {for (final u in productUnits) u: u},
                            onChanged: (v) => setState(() {
                              _unit = v ?? _unit;
                              _dirty = true;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Quantidade disponível',
                      controller: _quantity,
                      hint: '0',
                      suffixText: _unit,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: decimalInputFormatters,
                      validator: Validators.quantity,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Localização',
                      controller: _location,
                      hint: 'Cidade - UF',
                      icon: Icons.location_on_outlined,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => Validators.required(v, 'A localização'),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: SwitchListTile(
                        value: _available,
                        onChanged: (v) => setState(() {
                          _available = v;
                          _dirty = true;
                        }),
                        title: const Text('Disponível para venda'),
                        subtitle: Text(
                          _available
                              ? 'O produto aparece no catálogo para compradores.'
                              : 'O produto fica oculto do catálogo.',
                          style: TextStyle(color: context.palette.muted),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: _isEdit ? 'Salvar alterações' : 'Cadastrar produto',
                      icon: Icons.check_rounded,
                      loading: _saving,
                      onPressed: _save,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.validator,
  });

  final String label;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(label, style: context.text.labelLarge),
        ),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          hint: hint == null ? null : Text(hint!),
          validator: validator,
          borderRadius: BorderRadius.circular(12),
          items: [
            for (final e in items.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ImagesField extends StatelessWidget {
  const _ImagesField({
    required this.images,
    required this.onAdd,
    required this.onRemove,
    this.pendingName,
  });

  final List<String> images;
  final VoidCallback onAdd;

  /// Índices menores que `images.length` são fotos salvas; o índice seguinte
  /// é a foto escolhida ainda não enviada.
  final ValueChanged<int> onRemove;
  final String? pendingName;

  int get _total => images.length + (pendingName == null ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Imagens', style: context.text.labelLarge),
            const Spacer(),
            Text('$_total/${AppConfig.maxProductImages}',
                style: TextStyle(color: context.palette.muted, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < images.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      SizedBox(width: 96, height: 96, child: NetworkThumb(url: images[i])),
                      if (i == 0)
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: StatusBadge(label: 'Capa', color: Colors.white),
                        ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: IconButton.filled(
                          tooltip: 'Remover imagem',
                          visualDensity: VisualDensity.compact,
                          iconSize: 16,
                          style: IconButton.styleFrom(backgroundColor: Colors.black54),
                          onPressed: () => onRemove(i),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              if (pendingName != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: context.palette.accentSoft,
                          border: Border.all(color: context.colors.primary.withValues(alpha: 0.35)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined, color: context.colors.primary),
                            const SizedBox(height: 4),
                            Text(pendingName!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: context.colors.primary, fontSize: 10)),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: IconButton(
                          tooltip: 'Remover foto',
                          visualDensity: VisualDensity.compact,
                          iconSize: 16,
                          style: IconButton.styleFrom(backgroundColor: Colors.black54),
                          onPressed: () => onRemove(images.length),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_total < AppConfig.maxProductImages)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onAdd,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: context.palette.accentSoft,
                      border: Border.all(color: context.colors.primary.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, color: context.colors.primary),
                              const SizedBox(height: 4),
                              Text('Adicionar',
                                  style: TextStyle(color: context.colors.primary, fontSize: 12)),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
