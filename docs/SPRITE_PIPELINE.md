# Viajante — contrato de sprites

O Game Feel Lab agora usa um **PNG verdadeiro**, não um personagem desenhado por `Image.fill_rect()` em GDScript.

Arquivo de produção: [`assets/traveler_sheet.png`](../assets/traveler_sheet.png).

| Item | Valor |
|---|---|
| Imagem | 240 × 96 px |
| Grade | 5 colunas × 2 linhas |
| Célula | 48 × 48 px |
| Linha 0 | 5 poses de idle |
| Linha 1 | 5 poses de corrida |
| Fundo | transparente |
| Pivô do frame | centro horizontal em x=24 |
| Linha de contato dos pés | y≈46, pequena variação de 1 px nas poses de corrida |
| Direção original | direita (esquerda via `flip_h` na Godot) |
| Animação | idle 4 fps, run 10 fps |
| Godot | `AtlasTexture` com regiões retangulares fixas |

A arte foi gerada por IA com o viajante da floresta alienígena como referência, depois convertida em spritesheet por um processo de recorte, remoção de fundo, normalização das poses, redução de paleta e alinhamento.

**Limite importante:** dimensões/pivô bem definidos não garantem movimento artisticamente perfeito; variações de anatomia, iluminação e peças do traje ainda exigem inspeção manual. Os quadros aqui são uma primeira experiência, não uma animação final aprovada.

## Como testar

1. Execute o projeto normalmente (F5).
2. Pare para ver o idle.
3. Ande com A/D ou setas para ver a corrida; pare para voltar ao idle.
4. Observe que o corpo de colisão e os efeitos de squash/stretch continuam independentes da textura.

## Verificações automatizadas

```bash
python -m pip install Pillow
python tools/validate_sprites.py
```

Se trocar o PNG, mantenha as células, a transparência e a linha de contato. Caso mude o tamanho do frame, atualize `TRAVELER_FRAME`, `TRAVELER_FRAMES_PER_ROW`, escala e offset em `main.gd`.
