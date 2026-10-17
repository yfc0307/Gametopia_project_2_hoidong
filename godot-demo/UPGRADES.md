# 升級實作與測試入口

六項 GDD 升級：茶葉蛋 8→5 秒、五茶各自自動補碗、龜苓膏四份、燒賣六份、雙口味魚蛋、魚蛋快速補料。
主頁底部八個入口直接啟動指定配置，含基礎及全部升級。測試收入／天數／升級不寫入正式進度；返回主頁恢復正式進度。
正式購買由「設備與升級」進入；魚蛋快速補料需先購買魚蛋。下一營業日生效，購買永久保存，庫存每日重置。

魚蛋：生料兩顆一批、兩槽各六顆、共享生料十二顆；熟後浮起。竹籤置於裝填位後點熟魚蛋，同籤最多三顆同口味。短暫停手會返回裝填位，保留半成品；一／兩顆可交付，按比例收費。電話補滿已解鎖食物。
五茶：每壺獨立 1.2 秒裝填，拿起不補，交付／丟棄才補；無效落點回原位。

所有新可見物件保存在原生 .tscn：upgrade_stations、auto_tea_slot、upgrade_tests。原有 teashop 設備的位置與縮放保留 Nicole 最新編輯。
價格與升級時序在 config/balance.json 的 upgrade_prices / upgrade_rules；售價及升級價格為試算值。
占位食物素材 assets/upgrade-foods.png 由 ImageGen 生成，透明水彩手繪圖集；AtlasTexture 可換正式素材。

驗證：tests/test_upgrades.gd、test_upgrade_ui.gd、test_ui.gd、test_tea_labels.gd。
