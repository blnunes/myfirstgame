# Pipeline de personagens e sprites

> Guia para produzir e integrar dezenas de personagens sem repetir o trabalho manual da sprint dos cães `MIDNIGHT` e `GOLDEN`.

## Objetivo

O jogo deve conseguir crescer de 2 para 100 personagens com um processo previsível. Cada novo personagem precisa passar pelas mesmas etapas:

1. receber uma imagem de referência;
2. gerar um sheet de caminhada no padrão visual do jogo;
3. converter o sheet para um formato técnico canônico;
4. validar automaticamente dimensões, transparência e ocupação;
5. registrar a skin por dados, sem adicionar condicionais ao jogador.

O gerador de imagem é responsável por criar poses novas. Python deve apenas executar transformações determinísticas, como remover fundo, recortar, alinhar e validar. Não use scripts para redesenhar patas ou reconstruir anatomia: quando uma pose estiver incorreta, o frame deve ser regenerado ou substituído por uma arte corrigida.

## As três imagens do processo

Os arquivos têm papéis diferentes e não devem ser confundidos:

| Etapa | Conteúdo | Pode ser usada diretamente no jogo? |
|---|---|---|
| Referência | Uma ilustração que define identidade, cores e estilo do personagem | não |
| Sheet gerado | Dezesseis poses produzidas a partir da referência | ainda não |
| Sheet de runtime | Sheet validado, com transparência real, tamanho e grade canônicos | sim |

A imagem `d548452d-0530-46d8-b74d-755fe7ce58b4.png`, fornecida para o terceiro personagem, é uma **referência**. Ela possui `1254 x 1254`, não contém canal alpha e o quadriculado faz parte dos pixels RGB. Ela não é um sheet de animação apesar de ter a mesma resolução aproximada dos sheets atuais. No projeto, essa referência foi preservada como `assets/characters/dog/sources/dog_dapple_reference.png` e originou a skin `DAPPLE`.

## Contrato canônico do sheet

Todas as skins novas devem entregar o mesmo contrato:

- PNG RGBA com transparência real;
- `1252 x 1252` pixels;
- grade exata `4 x 4`;
- cada célula com `313 x 313` pixels;
- margem transparente mínima de `12 px` nos quatro lados de cada célula;
- conteúdo visível limitado a no máximo `289 x 289` pixels por célula (`313 - 2 × 12`);
- personagem inteiro dentro de cada célula, sem transbordar para o quadro vizinho;
- escala corporal e linha do chão consistentes nas 16 poses;
- mesma identidade, paleta e acabamento em todos os quadros;
- sem texto, sombra projetada, cenário ou quadriculado.

### Organização das linhas

| Linha | Direção | Uso atual no jogo |
|---:|---|---|
| 0 | frente, movimento para baixo | `walk_down` |
| 1 | perfil direito | `walk_side` |
| 2 | perfil esquerdo | preservada como referência; o runtime atualmente espelha a linha 1 |
| 3 | costas, movimento para cima | `walk_up` |

Manter a linha 2 no arquivo permite mudar o jogo futuramente para usar as duas laterais desenhadas. Enquanto isso, `flip_h` garante que a esquerda tenha a mesma cadência da direita.

### Organização das colunas

| Coluna | Fase da passada |
|---:|---|
| 0 | contato A |
| 1 | passagem A |
| 2 | contato B, com pernas opostas à coluna 0 |
| 3 | passagem B |

Nas laterais, dianteira e traseira devem trabalhar em oposição diagonal. Nas vistas frontal e traseira, a perna longa/adiantada deve alternar visualmente de lado entre as fases A e B. As quatro patas devem manter as mesmas cores do personagem; nunca pinte patas diferentes somente para evidenciar a alternância.

## Nomes e estrutura de diretórios

Use um identificador estável em `snake_case`, sem espaços, acentos ou número de versão. A terceira skin usa o id curto `dapple` e o nome exibido `DAPPLE`.

Estrutura recomendada:

