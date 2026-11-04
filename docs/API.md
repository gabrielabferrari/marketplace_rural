# Contrato da API — Marketplace Rural

O aplicativo Flutter conversa **somente** com a API REST em PHP. Nenhuma credencial de banco fica no app.

- URL base: `https://buzzcodex.com.br/api` (alterável com `--dart-define=API_BASE_URL=...`)
- Formato: JSON (UTF-8)
- Autenticação: `Authorization: Bearer <token>` (emitido no login/cadastro)
- Configuração no app: [lib/core/network/endpoints.dart](../lib/core/network/endpoints.dart)

## Envelope de resposta

```json
{ "sucesso": true,  "dados": { ... } }
{ "sucesso": false, "mensagem": "Texto amigável para o usuário" }
```

| HTTP | Como o app trata |
|---|---|
| 200/201 | Sucesso; lê `dados` |
| 400/422 | Erro de validação; exibe `mensagem` |
| 401 | Sessão inválida; o app encerra a sessão e volta ao login |
| 403 | Sem permissão para o tipo de conta |
| 404 com JSON | Registro não encontrado |
| 404 sem JSON, 405 ou 501 | **Endpoint ainda não existe**; a tela mostra "aguardando o servidor" |
| 409 | Conflito (ex.: e-mail já cadastrado) |
| 5xx | Mensagem genérica (detalhes nunca são exibidos) |

Datas no formato MySQL (`2026-11-04 10:30:00`) ou ISO-8601. Números podem vir como string.

---

## Esquema real do banco (SQL recebido)

O servidor usa o esquema do arquivo `buzzcode_marketplace_rural.sql` (exportado em 04/11/2026). Mapeamento aplicado pela API:

| App (contrato) | Banco |
|---|---|
| usuário (`tipo: produtor/comprador`) | `usuarios.tipo_acesso`; senha em `usuarios.senha_hash` |
| produto | `anuncios` (`titulo`→nome, `vendedor_id`→produtor_id, `quantidade_estoque`→quantidade, `status`→disponivel) + `anuncios_fotos` |
| categoria | `anuncios.categoria` em chave minúscula sem acento (`graos`, `hortalicas`, `frutas`, `carnes`, `laticinios`, `bebidas`, `organicos`, `outros`) |
| pedido | `pedidos` + `pedido_itens`; um pedido por produtor |
| status de pedido | `recebido`, `preparo`↔`em_preparacao`, `entregue`↔`concluido`, `cancelado`; `negociacao` aparece como `recebido` |
| favorito | `favoritos` (usuario_id, anuncio_id) |
| fazenda | `fazendas` (`localizacao`→endereco, `area_total`→area_total_ha, `cadastro_estadual`→inscricao_estadual) |

**Sem coluna no banco** (devolvidos nulos/padrão, não são gravados): unidade de venda (`un.`), estoque mínimo, cidade/estado da fazenda, área de produção, culturas, descrição da fazenda, motivo do estoque, observação do pedido, taxa e endereço de entrega.

**Sem tabela no banco** (endpoints não criados; o app mostra "aguardando o servidor"): `negociacoes/*`, `notificacoes/*`, `produtos/historico-estoque.php`, `auth/recuperar-senha.php`.

## ✅ Implementado em `server/api`

Autenticação e perfil (tabela `usuarios`):

| Método | Endpoint | Corpo | `dados` |
|---|---|---|---|
| POST | `auth/login.php` | `email, senha` | `{ token, usuario }` |
| POST | `auth/cadastro.php` | `nome, email, telefone, senha, confirmarSenha, tipo` | `{ token, usuario }` |
| GET | `auth/me.php` | — | `{ usuario }` |
| POST | `auth/logout.php` | — | `null` |
| POST | `auth/alterar-senha.php` | `senhaAtual, novaSenha` | `{ token }` (novo) |
| PUT | `usuarios/atualizar.php` | `nome, telefone` | `{ usuario }` |

`usuario` = `{ id, nome, email, telefone, tipo: "produtor"|"comprador" }`. A senha nunca é retornada.

**Token**: HMAC-SHA256 com validade de 30 dias. Ele inclui uma "versão da senha", então trocar a senha invalida todos os tokens antigos. Não há revogação individual (isso exigiria uma tabela de sessões).

---

Produtos, estoque, pedidos, favoritos e fazenda estão implementados em `server/api` sobre o esquema real (ver mapeamento acima). Os endpoints abaixo sem tabela no banco não existem; o app mostra o aviso de servidor pendente, **sem dados simulados**.

Status de validação: sintaxe PHP verificada (`php -l`); **a execução contra o MySQL ainda não foi testada** neste ambiente.

Todas as rotas exigem token. **O servidor deve verificar o tipo de conta pelo banco**, usando `exigir_tipo()` de `lib/token.php`.

### Produtos e estoque (escrita: somente `produtor`)

