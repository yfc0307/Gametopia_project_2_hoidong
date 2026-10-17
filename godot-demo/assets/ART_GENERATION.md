# Watercolor placeholder assets

使用內建 image_gen，沒有使用 API CLI。圖為本輪占位素材，不代表美術組最終畫風。

## shop.png — generation prompt

Use case: stylized-concept. Asset: background for a playable 2D Hong Kong herbal tea shop game, landscape 16:9. Watercolor hand-painted warm ivory paper, jade green tiles, honey wooden counter, muted terracotta accents, delicate ink contours. Front facing slightly top down fixed composition. Upper third has open serving window with Hong Kong street and empty space for customer sprites. Counter across lower two thirds, left station empty for egg supplies and two pots, central wide station empty for five tall silver tea kettles, right station natural shelves with unused space for future equipment. Old phone space on far left wall. Bottom counter cupboards and trash space. NO food, NO kettles or pots, NO people, NO text, NO UI, NO buttons. Calm readable large empty work surfaces; beautiful minimal production game background.

Final background edit: Edit this watercolor game background ONLY by removing the red wall telephone and its cable at far left, and removing the metal trash bin at lower right. Fill those areas naturally with matching jade wall tiles and wood cupboard or floor. Preserve exactly the camera, composition, counter, shelves, street view, colors, texture, all remaining details. This is a game background and all interactive props will be separate sprites; no phones, no trash bins, no people, no UI, no added text.

## props-empty-pot.png — generation and edit prompt

Use case: stylized-concept. A single game sprite atlas on genuinely transparent background, exact 4 columns by 2 rows equal cells, each isolated object centered with generous clear padding. Watercolor hand-painted delicate ink outlines, warm Hong Kong tea shop charming illustration style. Top row: tall silver herbal tea kettle, empty white ceramic tea bowl, white ceramic bowl filled with amber tea, six raw eggs clustered. Bottom row: round silver cooking pot with lid, open round silver warming pot containing brown tea eggs, vintage dark jade rotary telephone, small open metal trash bin. No letters, no labels, no shadows outside each cell, no borders, orthographic slightly top-down matching front facing shop counter. Exactly eight objects, one per equal cell. Output wide 2:1 aspect ratio.

Final atlas edit: Edit this game sprite atlas. Keep the exact watercolor style and the same eight object identities in the same 4 column 2 row arrangement, transparent background. The open warming pot in bottom row column 2 must be EMPTY, no eggs or food inside, show dark empty metal interior. Each object MUST sit fully inside its own equal-size grid cell with at least 12 percent clear padding on all four sides, never touch a cell boundary or neighboring object. Keep kettle, empty bowl, tea bowl, six raw eggs, closed cooking pot, empty open warming pot, green telephone, trash can. Do not draw grid lines, text, UI, background.

Atlas region is explicitly defined in `scripts/main.gd` sprite(). Eggs, text, counters and highlights are drawn as dynamic state. Earlier props.png is retained only as a generation draft and not referenced by gameplay.
