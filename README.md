# build_3Dcity
SketchUp plug-in for Stera_R

# DEMO
![image](https://user-images.githubusercontent.com/21374896/166086612-457337af-5897-42c0-bf1a-577889a501fc.png)

# Features

作成した３次元都市モデルをSketchUp上で修正するためのSketchUp用プラグインです

# Requirement

SketchUp2017以下（SketchUp2018以上は確認していません）

# Installation

C:\Users\ユーザー名\AppData\Roaming\SketchUp\SketchUp 2016\SketchUp\Plugins にコピーして，SketchUpのメニューの「ウインドウ」→「拡張機能マネージャー」をクリックして有効にしてください．（SketchUp2016以下では，「ウインドウ」→「環境設定」→「拡張機能」をクリックしてインストールしてください．）

# Usage

基準面を選択して，「Extensions」メニューからBuild 3Dcityを選択します．建物用途をプルダウンメニューで設定します．地上階数・地下階数を入力します．屋根タイプをプルダウンメニューから選択します．陸屋根以外の傾斜屋根については，屋根勾配以下のパラメータを設定します．平入り・妻入りの設定は，切妻屋根の屋根の流れ方向を設定します．流れ方向は片流れ屋根の流れ方向を設定します．用途地域の設定は，モデリング結果に用途地域図に基づく色で着色します．

# Note

Stera_Rで作成した３次元都市モデルを分解し，基準面以外の不要な面（屋根・壁等）はすべて削除します．SketchUpで作図した四角形にも適用できます．なお，Ｘ・Ｙ軸に平行な辺の場合，傾斜屋根のモデリング結果が不良になります．

# Author

* 山﨑 俊夫 ／ Toshio YAMAZAKI
* 函館工業高等専門学校 ／ UPCS（Urban Planning Cyber Studio）
* toshi_ya@hakodate-ct.ac.jp  ／ lisa9500jp@gmail.com

# License

"build 3Dcity" is under [MIT license](https://en.wikipedia.org/wiki/MIT_License).
