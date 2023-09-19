<img src="https://github.com/fangpindar/GoYo/blob/main/Image/logo.png">
**GoYo是一款為所有狗主人打造的App，除了提供一個狗狗社群平台，讓您可以與其他寵物愛好者分享寵物的點滴外，還讓您能夠輕鬆設置多個寵物角色，並為每個寵物定制獨特的照顧行事曆。這個功能讓您可以更方便地紀錄和管理每隻寶貝的生活，並設定提醒事項，確保不會錯過任何重要的寵物照顧細節。讓GoYo成為您與您的毛小孩共同生活的最佳伙伴！**


功能介紹
-------------
- 個人頁面：透過列表方式，一覽自家或其他狗友的狗寶貝生活照，分享並參與狗狗們的每一天
- 文章分享：狗友們透過圖文方式，分享狗寶貝的生活日常，亦可達到紀錄狗狗們生活的一種好方法。
- 原生拍照功能：使用原生AVFundation，進行最美的狗狗拍照，清晰的畫質及滿版的預覽，捕捉狗狗們的美好畫面。
- 濾鏡功能：使用原生CIFilter，製作出多種不同的濾鏡，提供狗友們可製作令人驚豔的美妙照片。
- 文章品質把關：透過CoreML搭配YOLO，防範非狗狗相關的照片出現，確保App品質。
- 遛狗距離紀錄：使用原生MapKit進行高精度的室外距離計算，記錄每次遛狗距離，並依照累積值提供相對應的獎章，刺激狗主人更想出門遛狗。
- 事件提醒：手動新增欲提醒的事件，可針對各個狗寶貝們設定事件，也可自行使用ColorPicker自定義標籤顏色，並可設定相關週期性(ex: 每週、每月)，搭配地端Notification進行提醒，不錯過狗寶貝的任何重要的事情。
- 行事曆：透過第三方套件FSCalendar，以行事曆方式呈現，一覽近期的重要事件提醒，並適時的做修正與新增。

<div style="display: inline-block">
<img width="200" src="https://github.com/fangpindar/GoYo/blob/main/Image/Frame%204.png" />
<img width="200" src="https://github.com/fangpindar/GoYo/blob/main/Image/Frame%205.png" />
<img width="200" src="https://github.com/fangpindar/GoYo/blob/main/Image/Frame%206.png" />
</div>
<br />
<div style="display: inline-block">
<img width="200" src="https://github.com/fangpindar/GoYo/blob/main/Image/Frame%207.png" />
<img width="200" src="https://github.com/fangpindar/GoYo/blob/main/Image/Frame%208.png" />
<img width="200" src="https://github.com/fangpindar/GoYo/blob/main/Image/Frame%209.png" />
</div>
<br />

<div style="display: inline-block">
<img width="200" src="https://github.com/fangpindar/GoYo/blob/main/Image/Frame%201.png" />
<img width="200" src="https://github.com/fangpindar/GoYo/blob/main/Image/Frame%202.png" />
<img width="200" src="https://github.com/fangpindar/GoYo/blob/main/Image/Frame%203.png" />
</div>
<br />

<div style="display: inline-block">
<img width="200" src="https://github.com/fangpindar/GoYo/blob/main/Image/Frame%2010.png" />
<img width="200" src="https://github.com/fangpindar/GoYo/blob/main/Image/Frame%2011.png" />
<img width="200" src="https://github.com/fangpindar/GoYo/blob/main/Image/Frame%2012.png" />
</div>


此App使用到以下第三方套件及第三方資料集
-------------
- SwiftLint
- IQKeyboardManagerSwift
- GoogleSignIn
- Hashtags
- JGProgressHUD
- EasyRefresher
- Kingfisher
- FSCalendar
- Firebase
- lottie-ios
- YOLOv3

安裝方式
-------------
- 將此份專案下載完畢後，請至https://developer.apple.com/machine-learning/models/ 下載YOLOv3.mlmodel，並將檔案放置於/GoYo/GoYo資料夾中
