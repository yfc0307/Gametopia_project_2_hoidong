# 開檔 · 涼茶舖 playable slice

Godot 4.7.2，Compatibility renderer。開啟 `project.godot`，按 F5 執行 `main.tscn`。

本輪完成：選關、五茶、茶葉蛋、三個顧客位、逐件交付、付款、補貨、垃圾桶、暫停、收工、結算、返回、金錢／天數自動保存。升級入口為明示未開放的占位頁；新商品、逐步教學及 Jack 錄音模組未納入本輪；DDA 與隨機入場已接入，見 DDA.md。

## 操作

- 拖陶瓷碗至裝填位，再拖水壺到碗上；倒滿後拖給顧客。
- 拖六個生蛋至煮爐；8 秒後點煮爐補滿保溫爐，再逐個拖蛋交付。
- 左牆電話免費補生蛋，1.5 秒；供應滿或補貨中不重複觸發。
- 食物與空碗可拖入下方垃圾桶。無效落點回彈，滿碗不能覆蓋茶款。
- ESC 暫停；失焦自動暫停，返回後按繼續。

## 測試配置與規則

所有經濟與時間配置在 `config/balance.json`。首輪暫用營業 180 秒、3 個顧客位、60 秒基準耐心、空位 1.2 秒補客；茶 $12、蛋 $6、錯茶 50% 收入。這些屬原型測試值，不代表設計定案。茶 1.2 秒、蛋 8 秒、轉移 0.4 秒、補貨 1.5 秒依 GDD。

同幀邊界暫採倒數歸零優先；訂單交齊或耐心耗盡才付款；收工未完成的訂單收入為零。金錢只有一個值；本次收入是結算統計。下次進場不保留食物。程序沒有延用舊的 150 秒／每 5 秒一客／20 秒耐心設定。

存檔：`user://hoidong_progress_v1.json`，保存金錢與下一營業日，臨時檔寫完後替換。首輪只有一份自動存檔，未實作三檔槽。測試資料另寫入 `tests/test_progress.json`，不污染玩家進度。

## 程式與美術替換

- `scripts/service.gd`：玩法狀態，無畫面依賴。
- `scripts/main.gd`：介面、拖拽、顯示及穩定音效事件 ID。
- `main.tscn` 現在是入口：僅組合六個頁面場景及共用音訊／錯誤提示，沒有頁面內部布局。完整遊戲仍按 F5 從這裡啟動。
- 請直接打開 `scenes/pages/tea_shop.tscn` 編輯關卡。拖動 `EggSupply`、`CookingPot`、`WarmingPot`、`BowlSupply`、`FillingSlot`、`Phone`、`Trash`；水壺在 `Kettles`，顧客在 `Customers`。請移動設備實例父節點，子圖片、標籤與熱區一起跟隨。
- 替換素材：選設備下的 `Art` TextureRect，在 Inspector 更換 Texture；已有 AtlasTexture 可展開調整 Region，也可直接拖入獨立 PNG。程序不重設 Texture 或設備位置。
- 每頁均為獨立 .tscn：`level_select` 選關、`tea_shop` 關卡、`settlement` 結算、`upgrades` 升級、`instructions` 操作說明、`pause_menu` 暫停。每頁打開即能看到自己的原生節點，無須切換 main 裡其他頁面的眼睛。頁面單獨執行只作靜態預覽；完整交互從 main 啟動。
- `scenes/components/kettle.tscn` 與 `customer_order.tscn` 分別供五個水壺／三個顧客位共用。七種設備也各有子場景。修改元件內部圖像或樣式時雙擊其場景圖示／打開 components 檔案；只改擺位時在 tea_shop 頁面拖動實例。茶款文字與個別調整保留為實例 override。
- 共用 UI 主題在 `ui/theme.tres`，每個頁面與元件均引用同一份，獨立編輯時也有一致字體與樣式。
- 互動範圍由設備 Control 的矩形轉換到主場景座標取得。可改位置及 Scale；設備標籤、圖片是子節點，主要圖片及熱區高亮使用 anchors 跟隨大小。程序僅更新狀態、數字、可見性與短暫效果。
- `tools/build_native_scenes.py`、`migrate_controller.py` 及 `split_scenes.py` 僅為一次性遷移工具；不要重跑覆蓋已手動編輯的布局。
- 基準 1920×1080，邏輯布局 1280×720 乘 1.5；固定構圖、等比縮放，非 16:9 保留黑邊。
- 顧客用原生 Panel 與 Label 組成占位表情；聲音為短合成提示，並非 Jack 的正式音效／契媽配音。契媽目前只有非阻塞字幕，預留 phone_restock 等事件。

## 驗證

`tests/test_service.gd`：23 項狀態規則檢查。

`tests/test_ui.gd`：場景內控制器整合，從選關按鈕開始，經茶、蛋、補貨、付款、垃圾桶、暫停、收工、結算返回及存檔讀回；另驗證移動設備後圖片與熱區跟隨、程序不覆寫位置。此為控制器整合測試，不等同真人滑鼠手感測試。

執行：`Godot --headless --path PROJECT --script res://tests/test_service.gd`；介面整合測試需圖形模式 `Godot --path PROJECT --script res://tests/test_ui.gd`。

## Godot MCP

已使用本機 `E:/Godot/GodotMCP/godot-mcp-main/godot-mcp-main/build/index.js` 完成 MCP 初始化與工具列舉、工程資訊查詢。Codex 持久連接以 `codex mcp add godot` 設定，遵循 [官方 MCP 文件](https://developers.openai.com/codex/mcp)。目前會話以工作區 `tools/godot_mcp_client.mjs` 的標準 MCP SDK client 呼叫，現有會話工具清單不會因此自動新增。