| Método | Endpoint | Parâmetros / corpo |
|---|---|---|
| GET | `produtos/listar.php` | `?busca&categoria&cidade&meus=1&disponiveis=1&ordem=recentes\|menorPreco\|maiorPreco\|nome&limite` |
| GET | `produtos/detalhe.php` | `?id` |
| POST | `produtos/cadastrar.php` | produto (abaixo) |
| PUT | `produtos/editar.php` | produto com `id`; só o dono pode editar |
| DELETE | `produtos/excluir.php` | `?id`; só o dono pode excluir |
| POST | `produtos/imagem.php` | multipart, campo `imagem` → `dados: { url }` |
| POST | `produtos/estoque.php` | `id, quantidade, motivo?` |
| GET | `produtos/historico-estoque.php` | `?id` → `[{ quantidade_anterior, quantidade_nova, motivo, data }]` |

Produto: `id, produtor_id, produtor_nome, nome, descricao, categoria, preco, unidade, quantidade, localizacao, disponivel, imagens[], estoque_minimo?, criado_em`.
Categorias usadas no app: Grãos, Hortaliças, Frutas, Carnes, Laticínios, Bebidas, Orgânicos, Outros.

### Pedidos

| Método | Endpoint | Corpo |
|---|---|---|
| GET | `pedidos/listar.php` | `?status`. O comprador vê os pedidos que fez; o produtor, os que recebeu |
| GET | `pedidos/detalhe.php` | `?id` (apenas participantes) |
| POST | `pedidos/criar.php` | `itens: [{ produto_id, quantidade }], negociacao_id?` (somente `comprador`; baixa o estoque em transação) |
| POST | `pedidos/atualizar.php` | `id, status` |

Pedido: `id, status, comprador_id, comprador_nome, produtor_id, produtor_nome, itens[{produto_id, nome, quantidade, preco_unitario, unidade, imagem}], total, taxa_entrega?, endereco_entrega?, criado_em, historico[{status, data}]`.

Status: `recebido → em_preparacao → a_caminho → concluido`, mais `cancelado`. Transições permitidas (repetir no servidor):

| Atual | Produtor | Comprador |
|---|---|---|
| recebido | em_preparacao, cancelado | cancelado |
| em_preparacao | a_caminho, cancelado | — |
| a_caminho | concluido | concluido |

### Negociações

| Método | Endpoint | Corpo |
|---|---|---|
| GET | `negociacoes/listar.php` | `?status` |
| GET | `negociacoes/detalhe.php` | `?id` |
| POST | `negociacoes/criar.php` | `produto_id, quantidade, preco_proposto, mensagem?` (somente `comprador`) |
| POST | `negociacoes/responder.php` | `id, acao: aceitar\|recusar\|contraproposta\|cancelar, preco_proposto?, quantidade?, mensagem?` |

Negociação: `id, produto_id, produto_nome, produto_imagem, comprador_id, comprador_nome, produtor_id, produtor_nome, status (aberta|aceita|recusada|cancelada), preco_original, preco_proposto, quantidade, unidade, ultima_proposta_por, criado_em, propostas[{autor_id, preco, quantidade, mensagem, data}]`.
Regra: só responde quem **não** fez a última proposta; só cancela quem fez.

### Favoritos

`GET favoritos/listar.php` → lista de produtos · `POST favoritos/adicionar.php` / `POST favoritos/remover.php` com `{ produto_id }`.

### Gestão de fazenda (somente `produtor`)

`GET fazenda/detalhe.php` → `{ fazenda }` (404 com JSON se ainda não houver cadastro) · `POST fazenda/salvar.php`.
Fazenda: `id, nome, cidade, estado, endereco, area_total_ha, area_producao_ha, culturas[], descricao, inscricao_estadual`.

### Notificações

`GET notificacoes/listar.php` → `[{ id, titulo, mensagem, lida, data, tipo: pedido|negociacao|produto|sistema, referencia_id }]` · `POST notificacoes/marcar-lidas.php`.

### Recuperação de senha

`POST auth/recuperar-senha.php` com `{ email }`. Exige envio de e-mail (SMTP) e uma tabela de tokens de redefinição. Responder sempre a mesma mensagem, exista ou não o e-mail.

---

## O que é necessário para concluir a integração

1. **Exportação SQL** do banco `buzzcode_marketplace_rural` (estrutura: tabelas, chaves e relacionamentos).
2. Confirmar onde a API será publicada (sugestão: `https://buzzcodex.com.br/api/`).
3. Criar no phpMyAdmin um usuário MySQL exclusivo da API (sem privilégios de root).
4. Definir se haverá cidade/endereço do usuário (a tabela `usuarios` atual não tem essa coluna).
5. Pasta pública para imagens de produtos e limite de tamanho.
6. Conta SMTP, se a recuperação de senha por e-mail for desejada.