```text
assets/characters/
├── sources/                         # referências originais, não usadas em runtime
│   └── dapple_dachshund.png
├── generated/                       # resultado bruto do gerador; opcional no Git
│   └── dapple_dachshund_sheet_raw.png
├── spritesheets/                    # somente os sheets finais consumidos pelo jogo
│   └── dapple_dachshund.png
└── definitions/                     # uma configuração por personagem
    └── dapple_dachshund.tres
tools/
├── normalize_character_sheet.py     # normalização de células já implementada
├── prepare_character_sheet.py       # remoção de fundo integrada proposta
└── validate_character_sheet.py      # validação isolada proposta
```

Não crie arquivos finais como `personagem_v2.png`, `personagem_v3.png` ou `personagem_final_agora.png`. O sheet ativo mantém um nome estável e o Git preserva o histórico. Imagens intermediárias só devem permanecer se tiverem valor como fonte de trabalho.

## Etapa 1 — preparar a referência

A referência precisa mostrar claramente:

- formato da cabeça, orelhas, focinho e cauda;
- proporções do tronco e das pernas;
- manchas e cores que identificam o personagem;
- estilo de renderização desejado.

Uma vista única é suficiente para definir a identidade, mas não contém informação completa sobre costas e lado oposto. O gerador terá de inferir essas vistas. Se uma mancha assimétrica for importante, forneça vistas adicionais antes de gerar o sheet.

O caminho da referência deve ser informado explicitamente. Não procure automaticamente imagens em `Downloads`, porque isso pode selecionar uma versão errada ou um arquivo não relacionado.

## Etapa 2 — gerar o sheet `4 x 4`

Use a referência somente para identidade e estilo. O pedido ao gerador precisa descrever separadamente o layout técnico e a mecânica da passada.

### Modelo de prompt

```text
Use a imagem anexada como referência obrigatória da identidade deste mesmo cão.
Crie um único sprite sheet de caminhada 4 x 4, sem texto e sem cenário.

Layout das linhas:
1. vista frontal, caminhando em direção à câmera;
2. perfil direito;
3. perfil esquerdo;
4. vista traseira, afastando-se da câmera.

Em cada linha, gere quatro fases contínuas:
1. contato A;
2. passagem A;
3. contato B com as patas opostas;
4. passagem B.

Preserve rigorosamente em todos os 16 frames: o mesmo personagem, proporções,
paleta, manchas, formato das orelhas, focinho e cauda. Mantenha o corpo com a
mesma escala, a linha do chão fixa e no mínimo 12 pixels transparentes nos
quatro lados de cada célula. As patas
dianteiras e traseiras precisam alternar de forma anatomicamente legível, sem
mudar a cor de nenhuma pata. Não corte o personagem e não permita que um frame
invada outro.

Entregue fundo transparente real. Se transparência real não for possível,
use uma cor chapada uniforme que não exista no personagem; não desenhe um
quadriculado de transparência.
```

### Inspeção antes de aceitar a geração

Rejeite o sheet bruto antes de qualquer processamento se houver:

- a mesma pata sempre à frente;
- pata traseira idêntica nos contatos A e B;
- cão flutuando por mudança da linha do chão;
- último quadro deformado ou incompleto;
- identidade, manchas ou cores diferentes entre frames;
- membros com cores artificiais para indicar alternância;
- sobreposição entre células;
- mistura de direções dentro de uma linha.

Transformações 2D conseguem mover pixels, mas não conseguem revelar corretamente uma perna que o desenho nunca representou. Aprovar a anatomia nesta etapa economiza a maior parte do retrabalho.

## Etapa 3 — processamento determinístico

O processamento local deve ser repetível e receber caminhos explícitos de entrada e saída. A preparação completa ainda é uma interface proposta:

```sh
python3 tools/prepare_character_sheet.py \
  --input assets/characters/generated/dapple_dachshund_sheet_raw.png \
  --output assets/characters/spritesheets/dapple_dachshund.png \
  --grid 4x4 \
  --cell-size 313 \
  --background auto
```

> `prepare_character_sheet.py` e `validate_character_sheet.py` ainda são propostas. A normalização de células já está implementada em `tools/normalize_character_sheet.py`.

A ferramenta deverá executar somente operações previsíveis:

