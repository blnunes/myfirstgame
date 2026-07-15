# Contexto do projeto para agentes

## Visão geral

Este é um protótipo 2D top-down em Godot 4.7. O jogador controla um cão em um mapa lógico de `640 x 480`. O jogo alterna dinamicamente entre quatro cenários: floresta, cidade, deserto e espaço.

Cada cenário fornece um alvo diferente:

- floresta: árvore;
- cidade: hidrante;
- deserto: cacto;
- espaço: meteoro.

Uma partida termina ao alcançar 10 alvos. O HUD mostra progresso e cronômetro; o tempo para imediatamente no décimo alvo. Se o resultado entrar entre os 10 menores tempos, o jogador informa exatamente três iniciais `A-Z`. O ranking é persistido entre execuções em `user://leaderboard.json`. Números, espaços, acentos e caracteres especiais não são aceitos.

Ao tocar em cada alvo, o movimento é pausado brevemente, o efeito de xixi e um som são reproduzidos e um cenário diferente é escolhido aleatoriamente. O alvo também ocupa uma das posições candidatas aleatórias do novo cenário. No espaço, uma camada visual adiciona um capacete somente ao redor da cabeça do cão.

O executável não está no `PATH`, mas está disponível em `/Users/brunonunes/Downloads/Godot.app/Contents/MacOS/Godot`. No sandbox, use `HOME=/private/tmp/godot-home`, `--headless`, `--rendering-method gl_compatibility` e `--audio-driver Dummy`; sem um `HOME` gravável, o Godot pode falhar ao criar `user://logs`. A validação visual continua sendo feita no editor.

## Estrutura de arquivos

```text
myfirstgame/
├── AGENTS.md
├── MainScene.tscn
├── project.godot
├── README.md
├── assets/characters/
│   ├── dog.png
│   └── dog_source.png
└── scripts/
    ├── main_scene.gd
    ├── leaderboard_store.gd
    ├── player.gd
    ├── player_accessories.gd
    └── scenarios/
        ├── base_scenario.gd
        ├── forest_scenario.gd
        ├── city_scenario.gd
        ├── desert_scenario.gd
        └── space_scenario.gd
```

## Configuração e coordenadas

`project.godot` define `MainScene.tscn` como cena principal, viewport lógico de `640 x 480`, janela de `960 x 720` e stretch `canvas_items`. A origem 2D fica no canto superior esquerdo; X cresce para a direita e Y para baixo.

## Hierarquia persistente

```text
MainScene (Node2D, main_scene.gd)
├── Player (CharacterBody2D, player.gd)
│   ├── DogSprite (Sprite2D)
│   ├── CollisionShape2D (RectangleShape2D, 100 x 100)
│   └── Accessories (Node2D, player_accessories.gd)
└── Interface (CanvasLayer)
    ├── MarginContainer/PanelContainer/Content
    │   ├── ScenarioLabel
    │   ├── InstructionLabel
    │   └── StatsLabel
    └── EndGameOverlay
        └── ResultsPanel/ResultsContent
            ├── tempo e estado de classificação
            ├── InitialsRow (LineEdit + botão)
            ├── LeaderboardLabel
            └── RestartButton
```

Em execução, `MainScene` adiciona:

```text
Scenario atual (BaseScenario)
InteractionSound (AudioStreamPlayer)
```

O alvo não possui `Area2D`. A aproximação é calculada diretamente por `BaseScenario` a cada frame de física, evitando que o colisor grande do cão antecipe a interação.

## Responsabilidades dos componentes

### `main_scene.gd`: coordenador

O nó principal conhece o catálogo `SCENARIO_SCRIPTS`, instancia um cenário, conecta o sinal `target_reached`, atualiza a interface e coordena a partida. Ele cronometra a sessão com `Time.get_ticks_msec()`, encerra no décimo alvo, valida a entrada visual das iniciais e sintetiza o som curto de interação. Não desenha elementos de cenário, não conhece como um alvo é construído e delega persistência a `LeaderboardStore`.

O primeiro cenário é sempre floresta. Depois disso, `_pick_different_scenario()` consome uma fila embaralhada com os outros três cenários. Cada tema aparece uma vez por ciclo, em ordem aleatória, e o cenário atual não se repete imediatamente. Dessa forma, cidade, deserto e espaço são garantidos nas três primeiras transições.

### `leaderboard_store.gd`: persistência do ranking

`LeaderboardStore` lê e escreve `user://leaderboard.json` usando `FileAccess` e JSON. Ele valida novamente dados carregados do disco e entradas novas, ordena por menor tempo e limita o ranking a 10 registros. Cada registro possui:

```json
{"initials": "DOG", "time": 12.345}
```

