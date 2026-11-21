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
