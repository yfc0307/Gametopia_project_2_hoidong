營業額已改用 scripts/revenue_number.gd，只作用於 HUD/Money/Amount。
Count Duration：中間數字跑動時間（預設 0.36 秒）。
Pop Scale：放大倍率（1.25）；Pop Angle：傾斜角度（-8 度）；Settle Duration：回穩時間（0.4 秒）。
訂單數及 HUD 入場彈跳已移除，中文標題、卡片、數字欄保持固定。
HUD 使用電車綠／白色分欄，粗黑描邊 Outline Size 8，可在各 Label 的 Theme Overrides 微調。
測試 tests/test_revenue_hud.gd 已驗證 0 至 15 全部中間數字、固定布局、連續收入、暫停及新日重置。

HUD 逐字波浪：在 service_hud.tscn 選根節點 HUD。
Wave Height：逐字上下幅度，預設 2.4。
Wave Speed：速度，預設 9（約每 0.7 秒一個週期）。
Letter Phase：相鄰字的相位差，預設 0.75。
文字是原生 RichTextLabel，使用 hud_wave_effect.gd，不移動外框或重新建立主要布局。
營業額字號已由 26 放大到 32；$ 靠近數字。收入計數／回彈時暫停整組營業額波浪，結束後接續；時間及訂單波浪不中斷。
測試 test_hud_wave.gd 已驗證三組文字的實際渲染變化、逐字相位、收入暫停／恢復及全域暫停。
關卡外動畫：按鈕下 Juice 的 Hover Scale / Tilt Degrees / Duration；標題或卡片下 EntranceJuice 的 Delay / Duration。
