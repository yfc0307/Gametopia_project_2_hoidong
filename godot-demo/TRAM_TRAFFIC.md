# 港式電車

素材：assets/hong-kong-tram-watercolor.png，內建 ImageGen 生成；同名 .prompt.txt 保存生成提示詞。
場景：hong_kong_tram.tscn 可替換圖片；tram_traffic.tscn 管理一輛可重用電車，不重疊生成。
茶舖：WindowMask/TramTraffic 在 Customers 前方的場景樹位置（視覺上位於顧客後方），由窗口原有 Clip Contents 裁切。
初次等候 4–8 秒；每次駛離後隨機等候 12–24 秒。速度 125 局部像素／秒，±8% 差異；由左往右。
Inspector 可調 first_delay_min/max、interval_min/max、travel_speed。Tram 的 Y、Scale 可手動調車道與大小，X 僅在運行時用於通過動畫。
車身使用透明輪廓遮光及獨立背光材質。只使用和顧客相同的車身輪廓遮光，不再壓暗整個操作區域或降低整盞燈的 Energy。
暫停時凍結電車及刷新倒數；新營業日重新抽首次進入時間。沒有更改正式存檔。
測試：tests/test_tram_traffic.gd，包含出現、行駛、輪廓、明暗像素差異、暫停及離場恢復。

Travel Speed 可調 30–2000，並允許手動輸入更高值。建議快車先試 600–900。現有場景中保存的速度與布局不會被腳本重設。局部投影驗證：tests/test_tram_local_shadow.gd。
