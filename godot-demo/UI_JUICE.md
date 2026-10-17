# UI 動效

可重用元件：scenes/components/ui_juice.tscn，腳本 scripts/ui_juice.gd。
將此子場景放在任意既有 Control 下；不需要替換原節點或素材。

Inspector 的 Mode：Button（懸停／按下）、Entrance（顯示時彈入）、Value（Label 文字變更時彈跳）。
Hover Scale：懸停倍率；Tilt Degrees：旋轉幅度，寬按鈕自動減弱。
Duration：回彈時間；Delay：入場錯開時間；Value Scale：數值彈跳倍率。
動效以各節點已保存的 Scale、Rotation、Modulate、Pivot 為基準；不改位置、錨點、尺寸。
隱藏頁面會取消動畫並恢復基準。停用按鈕不再保持懸停變形。

套用：選關、升級、說明、暫停、結算、升級測試按鈕及頂部 HUD。
營業額、訂單數、升級頁持有金額變更會彈跳；時間文字不每秒彈跳。

參考：https://www.youtube.com/watch?v=aagPe4dvM2M
原片在本次存取要求登入且無可匯出字幕；實作根據同片轉載介紹列出的技巧獨立製作，並非逐幀複製。
轉載介紹：https://www.bilibili.com/video/BV1uZ5Z6SEtK/

驗證：tests/test_ui_juice.gd，隔離測試存檔。
已驗證懸停、按下、停用、快速切頁、數值變動、暫停及恢復；共 63 個原生場景動效實例。
7 個修改場景中所有既有節點的屬性與修改前完全一致。
