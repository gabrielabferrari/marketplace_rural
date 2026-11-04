import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/farm.dart';
import '../../repositories/farm_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';

class FarmFormScreen extends StatefulWidget {
  const FarmFormScreen({super.key, this.farm});

  final Farm? farm;

  @override
  State<FarmFormScreen> createState() => _FarmFormScreenState();
}

class _FarmFormScreenState extends State<FarmFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.farm?.nome);
  late final _city = TextEditingController(text: widget.farm?.cidade);
  late final _state = TextEditingController(text: widget.farm?.estado);
  late final _address = TextEditingController(text: widget.farm?.endereco);
  late final _total = TextEditingController(
      text: widget.farm?.areaTotalHa == null ? '' : Formatters.quantity(widget.farm!.areaTotalHa!));
  late final _production = TextEditingController(
      text: widget.farm?.areaProducaoHa == null ? '' : Formatters.quantity(widget.farm!.areaProducaoHa!));
  late final _crops = TextEditingController(text: widget.farm?.culturas.join(', '));
  late final _description = TextEditingController(text: widget.farm?.descricao);
  late final _ie = TextEditingController(text: widget.farm?.inscricaoEstadual);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _city, _state, _address, _total, _production, _crops, _description, _ie]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _opt(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
  double? _num(TextEditingController c) => c.text.trim().isEmpty ? null : Validators.parseDecimal(c.text);

  String? _optionalArea(String? v) =>
      (v == null || v.trim().isEmpty) ? null : Validators.positiveDecimal(v, 'A área');

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final total = _num(_total);
    final production = _num(_production);
    if (total != null && production != null && production > total) {
      AppFeedback.info(context, 'A área de produção não pode ser maior que a área total.');
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<FarmRepository>().save(Farm(
            id: widget.farm?.id,
            nome: _name.text.trim(),
            cidade: _opt(_city),
            estado: _opt(_state)?.toUpperCase(),
            endereco: _opt(_address),
            areaTotalHa: total,
            areaProducaoHa: production,
            culturas: _crops.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
            descricao: _opt(_description),
            inscricaoEstadual: _opt(_ie),
          ));
      if (!mounted) return;
      AppFeedback.success(context, 'Informações da fazenda salvas.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.farm == null ? 'Cadastrar fazenda' : 'Editar fazenda')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            PageContainer(
              maxWidth: 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Nome da propriedade',
                    controller: _name,
                    hint: 'Ex.: Sítio Boa Esperança',
                    icon: Icons.agriculture_outlined,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => Validators.required(v, 'O nome'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: AppTextField(
                          label: 'Cidade',
                          controller: _city,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => Validators.required(v, 'A cidade'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'UF',
                          controller: _state,
                          maxLength: 2,
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) => Validators.required(v, 'A UF'),
                        ),
                      ),
                    ],
                  ),
                  AppTextField(
                    label: 'Endereço / acesso (opcional)',
                    controller: _address,
                    hint: 'Estrada, km, bairro rural…',
                    icon: Icons.signpost_outlined,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Área total',
                          controller: _total,
                          suffixText: 'ha',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: decimalInputFormatters,
                          validator: _optionalArea,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Área de produção',
                          controller: _production,
                          suffixText: 'ha',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: decimalInputFormatters,
                          validator: _optionalArea,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Culturas',
                    controller: _crops,
                    hint: 'Separe por vírgula: café, milho, hortaliças',
                    icon: Icons.eco_outlined,
                    helper: 'Informe o que é cultivado ou criado na propriedade.',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Inscrição estadual (opcional)',
                    controller: _ie,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Descrição (opcional)',
                    controller: _description,
                    hint: 'Práticas de cultivo, certificações, história da propriedade…',
                    maxLines: 4,
                    minLines: 3,
                    maxLength: 1000,
                  ),
                  const SizedBox(height: 16),
                  AppButton(label: 'Salvar', icon: Icons.check_rounded, loading: _saving, onPressed: _save),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
