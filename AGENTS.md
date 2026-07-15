# Contexto do projeto para agentes

> Estado documentado em 15 de julho de 2026. Antes de trabalhar, confirme mudanças posteriores com `git status -sb` e compare este documento com os scripts.

## Visão geral

Este é um protótipo 2D top-down em Godot 4.7. O jogador controla um cão em um mapa lógico de `640 x 480`. O jogo alterna dinamicamente entre quatro cenários: floresta, cidade, deserto e espaço.

Cada cenário fornece um alvo diferente:

- floresta: árvore;
- cidade: hidrante;
- deserto: cacto;
- espaço: meteoro.

Uma partida termina ao alcançar 10 alvos. O HUD mostra progresso e cronômetro; o tempo para imediatamente no décimo alvo. Se o resultado entrar entre os 10 menores tempos, o jogador informa exatamente três iniciais `A-Z`. O ranking é persistido entre execuções em `user://leaderboard.json`. Números, espaços, acentos e caracteres especiais não são aceitos.

O projeto abre na tela de título **Where can Bruce pee?**, com uma imagem frontal do Bruce retirada do sheet ativo. O mapa, jogador e cronômetro só começam depois de `PLAY`. Após salvar um resultado no Top 10, a confirmação permanece por `0,9 s` e o fluxo retorna automaticamente à tela inicial. Um resultado que não classifica oferece `VOLTAR AO INICIO`.

Ao tocar em cada alvo, o movimento é pausado brevemente, o efeito de xixi e um som são reproduzidos e um cenário diferente é escolhido aleatoriamente. O alvo também ocupa uma das posições candidatas aleatórias do novo cenário. No espaço, uma camada visual adiciona um capacete somente ao redor da cabeça do cão.

O executável não está no `PATH`, mas está disponível em `/Users/brunonunes/Downloads/Godot.app/Contents/MacOS/Godot`. No sandbox, use `HOME=/private/tmp/godot-home`, `--headless`, `--rendering-method gl_compatibility` e `--audio-driver Dummy`; sem um `HOME` gravável, o Godot pode falhar ao criar `user://logs`. A validação visual continua sendo feita no editor.

## Estrutura de arquivos

```text
myfirstgame/
├── .gitignore
├── AGENTS.md
├── MainScene.tscn
├── project.godot
├── README.md
├── assets/characters/
│   ├── dog.png
│   ├── dog_source.png
│   └── dog/spritesheets/
│       ├── dog_walk_v1.png
│       └── dog_walk_v2.png            # sheet ativo, cão preto em pixel art
└── scripts/
    ├── main_scene.gd
    ├── leaderboard_store.gd
    ├── player.gd
    ├── player_accessories.gd
    ├── player_visual_controller.gd
    ├── player_shadow.gd
    └── scenarios/
        ├── base_scenario.gd
        ├── forest_scenario.gd
        ├── city_scenario.gd
        ├── desert_scenario.gd
        └── space_scenario.gd
```

Arquivos `.gd.uid` e metadados `.png.import` também são versionados. `.gitignore` exclui `.godot/`, `.vscode/` e `.DS_Store`; não force esses caches ou configurações locais para o Git.

## Configuração e coordenadas

`project.godot` define `MainScene.tscn` como cena principal, viewport lógico de `640 x 480`, janela de `960 x 720` e stretch `canvas_items`. A origem 2D fica no canto superior esquerdo; X cresce para a direita e Y para baixo.

## Git e publicação

- Repositório público: `https://github.com/blnunes/myfirstgame`.
- Remote `origin`: `https://github.com/blnunes/myfirstgame.git`.
- Branch padrão e branch de trabalho atual: `master`.
- O GitHub CLI está instalado e autenticado como `blnunes`; nunca registre tokens ou conteúdo do credential store.
- O primeiro push precisou de `http.postBuffer = 524288000` no config local devido a erro HTTP 400 no envio dos PNGs. Isso não altera arquivos versionados.
- Antes de commit/push, execute `git status -sb`, valide o Godot e preserve mudanças do usuário não relacionadas.

## Hierarquia persistente