As iniciais precisam ter exatamente três códigos ASCII entre `A` e `Z`. A tela também sanitiza a digitação, mas o store repete a validação para não depender da interface. Empates com o décimo lugar não substituem o resultado existente.

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

### Cenários concretos

- `forest_scenario.gd`: grama, caminho, lago, árvores e árvore-alvo.
- `city_scenario.gd`: edifícios, rua, passeio e hidrante-alvo.
- `desert_scenario.gd`: areia, dunas, pedras e cacto-alvo.
- `space_scenario.gd`: nebulosas, estrelas, planeta, meteoros e meteoro-alvo.

O anel brilhante indica qual objeto é interativo. Elementos decorativos não possuem colisão.

### `player.gd`: movimento

`MainScene.tscn` mantém `(320, 260)` apenas como posição de fallback no editor. No início da partida e em toda troca de cenário, `get_safe_player_spawn()` escolhe aleatoriamente uma posição de `PLAYER_SPAWN_POSITIONS` que esteja a pelo menos `230 px` do alvo atual. O jogador lê `ui_left`, `ui_right`, `ui_up` e `ui_down`, normaliza a diagonal, usa velocidade `260 px/s` e chama `move_and_slide()`. Não há ações WASD explícitas em `project.godot`; as setas são o controle garantido.

O limite é `Rect2(0, 0, 640, 480)` e leva em conta o colisor de `100 x 100`. O centro fica aproximadamente entre X `50..590` e Y `50..430`.

O jogador entra no grupo `player`. Durante a transição, `set_movement_enabled(false)` zera a velocidade e impede novo input.

### `player_accessories.gd`: apresentação contextual

Esse componente desenha acima do sprite (`z_index = 11`) e é independente do movimento. Ele controla:

- capacete ajustado à cabeça quando `requires_space_helmet()` é verdadeiro;
- efeito temporário de xixi direcionado ao alvo.

Novas aparências contextuais devem ficar nesse componente ou em componentes irmãos, sem adicionar regras de cenário a `player.gd`.

## Sprite do cão

`dog.png` mede `1254 x 1254`, tem transparência RGBA e usa escala `(0.1, 0.1)`. Devido ao erro já observado `No loader found for resource`, `player.gd` continua carregando o arquivo com `Image.load_from_file()` e criando uma `ImageTexture` em tempo de execução. Não converta o PNG em `ext_resource Texture2D` sem validar o importador.

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
2. Executar em proporção `4:3` e confirmar início em `FOREST`.
3. Confirmar sprite, HUD, cronômetro, contador `00/10` e árvore destacada.
4. Testar setas, diagonais e quatro limites.
5. Tocar na árvore e conferir efeito, som, mensagem e troca após `0,7 s`.
6. Repetir até visitar CITY, DESERT e SPACE.
7. Confirmar hidrante, cacto e meteoro interativos e em posições variáveis.
8. Confirmar que CITY, DESERT e SPACE aparecem uma vez durante as três primeiras transições, sem repetição imediata.
9. Confirmar capacete apenas em SPACE.
10. Confirmar que o cão nasce em posições variadas e visualmente distante do alvo em cada mapa.
11. Permanecer parado próximo ao limite de ativação; a troca só deve ocorrer ao cruzá-lo em movimento.
12. Confirmar que não há ativação automática ao entrar em um mapa nem duas transições ao permanecer sobre o alvo.
13. Atingir o décimo alvo e confirmar contador `10/10`, movimento bloqueado e tela final.
14. Tentar números, espaços, símbolos e letras acentuadas nas iniciais; todos devem ser removidos.
15. Confirmar que apenas três letras habilitam `SALVAR` e que Enter também salva.
16. Salvar mais de 10 partidas e confirmar ordenação crescente e limite de 10 resultados.
17. Reiniciar o projeto e confirmar que `user://leaderboard.json` preservou o ranking.
18. Confirmar que um tempo fora do Top 10 não solicita iniciais.
19. Usar `JOGAR NOVAMENTE` e confirmar floresta, spawn seguro, `00/10` e cronômetro zerado.
20. Verificar o console para erros de PNG, script, áudio ou persistência.

## Regras de manutenção

- Preserve Godot 4.7 e mudanças pequenas em arquivos não relacionados.
- Atualize este documento se arquitetura ou comportamento mudarem.
- Não presuma que assets externos serão importados; valide antes de referenciá-los na cena.
- Cenários são visuais e atravessáveis. Para bloqueios futuros, adicione corpos físicos sem acoplar a interação por distância a esses colisores.
- Se o mapa mudar, atualize `BaseScenario.MAP_SIZE`, `player.gd::movement_bounds`, viewport, janela e posições candidatas em conjunto.
- Não misture acesso a `FileAccess` com scripts de cenário; regras de ranking pertencem a `LeaderboardStore`.
