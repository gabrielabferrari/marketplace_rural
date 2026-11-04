import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';

/// Campo de formulário com rótulo acima, validação e opção de senha.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscure = false,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.autofillHints,
    this.onSubmitted,
    this.onChanged,
    this.suffixText,
    this.prefixText,
    this.helper,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscure;
  final int maxLines;
  final int? minLines;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? suffixText;
  final String? prefixText;
  final String? helper;
  final TextCapitalization textCapitalization;
  final int? maxLength;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            widget.label,
            style: context.text.labelLarge?.copyWith(color: context.colors.onSurface),
          ),
        ),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          obscureText: _hidden,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          minLines: widget.minLines,
          enabled: widget.enabled,
          autofillHints: widget.autofillHints,
          onFieldSubmitted: widget.onSubmitted,
          onChanged: widget.onChanged,
          maxLength: widget.maxLength,
          textCapitalization: widget.textCapitalization,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helper,
            helperMaxLines: 2,
            prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: 20),
            suffixText: widget.suffixText,
            prefixText: widget.prefixText,
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? 'Mostrar senha' : 'Ocultar senha',
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(_hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