```text
MainScene (Node2D, main_scene.gd)
├── Player (CharacterBody2D, player.gd)
│   ├── CollisionShape2D (RectangleShape2D, 100 x 100)
│   ├── Shadow (Node2D, player_shadow.gd, z_index 9)
│   └── VisualRoot (Node2D, player_visual_controller.gd, z_index 10)
│       ├── DogSprite (AnimatedSprite2D)
│       └── Accessories (Node2D, player_accessories.gd, z_index 1)
└── Interface (CanvasLayer)
    ├── MarginContainer/PanelContainer/Content
    │   ├── ScenarioLabel
    │   ├── InstructionLabel
    │   └── StatsLabel
    ├── EndGameOverlay
        └── ResultsPanel/ResultsContent
            ├── tempo e estado de classificação
            ├── InitialsRow (LineEdit + botão)
            ├── LeaderboardLabel
            └── RestartButton
    └── StartOverlay
        └── StartPanel/StartMargin/StartContent
            ├── TitleLabel
            ├── BruceFrame/BruceImage
            ├── PlayButton
            └── textos auxiliares
```

Em execução, `MainScene` adiciona:

```text
Scenario atual (BaseScenario)
InteractionSound (AudioStreamPlayer)
```

O alvo não possui `Area2D`. A aproximação é calculada diretamente por `BaseScenario` a cada frame de física, evitando que o colisor grande do cão antecipe a interação.

## Responsabilidades dos componentes

### `main_scene.gd`: coordenador

O nó principal conhece o catálogo `SCENARIO_SCRIPTS`, instancia um cenário, conecta o sinal `target_reached`, atualiza a interface e coordena a partida. Ele controla também a máquina de estados simples entre tela inicial, partida e resultado. Cronometra a sessão com `Time.get_ticks_msec()`, encerra no décimo alvo, valida a entrada visual das iniciais e sintetiza o som curto de interação. Não desenha elementos de cenário, não conhece como um alvo é construído e delega persistência a `LeaderboardStore`.

O primeiro cenário é sempre floresta. Depois disso, `_pick_different_scenario()` consome uma fila embaralhada com os outros três cenários. Cada tema aparece uma vez por ciclo, em ordem aleatória, e o cenário atual não se repete imediatamente. Dessa forma, cidade, deserto e espaço são garantidos nas três primeiras transições.

O cronômetro começa depois que a floresta inicial é carregada. As pausas de `0,7 s` das nove primeiras transições contam no tempo total porque `game_running` continua verdadeiro. No décimo alvo, `final_time_seconds` é capturado imediatamente; a animação final de `0,7 s` não aumenta o resultado.

### Ordem de processamento — invariante importante

`Player` é um filho persistente criado antes dos cenários dinâmicos. `_load_scenario()` posiciona o jogador e só depois chama `add_child(current_scenario)`. O cenário fica no final da ordem de filhos, então seu `_physics_process()` observa a posição já atualizada pelo movimento do jogador naquele frame. O fundo continua atrás do cão por usar `z_index = -10`; não use `move_child(current_scenario, 0)` apenas para ordenar o desenho.

Essa ordem, junto com `target_consumed`, evita ativações atrasadas do cenário antigo, cuja remoção por `queue_free()` só termina no fim do frame. Ao refatorar `_load_scenario()`, preserve:

1. configurar o alvo;
2. conectar `target_reached`;
3. escolher e aplicar o spawn seguro;
4. adicionar o cenário como filho;
5. atualizar capacete e HUD.

### `leaderboard_store.gd`: persistência do ranking

`LeaderboardStore` lê e escreve `user://leaderboard.json` usando `FileAccess` e JSON. Ele valida novamente dados carregados do disco e entradas novas, ordena por menor tempo e limita o ranking a 10 registros. Cada registro possui:

```json
{"initials": "DOG", "time": 12.345}
```

As iniciais precisam ter exatamente três códigos ASCII entre `A` e `Z`. A tela também sanitiza a digitação, mas o store repete a validação para não depender da interface. Empates com o décimo lugar não substituem o resultado existente.

O arquivo salvo não pertence ao repositório. `user://` depende do diretório de dados do Godot e do `HOME`; testes headless com `HOME=/private/tmp/godot-home` usam um ranking separado do perfil normal. Não adicione rankings de teste ao projeto nem altere a regra de classificação apenas para facilitar testes.

### `base_scenario.gd`: contrato comum

`BaseScenario` centraliza:

