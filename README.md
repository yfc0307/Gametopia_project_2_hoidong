# Gametopia_project_2_hoidong

## 開檔 · 涼茶舖 Godot Demo

### 成員啟動方式

1. 在 GitHub Desktop Clone 此 repo（已有副本則 Pull）。
2. 使用 **Godot 4.7.2**，在專案管理員按 Import，選擇 `godot-demo/project.godot`。
3. 等待首次素材匯入完成，按 **F5**，從選關頁面開始。
4. 主頁底部提供各項升級測試入口；測試模式不寫入正常進度。
5. 主頁右上角「自訂音效」可試聽及錄製 21 種音效；支援隨機挑選、側欄選擇、自動剪去首尾靜音與還原原音。只有按「開始錄音」才會開啟麥克風。

Renderer 使用 Compatibility；場景與素材已包含，不需要另外下載套件。

### 協作編輯

- 入口：`godot-demo/main.tscn`；關卡：`godot-demo/scenes/pages/tea_shop.tscn`。
- 頁面位於 `scenes/pages/`；共用設備與 UI 位於 `scenes/components/`。
- 請從設備父節點調整位置，保留已有手動布局；修改前先閱讀工程的 `AGENTS.md`。
- 字體已包含於 `assets/fonts/`，授權文件隨素材一起提供。
- `.godot/` 為本機產生的快取，不提交；`.uid` 和素材 `.import` 檔案需保留。
- 玩家存檔位於各自電腦的 Godot `user://`，不會跟隨 Git 分享。
- 自訂錄音另存於 `user://custom_sfx_gametopia/`；功能說明及全部觸發條件見 `godot-demo/SOUND_CUSTOMISATION.txt` 和 `godot-demo/SOUND_EFFECTS.txt`。
- 請在自己的分支修改，提交前檢查 Changes，避免同時覆蓋其他人的場景布局。

更多玩法與元件說明見 `godot-demo/` 內的 Markdown 文件；部分早期說明可能落後於目前 demo，實際場景與設定為準。
