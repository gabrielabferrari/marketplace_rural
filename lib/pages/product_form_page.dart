import 'package:flutter/material.dart';
import '../data/local_store.dart';
import '../models/models.dart';

class ProductFormPage extends StatefulWidget {
  final Product? product;
  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  late TextEditingController name;
  late TextEditingController description;
  late TextEditingController category;
  late TextEditingController price;
  late TextEditingController stock;
  late TextEditingController unit;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    name = TextEditingController(text: p?.name ?? '');
    description = TextEditingController(text: p?.description ?? '');
    category = TextEditingController(text: p?.category ?? '');
    price = TextEditingController(text: p?.price.toString() ?? '');
    stock = TextEditingController(text: p?.stock.toString() ?? '');
    unit = TextEditingController(text: p?.unit ?? 'un.');
  }

  @override
  void dispose() {
    for (final c in [name, description, category, price, stock, unit]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    final parsedPrice = double.tryParse(price.text.replaceAll(',', '.'));
    final parsedStock = int.tryParse(stock.text);

    if (name.text.trim().isEmpty || parsedPrice == null || parsedStock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha nome, preço e estoque corretamente.')));
      return;
    }

    final p = Product(
      id: widget.product?.id ?? 'p_${DateTime.now().millisecondsSinceEpoch}',
      ownerId: LocalStore.instance.currentUser!.id,
      name: name.text.trim(),
      description: description.text.trim(),
      category: category.text.trim().isEmpty ? 'Outros' : category.text.trim(),
      price: parsedPrice,
      stock: parsedStock,
      unit: unit.text.trim().isEmpty ? 'un.' : unit.text.trim(),
    );

    await LocalStore.instance.saveProduct(p);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.product == null ? 'Novo produto' : 'Editar produto')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome do produto')),
          const SizedBox(height: 12),
          TextField(controller: description, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descrição')),
          const SizedBox(height: 12),
          TextField(controller: category, decoration: const InputDecoration(labelText: 'Categoria')),
          const SizedBox(height: 12),
          TextField(controller: price, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Preço')),
          const SizedBox(height: 12),
          TextField(controller: stock, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade em estoque')),
          const SizedBox(height: 12),
          TextField(controller: unit, decoration: const InputDecoration(labelText: 'Unidade (kg, un., caixa...)')),
          const SizedBox(height: 20),
          FilledButton(onPressed: save, child: const Text('Salvar produto')),
        ],
      ),
    );
  }
}