- tamanho do mapa e cor de fundo;
- escolha aleatória de uma posição candidata;
- escolha aleatória de um spawn seguro para o jogador;
- distância mínima de `230 px` entre spawn e alvo;
- detecção centro-a-centro de `52 px`, alinhada ao centro visual do anel de cada alvo;
- comparação da posição atual com a posição do frame anterior e cruzamento de fora para dentro;
- consumo único do alvo para impedir ativações residuais;
- localização do grupo `player`;
- sinal `target_reached`;
- helpers vetoriais compartilhados.

Cada implementação sobrescreve apenas os métodos necessários: título, textos, cor, posições candidatas, desenho e, no espaço, uso do capacete. Esse desenho segue responsabilidade única, aberto/fechado e substituição: o coordenador trabalha com `BaseScenario`, sem condicionais por tipo de ambiente.

As 10 posições candidatas de spawn respeitam o colisor do jogador e ficam dentro dos limites efetivos. Para as 16 posições de alvo atuais, cada alvo possui de 6 a 8 spawns válidos a pelo menos `230 px`; o `assert` em `get_safe_player_spawn()` protege essa garantia durante desenvolvimento.

### Cenários concretos

- `forest_scenario.gd`: grama, caminho, lago, árvores e árvore-alvo.
- `city_scenario.gd`: edifícios, rua, passeio e hidrante-alvo.
- `desert_scenario.gd`: areia, dunas, pedras e cacto-alvo.
- `space_scenario.gd`: nebulosas, estrelas, planeta, meteoros e meteoro-alvo.

O anel brilhante indica qual objeto é interativo. Elementos decorativos não possuem colisão.

`target_position` nem sempre é o centro visual do objeto. A detecção e o efeito usam `get_target_interaction_position()`:

| Cenário | Alvo | Offset do centro interativo | Capacete |
|---|---|---:|---|
| Forest | árvore | `(0, -17)` | não |
| City | hidrante | `(0, -8)` | não |
| Desert | cacto | `(0, -18)` | não |
| Space | meteoro | `(0, 0)` | sim |

Ao redesenhar um alvo, mantenha o anel, o offset interativo e a posição usada pelo efeito de xixi alinhados.

### `player.gd`: movimento

`MainScene.tscn` mantém `(320, 260)` apenas como posição de fallback no editor. No início da partida e em toda troca de cenário, `get_safe_player_spawn()` escolhe aleatoriamente uma posição de `PLAYER_SPAWN_POSITIONS` que esteja a pelo menos `230 px` do alvo atual. O jogador lê `ui_left`, `ui_right`, `ui_up` e `ui_down`, normaliza a diagonal e usa velocidade máxima `260 px/s`. `velocity.move_toward()` aplica aceleração de `1450 px/s²` e desaceleração de `1850 px/s²` antes de `move_and_slide()`, evitando partidas e paradas instantâneas. Não há ações WASD explícitas em `project.godot`; as setas são o controle garantido.

O limite é `Rect2(0, 0, 640, 480)` e leva em conta o colisor de `100 x 100`. O centro fica aproximadamente entre X `50..590` e Y `50..430`.

O jogador entra no grupo `player`. Durante a transição, `set_movement_enabled(false)` zera a velocidade e impede novo input.

Depois de mover e aplicar limites, `player.gd` envia `velocity` e `speed` a `VisualRoot::set_motion()`. A lógica física não conhece detalhes de bob, sombra ou sprite sheet; preserve essa separação ao evoluir o personagem.

### `player_visual_controller.gd`: animação direcional e acabamento procedural

`VisualRoot` seleciona a animação pela direção dominante de `velocity`:

- `walk_down`: vista frontal/para baixo;
- `walk_side`: vista lateral direita; `flip_h` produz a esquerda;
- `walk_up`: vista traseira/para cima;
- abaixo de `3%` da velocidade máxima, pausa no frame `0` da direção atual.

Sobre os frames reais, aplica acabamento sutil:

- respiração e bob vertical em idle;
- cadência e altura de bob proporcionais à velocidade;
- inclinação horizontal máxima de `0,035 rad`;
- squash/stretch máximo de `2%` nos passos;
- `flip_h` quando o movimento horizontal muda de direção;
- espelhamento conjunto de `Accessories` para manter capacete e efeito alinhados;
- escala, deslocamento e opacidade suaves da sombra.

