# Contrato da API — Marketplace Rural

O aplicativo Flutter usa **o mesmo backend PHP do site** (pasta `backend/`, publicada em `https://buzzcodex.com.br/backend`) e o mesmo banco MySQL. Não há API separada para o app.

- Autenticação: sessão PHP. O login devolve o cookie `PHPSESSID`, que o app guarda e reenvia.
- Entrada: campos de formulário (`application/x-www-form-urlencoded`); arquivos em multipart.
- Saída: JSON com `sucesso`. Em erro: `{ "sucesso": false, "mensagem": "..." }`.
- Configuração no app: `lib/core/config/app_config.dart` e rotas em `lib/core/network/endpoints.dart`.

## Rotas existentes

| Rota | Método | Campos | Resposta |
|---|---|---|---|
| `auth/login.php` | POST | `email, senha` | `{ sucesso, redirect }` + cookie |
| `auth/cadastro.php` | POST | `nome, email, telefone, endereco?, senha, confirmarSenha, tipoConta` | 201 (não abre sessão) |
| `auth/sessao.php` | GET | — | `{ usuario }` |
| `auth/logout.php` | GET | — | encerra a sessão |
| `auth/atualizar_perfil.php` | POST | `nome, telefone, cidade` | `{ usuario }` |
| `usuarios/tipo.php` | POST | `tipo` | `{ tipo_acesso }` |
| `produtos/listar.php` | GET | `escopo=catalogo\|meus, categoria, busca` | `{ produtos }` |
| `produtos/cadastrar.php` | POST multipart | `nome, categoria, preco, estoque, descricao, imagem?` | 201 `{ produto }` |
| `produtos/editar.php` | POST multipart | `id` + campos acima; `imagem` substitui a foto | `{ produto }` |
| `produtos/excluir.php` | POST | `id` (exclusão lógica: status `inativo`) | `{}` |
| `produtos/estoque.php` | GET / POST | POST: `id, quantidade` (novo saldo) | `{ itens }` / `{ item }` |
| `pedidos/listar.php` | GET | — | `{ pedidos }` (com `papel`, `contraparte`, `transicoes`) |
| `pedidos/criar.php` | POST | `anuncio_id, quantidade` (baixa o estoque) | 201 `{ pedido_id }` |
| `pedidos/atualizar.php` | POST | `id, status` | `{}` |
| `favoritos/listar.php` | GET | — | `{ produtos }` |
| `favoritos/atualizar.php` | POST | `acao=adicionar\|remover\|limpar, anuncio_id` | `{}` |
| `gestao/resumo.php`, `iot/*` | — | usados pelo site; o app não os usa | — |

## Valores do banco usados pelo app

- Categorias de produto: `hortalicas, frutas, graos, laticinios, carnes, flores`.
- Status do anúncio: `ativo` (visível), `pausado` e `inativo` (excluído).
- Status do pedido: `recebido` → `preparo` (o app chama de "Em preparação") → `entregue` ("Concluído"); `cancelado` em qualquer etapa aberta; `negociacao` aparece como "Recebido".
- Transições: produtor `recebido → preparo | cancelado`, `preparo → entregue | cancelado`; comprador `recebido → cancelado`.

## Lacunas (o app mostra "aguardando o servidor")

Rotas que não existem no backend: detalhe de produto e de pedido (o app busca nas listas), histórico de estoque, alteração de senha, recuperação de senha, fazenda, negociações e notificações.

Diferenças conhecidas:

- O backend guarda uma foto por produto.
- Unidade de venda, estoque mínimo e localização do anúncio não são gravados nem filtrados pelo servidor.
- Pausar produto (`disponivel = false`) não é persistido na edição.
- "A caminho" não existe no banco.