1. ler o modo e as dimensões da imagem;
2. preservar alpha verdadeiro quando já existir;
3. remover fundo uniforme ou quadriculado conectado às bordas;
4. impedir que tons claros internos do cão sejam apagados junto com o fundo;
5. recortar a borda de um pixel quando uma fonte `1254 x 1254` realmente contiver um sheet alinhado que precisa se tornar `1252 x 1252`;
6. salvar PNG RGBA sem alterar a anatomia ou a ordem dos frames;
7. chamar o validador e falhar sem substituir o asset ativo se algum requisito não for atendido.

### Normalização de células já implementada

Depois de obter um PNG RGBA `1252 x 1252`, execute:

```sh
python3 tools/normalize_character_sheet.py \
  --input assets/characters/dog/spritesheets/dog_walk_dapple.png \
  --output /private/tmp/dog_walk_dapple_normalized.png \
  --cell-size 313 \
  --safe-margin 12
```

O normalizador:

1. detecta exatamente 16 componentes conectados usando alpha maior que `32/255`;
2. agrupa quatro componentes por linha e os ordena da esquerda para a direita;
3. centraliza cada desenho horizontalmente na própria célula;
4. preserva uma linha de base comum por direção, corrigindo-a somente quando for necessário respeitar a margem;
5. mantém no mínimo `12 px` transparentes nos quatro lados;
6. recusa qualquer desenho maior que `289 x 289`, em vez de reduzi-lo silenciosamente;
7. preserva os pixels e a anatomia de cada pose, alterando somente sua posição no sheet.

Gere em um caminho temporário, valide visualmente e só então substitua o asset ativo. No primeiro sheet da `DAPPLE`, a linha lateral direita chegou a ter `0 px` de margem e pixels opacos nas divisões entre frames; a linha traseira começava `19 px` antes de sua célula. A normalização corrigiu ambos sem redesenhar o personagem.

### Tratamento de fundo

Use esta ordem de preferência:

1. **Alpha real:** preserve os pixels transparentes existentes.
2. **Cor chapada:** remova a cor a partir das bordas com tolerância pequena.
3. **Quadriculado incorporado:** classifique apenas tons claros e quase neutros conectados ao exterior de cada célula e faça flood fill a partir das bordas.

Não transforme globalmente todo pixel branco/cinza em transparência. Olhos, dentes, pelos claros e brilhos também podem usar essas cores. A conexão com a borda é o que diferencia fundo de detalhes internos na maior parte dos casos.

Se a remoção automática apagar partes do personagem, o processo deve parar. É preferível gerar novamente sobre fundo chapado a manter uma máscara destrutiva específica para uma única skin.

### O que Python não deve fazer

- copiar uma pata de um frame e colá-la em outro para simular alternância;
- espelhar somente um membro;
- pintar patas com cores diferentes;
- reconstruir partes ausentes com formas improvisadas;
- deslocar cada frame manualmente sem registrar uma regra reproduzível;
- sobrescrever o sheet ativo antes de a validação terminar.

Essas tentativas criam costuras, membros malformados e inconsistência de perspectiva. O script deve preparar a arte, não redesenhá-la.

## Etapa 4 — validação automática

A segunda ferramenta deverá ser executável isoladamente:

```sh
python3 tools/validate_character_sheet.py \
  assets/characters/spritesheets/dapple_dachshund.png
```

Validações mínimas:

- formato PNG e modo RGBA;
- dimensões exatas de `1252 x 1252`;
- 16 células de `313 x 313`;
- cantos transparentes em cada célula;
- conteúdo não transparente em todas as células;
- conteúdo confinado à própria célula;
- margem transparente mínima de `12 px` nos quatro lados de cada célula;
- largura e altura visíveis máximas de `289 px`;
- área ocupada em uma faixa plausível para detectar quadros vazios ou enormes;
- linha do chão com tolerância pequena dentro de cada direção;
- frames diferentes entre si, evitando uma linha estática duplicada.

Essas verificações encontram erros técnicos, mas não entendem anatomia. A revisão humana ainda deve confirmar:

- alternância dianteira e traseira nas linhas laterais;
- alternância legível nas linhas frontal e traseira;
- continuidade do ciclo `0 → 1 → 2 → 3 → 0`;
- ausência de flutuação;
- identidade e paleta constantes;
- qualidade do primeiro e do último quadro.

Depois da validação da imagem, execute os testes do Godot para confirmar carregamento, animações, capa e troca de skin.

## Etapa 5 — catálogo orientado a dados

O catálogo atual em `scripts/player_skin_catalog.gd` é adequado para duas skins, mas exige editar GDScript para cada personagem. Com 100 skins, a fonte única deve passar a ser um diretório de configurações `Resource`.

Modelo recomendado:

```gdscript
class_name PlayerSkinDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_file("*.png") var texture_path: String
@export var walk_down_row := 0
@export var walk_side_row := 1
@export var walk_up_row := 3
@export var cover_frame := Vector2i(0, 0)
```

Cada personagem terá um `.tres` semelhante a:

```text
[resource]
id = &"dapple_dachshund"
display_name = "DAPPLE"
texture_path = "res://assets/characters/spritesheets/dapple_dachshund.png"
walk_down_row = 0
walk_side_row = 1
walk_up_row = 3
cover_frame = Vector2i(0, 0)
```

`PlayerSkinCatalog` deverá carregar todos os `.tres` de `assets/characters/definitions/` usando `DirAccess`, validar ids duplicados e ordenar por um campo explícito ou pelo nome. Assim, adicionar uma skin vira uma operação de dados; `player.gd`, `main_scene.gd` e o menu não mudam.

Essa migração ainda é uma recomendação. Enquanto ela não for implementada, `PlayerSkinCatalog.create_skins()` continua sendo a fonte oficial e toda skin precisa ser adicionada manualmente ali.

## Fluxo do terceiro personagem

Para transformar a referência atual no terceiro personagem:

1. escolher o `id` e o nome de exibição definitivos;
2. copiar a referência para `assets/characters/sources/<id>.png`;
3. gerar um sheet bruto usando o modelo de prompt;
4. rejeitar imediatamente qualquer passada anatomicamente incorreta;
5. processar para `assets/characters/spritesheets/<id>.png` em RGBA `1252 x 1252`;
6. validar técnica e visualmente as 16 células;
7. registrar a skin no catálogo atual ou, após a refatoração, criar `<id>.tres`;
8. executar os smoke tests do projeto e revisar a animação no Godot 4.7;
9. manter no Git somente a referência útil, o sheet ativo e a definição.

## Definição de pronto para qualquer skin

- [ ] Identidade e nome foram definidos.
- [ ] A referência original está preservada com nome estável.
- [ ] O sheet segue a grade canônica `4 x 4`.
- [ ] As quatro fases apresentam alternância real das patas.
- [ ] O PNG final é RGBA `1252 x 1252`.
- [ ] Não existe quadriculado incorporado nem fundo opaco.
- [ ] Nenhuma célula está cortada, vazia ou invadindo outra.
- [ ] O validador automático passou.
- [ ] A revisão visual das 16 poses passou.
- [ ] A skin está declarada em uma única fonte de dados.
- [ ] Capa, seleção, caminhada e espelhamento foram testados no jogo.
- [ ] Arquivos intermediários e versões obsoletas foram removidos.

## Aprendizados da sprint

- Um quadriculado visível pode estar incorporado ao RGB e não representar transparência.
- `1254` não é divisível por quatro; o runtime precisa de uma dimensão canônica exata.
- Prompts vagos produzem uma coleção de poses, não necessariamente um ciclo de caminhada.
- O gerador precisa receber tanto o layout das direções quanto as quatro fases mecânicas da passada.
- Consistência anatômica deve ser aprovada antes de usar Python.
- Recortes e trocas manuais de patas criam costuras e deformações difíceis de corrigir.
- Nomes estáveis mais histórico do Git são melhores que acumular `v2`, `v3` e cópias finais.
- Geração visual e preparação técnica são etapas diferentes e devem falhar separadamente.
- O catálogo, os testes e o menu devem consumir a mesma definição de skin.
- Um pipeline só escala se o personagem 100 exigir os mesmos passos do personagem 3, sem novas exceções no código.