As interpolações usam `1 - exp(-response * delta)`, portanto são aproximadamente independentes da taxa de frames. `VisualRoot` movimenta cão e acessórios juntos; `Shadow` é irmão, não filho, para não acompanhar o bob vertical. `DogSprite` já é `AnimatedSprite2D`; futuras substituições de sheet devem manter a API `set_motion()`, os nomes das animações e a estrutura do `VisualRoot`.

### `player_shadow.gd`: sombra procedural

Desenha uma elipse sem asset externo. `player_visual_controller.gd` altera seu transform e `modulate.a`, mas a sombra permanece centrada no chão. Ela usa `z_index = 9`, abaixo do `VisualRoot` em `10` e acima dos cenários em `-10`.

### `player_accessories.gd`: apresentação contextual

Esse componente é filho de `VisualRoot` com `z_index = 1`, portanto aparece acima do `DogSprite` e acompanha a animação corporal. Ele controla:

- capacete ajustado à cabeça quando `requires_space_helmet()` é verdadeiro;
- efeito temporário de xixi direcionado ao alvo.

Novas aparências contextuais devem ficar nesse componente ou em componentes irmãos, sem adicionar regras de cenário a `player.gd`.

## Sprite do cão

O personagem principal usa `dog_walk_v2.png`, gerado a partir da referência de um cão pequeno preto e cinza, com pelo volumoso, orelhas pontudas, olhos grandes, peito claro e cauda enrolada. O estilo é pixel art RPG 2.5D. O sheet tem transparência RGBA e mede `1252 x 1252`, formando uma grade exata `4 x 4` de células `313 x 313`. `player.gd::_load_dog_animations()` carrega a imagem como `Texture2D`, cria `AtlasTexture` para cada frame e monta `SpriteFrames` em runtime.

`dog_walk_v1.png` é a versão anterior, com o cão marrom, e permanece versionado para permitir reversão sem regenerar o asset.

Mapeamento de linhas, com índice iniciado em zero:

- linha `0`: quatro passos frontais, animação `walk_down`;
- linha `1`: quatro passos laterais olhando para a esquerda, atualmente não utilizada diretamente;
- linha `2`: quatro passos laterais olhando para a direita, animação `walk_side`; `flip_h` produz a esquerda;
- linha `3`: quatro passos traseiros, animação `walk_up`.

As animações usam `8 FPS`, ajustados em runtime entre `72%` e `118%` conforme a velocidade. As vistas frontal e traseira usam escala `0,4`; a lateral usa `0,47` para compensar a diferença de ocupação dentro da célula.

`dog.png` continua como fallback estático. Ele mede `1254 x 1254`, tem transparência RGBA e usa escala `(0.1, 0.1)` somente se o sheet falhar. Esse fallback ainda usa `Image.load_from_file()` por causa do erro histórico `No loader found for resource`. O novo sheet foi importado e validado como `Texture2D`, portanto não replique o workaround antigo para ele.

## Fluxo de execução

1. Os filhos da cena ficam prontos; o jogador carrega o PNG e entra no grupo `player`.
2. `MainScene` cria o áudio, carrega o ranking e inicia cronômetro, contador e floresta.
3. `BaseScenario.configure()` escolhe uma posição candidata para o alvo.
4. `MainScene` pede um spawn aleatório a pelo menos `230 px` do alvo e posiciona o cão antes de adicionar o cenário.
5. O cenário desenha o fundo e encontra o jogador pelo grupo `player`.
6. O jogador move e permanece dentro dos limites.
7. Depois do movimento do jogador, o cenário compara a posição atual com o frame anterior e mede a distância até o centro visual do alvo. Ao cruzar `52 px` com deslocamento real, consome o alvo e emite `target_reached` uma única vez.
8. `MainScene` incrementa o contador, pausa o jogador, reproduz efeito/som e mostra a mensagem de sucesso.
9. Nos nove primeiros alvos, após `0,7 s`, o cenário é substituído, um novo spawn seguro é escolhido e a interface e o capacete são atualizados.
10. No décimo alvo, o tempo final é capturado imediatamente e a tela de resultados abre após o efeito.
11. Se o tempo estiver no Top 10, três iniciais válidas podem ser salvas; depois, `JOGAR NOVAMENTE` inicia uma sessão limpa.

## Como adicionar um cenário

