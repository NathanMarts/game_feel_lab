# Game Feel Lab — Godot 4

Uma sala de testes para sentir a diferença que os efeitos de *game feel* fazem em um metroidvania 2D. O projeto não usa sprites externos, plug-ins nem assets de terceiros: os dois personagens são desenhados em pixels por código, e os sons são sintetizados.

## Como rodar

1. Extraia o ZIP.
2. Abra o **Godot 4.x**, escolha **Importar** e selecione o arquivo `project.godot` da pasta extraída.
3. Aperte **F6** (na cena `main.tscn`) ou **F5** (executar projeto).
4. Aproxime-se do boneco à direita e ataque, alternando os efeitos.

## Controles

| Tecla | Ação |
|---|---|
| `A`, `D` ou setas | Andar |
| `Espaço` ou `W` | Pular |
| `J`, `K` ou clique esquerdo | Atacar |
| `1` | Ligar/desligar white flash |
| `2` | Ligar/desligar squash & stretch |
| `3` | Ligar/desligar hitstop |
| `4` | Ligar/desligar camera shake |
| `5` | Ligar/desligar partículas |
| `6` | Ligar/desligar efeitos sonoros |
| `R` | Reiniciar posição e contagem |

### Compare com e sem efeitos

- Desligue tudo (teclas `1` até `6`), acerte o boneco e observe como o golpe fica seco.
- Ative `1` (flash), depois `3` (hitstop), depois `4` (câmera). Teste cada opção individualmente antes de combinar.
- Ative `2` e pule: a *colisão não muda*, apenas o desenho do personagem se deforma. Compare ao aterrissar.
- Por fim, ative `5` e `6` e veja a contribuição das partículas e do som.

## Arquivos

- `main.tscn`: sala inicial.
- `main.gd`: controle, efeitos, cenário, personagem, dummy e UI.
- `audio/*.wav`: sons originais simples do laboratório.

## Experimentos sugeridos no `main.gd`

| Constante / valor | Experimente |
|---|---|
| `JUMP_SPEED := -302.0` | -260 (pulo baixo), -340 (alto) |
| `MOVE_SPEED := 145.0` | 110 (pesado), 180 (ágil) |
| `shake_strength := 2.9` | 1.0 (sutil), 6.0 (forte) |
| `Engine.time_scale = 0.1` | 0.05 (quase pausa), 0.35 (menos pausa) |
| `create_timer(0.055, ...)` | 0.025 (sutil), 0.09 (marcado) |
| `apply_squash(Vector2(1.27, 0.73), 0.28)` | 1.1 / 0.9 (sutil) |

**Nota:** a arte foi mantida intencionalmente rudimentar. A meta é verificar que o jogador sente os impactos e movimentos antes de investir em sprites, personagens e mundo.

Este protótipo foi escrito para Godot 4 e não depende de recursos pagos.


## Floresta alienígena — experimento visual

O laboratório agora representa a superfície de um planeta coberto por flora bioluminescente, árvores gigantes e insetos voadores. Ao fundo há um planeta com anéis e uma lua. O cenário é desenhado no `_draw()` de `main.gd`; as camadas estão organizadas para futuramente serem extraídas para um `Parallax2D`.

### Viajante interplanetário

O protagonista usa traje claro, visor luminoso, mochila e antena. As animações são geradas proceduralmente por `draw_traveler_frame()`, sem sprites externos:

| Animação | Frames | Ritmo |
|---|---:|---:|
| Idle | 4 | 4 fps |
| Walk | 6 | 10 fps |

Cada frame é uma imagem transparente **32×40 px** com centro horizontal fixo (`x=16`) e base dos pés em `y=38` (com pequena variação vertical intencional no ciclo). O sistema troca frames sem ajustar a posição do nó ou o collider. O filtro de textura mantém os pixels nítidos.

**Nota de qualidade:** esta é uma implementação procedural de referência, não uma spritesheet artística final. O próximo passo é substituir os frames por pixel art desenhada, mantendo dimensões, pivô e silhueta consistentes.

### Teste sugerido

1. Execute F5.
2. Fique parado e observe o idle.
3. Ande com A/D para alternar para a caminhada.
4. Pule e ataque; os efeitos originais do laboratório continuam disponíveis.
5. Compare o alinhamento visual dos pés enquanto o personagem se move.

A arte de referência conceitual serve como direção de estilo; não foi aplicada como imagem única de fundo, pois isso impediria camadas de parallax e reutilização modular.
