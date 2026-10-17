# 窗光與顧客遮光

tea_shop.tscn / WindowSunlight 是獨立可重用效果場景，保留原有設備布局。
Inspector：Enabled 開關、Sunlight Energy 亮度、Sunlight Color 色溫、Cloud Amount 雲影變化、Cloud Speed 速度。
開啟 window_sunlight.tscn：Sun 可拖動調整窗外光源；WindowPatch 可調整桌面受光區位置／尺寸，Shader 的 Direction 調整亮帶斜度。

PointLight2D 與物品共用光照位元 2。HUD、訂單氣泡與標籤不受窗光影響。
人物 Avatar/SunOccluder 使用四張顧客透明輪廓生成的多邊形，依目前人物圖片及窗口裁切更新；走入／離開時投影跟隨，人物隱藏則立即停用。
物品 sun_backlight.tres 是水彩亮邊材質，受到同一個光源與顧客遮擋，並非永遠發亮的描邊。調整材質的 Rim Strength 可改亮邊強度；Face Brightness 為基礎正面明度。
雲影使用慢速噪聲驅動光強，不移動設備；遊戲暫停及離開營業頁面時停止雲影時間。

這是 2D 輪廓光照／投影，未建立真實 3D 高度或物理體積散射。窗格亮帶為藝術化光區。正式替換顧客圖像後，執行 tests/build_silhouettes.gd 重新生成對應 ui/customer_occluders 輪廓。
驗證：tests/test_window_sunlight.gd 比對無顧客／有顧客／顧客移動後的桌面與不透明物品像素，並檢查隱藏及暫停。

雲影更新：改用 96×96 移動噪聲燈光貼圖，每約 0.12 秒更新；桌面另有同源柔邊雲影對比，不影響 UI。Cloud Shadow Strength 控制桌面雲影濃度；Cloud Amount 控制遮光深度；Cloud Speed 控制掠過速度。三束亮帶已收窄約四分之一。