1. Crie `scripts/scenarios/nome_scenario.gd` com `extends BaseScenario`.
2. Implemente `get_title()`, `get_instruction()`, `get_success_message()`, `get_background_color()`, `get_target_positions()` e `draw_environment()`.
3. Se `target_position` representar a base do desenho, sobrescreva `get_target_interaction_position()` para devolver o centro visual indicado pelo anel.
4. Se precisar de equipamento espacial, sobrescreva `requires_space_helmet()`; para outro acessório, adicione uma API genérica ao componente de acessórios em vez de testar o tipo do cenário no jogador.
5. Adicione um único `preload` a `SCENARIO_SCRIPTS` em `main_scene.gd`.
6. Garanta ao menos uma posição candidata. O contrato base escolherá um spawn seguro; se novos alvos tornarem impossível respeitar `230 px`, amplie `PLAYER_SPAWN_POSITIONS`.

Não crie `Area2D` de interação nem duplique cálculo de distância, filtro do jogador ou lógica de transição no cenário concreto.

## Checklist de validação manual

1. Abrir `MainScene.tscn` no Godot 4.7 sem erros de parse.
2. Executar em proporção `4:3` e confirmar a capa **Where can Bruce pee?**, a imagem frontal do Bruce e o botão `PLAY`.
3. Antes de `PLAY`, confirmar jogador, HUD e cronômetro inativos; clicar em `PLAY` e confirmar início em `FOREST`.
4. Confirmar sprite, HUD, cronômetro, contador `00/10` e árvore destacada; testar setas, diagonais e quatro limites.
5. Tocar na árvore e conferir efeito, som, mensagem e troca após `0,7 s`.
6. Repetir até visitar CITY, DESERT e SPACE.
7. Confirmar hidrante, cacto e meteoro interativos e em posições variáveis.
8. Confirmar que CITY, DESERT e SPACE aparecem uma vez durante as três primeiras transições, sem repetição imediata.
9. Confirmar capacete apenas em SPACE.
10. Confirmar movimento real das patas nas quatro direções, vista frontal ao descer, traseira ao subir e espelhamento ao andar à esquerda.
11. Confirmar que idle pausa o sheet sem remover respiração, sombra ou direção atual.
12. Confirmar que o cão nasce em posições variadas e visualmente distante do alvo em cada mapa.
13. Permanecer parado próximo ao limite de ativação; a troca só deve ocorrer ao cruzá-lo em movimento.
14. Confirmar que não há ativação automática ao entrar em um mapa nem duas transições ao permanecer sobre o alvo.
15. Atingir o décimo alvo e confirmar contador `10/10`, movimento bloqueado e tela final.
16. Tentar números, espaços, símbolos e letras acentuadas nas iniciais; todos devem ser removidos.
17. Confirmar que apenas três letras habilitam `SALVAR`, que Enter também salva e que, após a confirmação, a capa retorna automaticamente.
18. Salvar mais de 10 partidas e confirmar ordenação crescente e limite de 10 resultados.
19. Reiniciar o projeto e confirmar que `user://leaderboard.json` preservou o ranking.
20. Confirmar que um tempo fora do Top 10 não solicita iniciais.
21. Para um tempo fora do Top 10, usar `VOLTAR AO INICIO`; então clicar em `PLAY` e confirmar floresta, spawn seguro, `00/10` e cronômetro zerado.
22. Verificar o console para erros de PNG, script, áudio ou persistência.

## Validação automatizável no ambiente atual

O Godot não está no `PATH`. Prepare um `HOME` gravável e use o caminho absoluto:

```sh
mkdir -p /private/tmp/godot-home
HOME=/private/tmp/godot-home /Users/brunonunes/Downloads/Godot.app/Contents/MacOS/Godot --headless --rendering-method gl_compatibility --audio-driver Dummy --path /Users/brunonunes/myfirstgame --editor --quit
HOME=/private/tmp/godot-home /Users/brunonunes/Downloads/Godot.app/Contents/MacOS/Godot --headless --rendering-method gl_compatibility --audio-driver Dummy --path /Users/brunonunes/myfirstgame --quit-after 3
HOME=/private/tmp/godot-home /Users/brunonunes/Downloads/Godot.app/Contents/MacOS/Godot --headless --rendering-method gl_compatibility --audio-driver Dummy --path /Users/brunonunes/myfirstgame --script res://tests/dog_animation_smoke_test.gd
HOME=/private/tmp/godot-home-startscreen /Users/brunonunes/Downloads/Godot.app/Contents/MacOS/Godot --headless --rendering-method gl_compatibility --audio-driver Dummy --path /Users/brunonunes/myfirstgame --script res://tests/start_screen_smoke_test.gd
```

O segundo comando, o smoke test direcional e o teste do fluxo da capa já executaram com exit code `0`. É esperado no macOS isolado:

- aviso de certificados do sistema (`get_system_ca_certificates`).

Não considere esse aviso como erro de parse. Um aviso de `Image.load_from_file()` no caminho normal indica que o sheet falhou e o fallback estático foi usado; investigue o importador. Qualquer backtrace GDScript, erro de nó inexistente, falha em `assert` ou exit code diferente de `0` também precisa ser investigado. Sem `HOME` temporário, o Godot pode falhar ao criar `user://logs` ou tentar gravar settings fora do sandbox.

O headless de três frames valida carregamento e `_ready()`, mas agora permanece corretamente na tela inicial. `start_screen_smoke_test.gd` cobre bloqueio inicial, `PLAY`, salvamento e retorno à capa. Ele não cobre visualmente o layout, troca de cenário nem as dez aproximações reais; mantenha o checklist manual.

## Problemas conhecidos e dívida técnica

- O fallback manual de `dog.png` não é seguro para export; o fluxo principal com `dog_walk_v2.png` usa o importador normal e deve ser incluído em testes de export.
- O sheet tem quatro frames por direção, não possui diagonais dedicadas e usa espelhamento na lateral esquerda. O código escolhe a direção dominante para movimentos diagonais.
- `tests/dog_animation_smoke_test.gd` cobre seleção direcional, avanço de frame e flip; `tests/start_screen_smoke_test.gd` cobre abertura, `PLAY`, um salvamento controlado e retorno à capa. Ainda não existem testes automatizados completos para seleção de cenários, distância/spawn ou todos os casos de `LeaderboardStore`.
- O áudio e todos os cenários são desenhados ou sintetizados por código; crescer o mapa pode justificar cenas reutilizáveis, Resources de configuração ou TileMap.
- A interface mistura textos em inglês dos cenários com textos em português no HUD e na tela final.
- Não existe opção na UI para limpar o Top 10.
- Objetos decorativos e o lago continuam atravessáveis e não afetam movimento.
- O tempo inclui deliberadamente as pausas intermediárias de transição; mudar isso altera a comparabilidade de rankings já salvos.

## Regras de manutenção

- Preserve Godot 4.7 e mudanças pequenas em arquivos não relacionados.
- Atualize este documento se arquitetura ou comportamento mudarem.
- Não presuma que assets externos serão importados; valide antes de referenciá-los na cena.
- Cenários são visuais e atravessáveis. Para bloqueios futuros, adicione corpos físicos sem acoplar a interação por distância a esses colisores.
- Se o mapa mudar, atualize `BaseScenario.MAP_SIZE`, `player.gd::movement_bounds`, viewport, janela e posições candidatas em conjunto.
- Não misture acesso a `FileAccess` com scripts de cenário; regras de ranking pertencem a `LeaderboardStore`.
- Não substitua a detecção centro-a-centro por `Area2D` usando o colisor atual de `100 x 100`; isso foi a causa de ativações visualmente prematuras.
- Não reposicione o jogador depois de adicionar o cenário. `_ready()` precisa observar o spawn seguro como posição inicial para configurar `player_was_inside_target` corretamente.
- Ao alterar `TARGET_ACTIVATION_DISTANCE`, offsets ou posições candidatas, reteste todas as combinações de alvo/spawn e as aproximações diagonais.
- Ao alterar `player.gd::speed`, revise aceleração/desaceleração e os parâmetros exportados de `PlayerVisualController`; `set_motion()` sincroniza a velocidade máxima em runtime.
- Não aplique bob diretamente ao nó `Player`, pois isso moveria o corpo físico e afetaria a detecção de distância. Animações cosméticas pertencem a `VisualRoot`.
- Não volte a iniciar a partida diretamente em `_ready()`: `_show_start_screen()` deve manter jogador e HUD inativos até o sinal de `PlayButton`.
- Ao substituir o sheet ativo `dog_walk_v2.png`, preserve grade `4 x 4`, dimensões divisíveis por quatro, transparência, padding e mapeamento de linhas; caso contrário, atualize `WALK_ANIMATION_ROWS` e as validações em `player.gd`.
