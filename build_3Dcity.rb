# First we pull in the standard API hooks.
require 'sketchup.rb'

# Show the Ruby Console at startup so we can
# see any programming errors we may make.
# SKETCHUP_CONSOLE.show

# Numericクラス拡張
class Numeric
  # メートル⇒インチ
  def m_inch
    self / 0.0254
  end
end

# JavaScript互換
def alert(msg)
  UI.messagebox msg
end

# エンティティ属性
def get_attrib(f, k, v=nil)
  f.get_attribute('Default', k, v)
end

# 選択エンティティ取得
def get_selected
  sel = Sketchup.active_model.selection
  if sel.length >= 1
    return sel[0]
  else
    return nil
  end
end

# 選択された面／辺の情報を表示
def show_selected
  # 選択エンティティ
  object = get_selected
  if object.is_a? Sketchup::Face
    # 面…そのまま
  else
    # 選択なし
    alert '基準面を選択してください。'
    return
  end
end

def call_UIbox
  model = Sketchup.active_model # Open model
  if (! model)
    UI.messagebox "Failure"
  else
    # code acting on the model
    entities = model.active_entities

    prompts = ["建物用途", "地上階数", "地下階数", "屋根タイプ", "屋根勾配", "平入り･妻入り", "流れ方向", "軒庇の長さ", "けらば幅", "屋根厚さ", "用途地域"]
    defaults = ["住宅", "2", "0", "陸屋根", "0.5", "入れ換えなし", "回転なし", "0.3", "0.2", "0.2", "なし"]
    list = ["住宅|店舗|オフィスビル|デパート|ホテル|マンション", "", "", "陸屋根|切妻屋根|寄棟屋根|入母屋屋根|片流れ屋根|町家･長屋", "","入れ換えなし|入れ換えあり", "回転なし|左90°回転|180°回転|右90°回転", "", "", "", "なし|第一種低層住居専用地域|第二種低層住居専用地域|第一種中高層住居専用地域|第二種中高層住居専用地域|第一種住居地域|第二種住居地域|準住居地域|近隣商業地域|商業地域|準工業地域|工業地域|工業専用地域"]
  @input = UI.inputbox(prompts, defaults, list, "建物属性データ")
  end
end

def youto_d_color(youto_d)
  if youto_d == "なし"
    [255,255,255]
  elsif youto_d == "第一種低層住居専用地域"
    [0,165,104]
  elsif youto_d == "第二種低層住居専用地域"
    [119,183,158]
  elsif youto_d == "第一種中高層住居専用地域"
    [80,175,108]
  elsif youto_d == "第二種中高層住居専用地域"
    [190,205,0]
  elsif youto_d == "第一種住居地域"
    [255,239,68]
  elsif youto_d == "第二種住居地域"
    [249,178,0]
  elsif youto_d == "準住居地域"
    [238,127,0]
  elsif youto_d == "近隣商業地域"
    [240,145,154]
  elsif youto_d == "商業地域"
    [232,88,133]
  elsif youto_d == "準工業地域"
    [209,189,217]
  elsif youto_d == "工業地域"
    [191,226,231]
  elsif youto_d == "工業専用地域"
    [80,107,173]
  else
    [255,255,255]
  end
end

# 地下部分の深さ計算
def basement(story, base_f)
  if story.to_i > 0
    depth = 3.0 * @input[2].to_i
  else
    if base_f.to_i > 3
      depth = 1.0
    else
      depth = 0.3
    end
  end
end

# 地上部分の高さ計算
def height(yanetype, story, youto)
  # 町家・長屋の高さ設定
  if yanetype == "町家･長屋"
    height = 2.7
  # 傾斜屋根家屋の高さ計算
  elsif (yanetype != "陸屋根") && (story.to_i <= 3)
    height = 3.25 + 2.5 * (story.to_i - 1)
  # 専門店・飲食店の高さ計算
  elsif youto == "店舗"
    height = 3.2 * story.to_i
  # 事務所ビルの高さ計算
  elsif youto == "オフィスビル"
    height = 4.2 + 3.5 * (story.to_i - 1)
  # デパート・スーパーの高さ計算
  elsif youto == "デパート"
    height = 4.0 + 3.5 * (story.to_i - 1)
  # ホテルの高さ計算
  elsif youto == "ホテル"
    height = 4.2 + 3.2 * (story.to_i - 1)
  # マンションの高さ計算
  elsif youto == "マンション"
    height = 3.2 * story.to_i
  # その他住宅の高さ計算
  else
    height = 3.3 * story.to_i
  end
end

# hiratumaスイッチによる平入りと妻入りの入れ換え
def change_iri(chk_hiratuma, pts_t)
  if chk_hiratuma == "入れ換えあり"
    pts_tmp = []
    for i in 1..4
      pts_tmp[i] = pts_t[i]
    end
    for j in 1..3
      pts_t[j] = pts_tmp[j+1]
    end
    pts_t[4] = pts_tmp[1]
  end
  pts_t[0] = nil
  return pts_t[0], pts_t[1], pts_t[2], pts_t[3], pts_t[4]
end

# 妻壁の高さ
def tumakabe_high(pts_t, incline)
  len_s2 = Math.sqrt((pts_t[2][0] - pts_t[3][0]) ** 2 + (pts_t[2][1] - pts_t[3][1]) ** 2)
  tuma1_height = len_s2 / 2 * incline
  len_s4 = Math.sqrt((pts_t[4][0] - pts_t[1][0]) ** 2 + (pts_t[4][1] - pts_t[1][1]) ** 2)
  tuma2_height = len_s4 / 2 * incline
  tuma_height = (tuma1_height + tuma2_height) / 2
  return tuma_height
end

# 妻面の中間座標の算出
def ave_tuma(xy_1, xy_2)
  abs_xy_1 = xy_1.abs
  abs_xy_2 = xy_2.abs
  ave_xy = (abs_xy_1 + abs_xy_2) / 2
  if xy_1 <0 && xy_2 >=0
	if abs_xy_1 > abs_xy_2
	  ave_xy = abs_xy_2 - ave_xy
	else
	  ave_xy = -(abs_xy_1 - ave_xy)
	end
  elsif xy_1 >=0 && xy_2 <0
	if abs_xy_1 > abs_xy_2
	  ave_xy = abs_xy_1 - ave_xy
	else
	  ave_xy = -(abs_xy_2 - ave_xy)
	end
  elsif xy_1 >=0 && xy_2 >=0
    ave_xy = ave_xy
  elsif xy_1 <0 && xy_2 <0
    ave_xy = -ave_xy
  end
  return ave_xy
end

# 妻壁の頂点座標の計算
def tuma_top_5(pts_t, tuma_height)
  pts_t[5] = []
  x = ave_tuma(pts_t[2][0], pts_t[3][0])
  pts_t[5].push(x)
  y = ave_tuma(pts_t[2][1], pts_t[3][1])
  pts_t[5].push(y)
  z = (pts_t[2][2] + pts_t[3][2]) / 2 + tuma_height
  pts_t[5].push(z)
  return pts_t[5]
end
def tuma_top_6(pts_t, tuma_height)
  pts_t[6] = []
  x = ave_tuma(pts_t[4][0], pts_t[1][0])
  pts_t[6].push(x)
  y = ave_tuma(pts_t[4][1], pts_t[1][1])
  pts_t[6].push(y)
  z = (pts_t[4][2] + pts_t[1][2]) / 2 + tuma_height
  pts_t[6].push(z)
  return pts_t[6]
end

# 法線ベクトルの計算
def normal_vector(p1, p2, p3)
  v1 = []
  v2 = []
  cross = []
  for i in 1..3
    v1[i] = p1[i] - p2[i]
  end
  for i in 1..3
    v2[i] = p3[i] - p2[i]
  end
  for i in 1..3
    cross[i] = v2[(i+1)%3+1] * v1[(i+0)%3+1] - v2[(i+0)%3+1] * v1[(i+1)%3+1]
  end
  length = Math.sqrt(cross[1] * cross[1] + cross[2] * cross[2] + cross[3] * cross[3])
  normal = []
  for i in 1..3
    normal[i] = cross [i] / length
  end
  return normal
end

# 平面座標の書き出し
def plate_pts(vertex, x, y, z)
  pts_p = []
  for i in 1..vertex
    pts_p[i] = [x[i], y[i], z[i]]
  end
  return pts_p
end

# Add a menu item to launch our plugin.
UI.menu("Plugins").add_item("Build 3Dcity") {
  # UI.messagebox("I'm about to build 3Dcity!")
  model = Sketchup.active_model
  entities = model.active_entities
  materials = model.materials
  
  # Call our new method.
  face = get_selected
  if face.is_a? Sketchup::Face
    call_UIbox
  else
    # 選択なし
    alert '基準面を選択してください。'
  end
  
  # 頂点数を確認する
  vertex = face.vertices
  number = vertex.length
  
  # 基準面の頂点座標を得る
  pts = []
  for i in 1..number
    pts[i] = vertex[i-1].position
  end
  
  # 建物モデリングの開始
  # 用途地域による色の設定
  youto_d = @input[10]
  face.material = youto_d_color(youto_d)
  
  # 地下部分のモデリング
  story = @input[2]
  base_f = @input[1]
  thickness_B = basement(story, base_f).m_inch
  status = face.pushpull thickness_B
  
  # 地上部分のモデリング
  yanetype = @input[3]
  story = @input[1]
  youto = @input[0]
  thickness = height(yanetype, story, youto).m_inch
  status = face.pushpull thickness
  
  # 基準面の復元
  # grp = entities.add_group
  pts_set = [pts[1]]
  for j in 2..number
    pts_set.push(pts[j])
  end
  # face = grp.entities.add_face pts_set
  face = entities.add_face pts_set
  
  # 傾斜屋根モデルのモデリング
  if number == 4
    # 上面の頂点座標を得る
    pts_t = []
    pts_t[1] = vertex[0].position
    pts_t[2] = vertex[1].position
    pts_t[3] = vertex[2].position
    pts_t[4] = vertex[3].position
	
    # 平側と妻側の長さをチェックする
    l_s1 = Math.sqrt((pts[1][0] - pts[2][0]) ** 2 + (pts[1][1] - pts[2][1]) ** 2)
    l_s2 = Math.sqrt((pts[2][0] - pts[3][0]) ** 2 + (pts[2][1] - pts[3][1]) ** 2)
    l_s3 = Math.sqrt((pts[3][0] - pts[4][0]) ** 2 + (pts[3][1] - pts[4][1]) ** 2)
    l_s4 = Math.sqrt((pts[4][0] - pts[1][0]) ** 2 + (pts[4][1] - pts[1][1]) ** 2)
    
    # 直線S1･s3が直線S2･s4より短い場合，平側と妻側を入れ替える
    xb_r = []
    yb_r = []
    xt_r = []
    yt_r = []
    if (l_s1 + l_s3) < (l_s2 + l_s4)
      for j in 1..4
        xb_r[j] = pts[j][0]
        yb_r[j] = pts[j][1]
        xt_r[j] = pts_t[j][0]
        yt_r[j] = pts_t[j][1]
      end
      for j in 1..3
        pts[j][0] = xb_r[j+1]
        pts[j][1] = yb_r[j+1]
        pts_t[j][0] = xt_r[j+1]
        pts_t[j][1] = yt_r[j+1]
      end
      pts[4][0] = xb_r[1]
      pts[4][1] = yb_r[1]
      pts_t[4][0] = xt_r[1]
      pts_t[4][1] = yt_r[1]
    end
	
	# hiratumaスイッチが入れ換えありの場合（平入り⇔妻入り）
	if @input[3] != "片流れ屋根"
	  chk_hiratuma = @input[5]
      pts = change_iri(chk_hiratuma, pts)
	  pts_t = change_iri(chk_hiratuma, pts_t)
	end
    
    # 屋根頂点座標の算出（共通事項）
    # 直線（辺）の傾きと切片
    a = []  # 直線（辺）の傾き
    b = []  # 直線（辺）の切片
    
    # 直線S1(頂点1→2)～直線S4(頂点4→1)の式
    for i in 1..4
      if i == 4
        if (pts_t[i][0] - pts_t[1][0]) == 0
          pts_t[i][0] = pts_t[1][0] + 0.00001
        end
        a[i] = (pts_t[i][1] - pts_t[1][1]) / (pts_t[i][0] - pts_t[1][0])
      else
        if (pts_t[i][0] - pts_t[i+1][0]) == 0
          pts_t[i][0] = pts_t[i+1][0] + 0.00001
        end
        a[i] = (pts_t[i][1] - pts_t[i+1][1]) / (pts_t[i][0] - pts_t[i+1][0])
      end
      b[i] = pts_t[i][1] - pts_t[i][0] * a[i]
    end
    
    # 直線に平行な直線の式（傾きは同じ）
    # hisashi, kerabaに応じて切片が変化
    hisashi = (@input[7].to_f).m_inch
    keraba = (@input[8].to_f).m_inch
    # 基本はS1，S3の面に対して平入り
    d = [hisashi, keraba, hisashi, keraba]
    # hiratumaスイッチが入れ換えありの場合（平入り⇔妻入り）
    if @input[5] == "入れ換えあり"
      d = [keraba, hisashi, keraba, hisashi]
    end
    # 寄棟屋根/入母屋屋根の場合
    if @input[3] == "寄棟屋根" || @input[3] == "入母屋屋根"
      d = [hisashi, hisashi, hisashi, hisashi]
    end
    # 片流れ屋根の場合，流れ方向が左90°回転，右90°回転の場合
    if @input[3] == "片流れ屋根"
      if @input[6] == "左90°回転" || @input[6] == "右90°回転"
        d = [keraba, hisashi, keraba, hisashi]
      end
    end

    # 仮の切片の値の算出(xMaxの時のｙの値)
    xMax = pts_t[1][0]
    for i in 2..4
      if xMax < pts_t[i][0]
        xMax = pts_t[i][0]
      end
    end
    br = []
    for j in 1..4
      br[j] = xMax * a[j] + b[j]
    end

    # 向かい合う直線の切片間の距離
    _D = []
    _D[1] = (br[1] - br[3]).abs
    _D[2] = (br[2] - br[4]).abs
    _D[3] = (br[3] - br[1]).abs
    _D[4] = (br[4] - br[2]).abs
 
    # 直線S1(頂点1→2)～直線S4(頂点4→1)に平行な直線の式の切片
    _B = Array.new(5){ Array.new(3) }
    bo = []
    for i in 1..2
      _B[i][1] = br[i] + d[i-1] * Math.sqrt(a[i] ** 2 + 1)
      _B[i][2] = br[i] - d[i-1] * Math.sqrt(a[i] ** 2 + 1)
      if _D[i] < (_B[i][1] - br[i + 2]).abs
        bo[i] = b[i] + d[i-1] * Math.sqrt(a[i] ** 2 + 1)
      elsif
        bo[i] = b[i] - d[i-1] * Math.sqrt(a[i] ** 2 + 1)
      end
    end
    for i in 3..4
      _B[i][1] = br[i] + d[i-1] * Math.sqrt(a[i] ** 2 + 1)
      _B[i][2] = br[i] - d[i-1] * Math.sqrt(a[i] ** 2 + 1)
      if _D[i] < (_B[i][1] - br[i - 2]).abs
        bo[i] = b[i] + d[i-1] * Math.sqrt(a[i] ** 2 + 1)
      elsif
        bo[i] = b[i] - d[i-1] * Math.sqrt(a[i] ** 2 + 1)
      end
    end
    
    # 屋根モデルのための４頂点の設定
    pts_o = Array.new(5){ Array.new(3) }
    pts_r = Array.new(5){ Array.new(3) }
    
    # 屋根モデルのための４頂点のＸ･Ｙ座標の算出
    for i in 1..4
      if i == 1
        pts_o[i][0] = (bo[i] - bo[4]) / (a[4] - a[i])
      elsif
        pts_o[i][0] = (bo[i] - bo[i-1]) / (a[i-1] - a[i])
      end
      pts_r[i][0] = pts_o[i][0]
      pts_o[i][1] = pts_o[i][0] * a[i] + bo[i]
      pts_r[i][1] = pts_o[i][1]
      pts_r[i][2] = pts_o[i][2] = pts_t[i][2]
    end
    
	# 屋根モデルのための4頂点のX・Y座標の設定
	xo = []
	yo = []
	xo[1] = pts_o[1][0]
	yo[1] = pts_o[1][1]
	xo[2] = pts_o[2][0]
	yo[2] = pts_o[2][1]
	xo[3] = pts_o[3][0]
	yo[3] = pts_o[3][1]
	xo[4] = pts_o[4][0]
	yo[4] = pts_o[4][1]
	
    # 切妻屋根の家型のモデリング
    if @input[3] == "切妻屋根"
	  # 妻壁の頂点の高さの計算
	  incline = @input[4].to_f
      tuma_height = tumakabe_high(pts_t, incline)
    
      # 妻壁の頂点座標の計算
      pts_t[5] = tuma_top_5(pts_t, tuma_height)
	  pts_t[6] = tuma_top_6(pts_t, tuma_height)
	  
      # 妻面と屋根裏面のモデリング
      face = entities.add_face(pts_t[5], pts_t[2], pts_t[3])
      face.material = youto_d_color(youto_d)
      face = entities.add_face(pts_t[6], pts_t[4], pts_t[1])
      face.material = youto_d_color(youto_d)
      face = entities.add_face(pts_t[1], pts_t[2], pts_t[5])
      face.material = youto_d_color(youto_d)
      face = entities.add_face(pts_t[5], pts_t[6], pts_t[1])
      face.material = youto_d_color(youto_d)
      face = entities.add_face(pts_t[3], pts_t[4], pts_t[6])
      face.material = youto_d_color(youto_d)
      face = entities.add_face(pts_t[6], pts_t[5], pts_t[3])
      face.material = youto_d_color(youto_d)
	  
	  edge1 = entities.add_line(pts_t[2],pts_t[3])
	  entities.erase_entities edge1
	  edge2 = entities.add_line(pts_t[4],pts_t[1])
	  entities.erase_entities edge2
    end
	
    # 切妻屋根のモデリング
    if @input[3] == "切妻屋根"
      xo1 = []
      yo1 = []
      zo1 = []
      xo2 = []
      yo2 = []
      zo2 = []
      xr1 = []
      yr1 = []
      zr1 = []
      xr2 = []
      yr2 = []
      zr2 = []
      
      # 軒下端の高さ（Ｚ座標）
      hisashi = (@input[7].to_f).m_inch
      incline = @input[4].to_f
      nh = hisashi * incline
      zo1[1] = pts_t[1][2] - nh
      zo1[2] = pts_t[2][2] - nh
      zo2[1] = pts_t[3][2] - nh
      zo2[2] = pts_t[4][2] - nh
      
      # yaneatuによる垂直方向の高さ（軒側）
      yaneatu = (@input[9].to_f).m_inch
      kh = yaneatu / Math.sqrt(1 + incline ** 2)
      # yaneatuによる垂直方向の高さ（棟側）
      rh = yaneatu * Math.sqrt(1 + incline ** 2)
      
      # 軒上端の高さ（Ｚ座標）
      zr1[1] = zo1[1] + kh
      zr1[2] = zo1[2] + kh
      zr2[1] = zo2[1] + kh
      zr2[2] = zo2[2] + kh
      
      # 棟頂点高さの計算
      zo1[3] = pts_t[5][2]
      zo1[4] = pts_t[6][2]
      zo2[3] = pts_t[6][2]
      zo2[4] = pts_t[5][2]
      zr1[3] = zo1[3] + rh
      zr1[4] = zo1[4] + rh
      zr2[3] = zo2[3] + rh
      zr2[4] = zo2[4] + rh
      
      # 軒頂点座標の計算
      xo1[1] = pts_o[1][0]
      yo1[1] = pts_o[1][1]
      xo1[2] = pts_o[2][0]
      yo1[2] = pts_o[2][1]
	  
	  xo2[1] = pts_o[3][0]
      yo2[1] = pts_o[3][1]
      xo2[2] = pts_o[4][0]
      yo2[2] = pts_o[4][1]
	  
	  xo1[3] = ave_tuma(pts_o[2][0], pts_o[3][0])
      yo1[3] = ave_tuma(pts_o[2][1], pts_o[3][1])
      xo1[4] = ave_tuma(pts_o[1][0], pts_o[4][0])
      yo1[4] = ave_tuma(pts_o[1][1], pts_o[4][1])
      
      xo2[3] = ave_tuma(pts_o[1][0], pts_o[4][0])
      yo2[3] = ave_tuma(pts_o[1][1], pts_o[4][1])
      xo2[4] = ave_tuma(pts_o[2][0], pts_o[3][0])
      yo2[4] = ave_tuma(pts_o[2][1], pts_o[3][1])
      
	  # 軒端のX･Y座標の算出
	  p1 = [0, xo1[4], yo1[4], zo1[4]]
	  p2 = [0, xo1[1], yo1[1], zo1[1]]
	  p3 = [0, xo1[2], yo1[2], zo1[2]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr1[1] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr1[1] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xo1[1], yo1[1], zo1[1]]
	  p2 = [0, xo1[2], yo1[2], zo1[2]]
	  p3 = [0, xo1[3], yo1[3], zo1[3]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr1[2] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr1[2] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xo2[4], yo2[4], zo2[4]]
	  p2 = [0, xo2[1], yo2[1], zo2[1]]
	  p3 = [0, xo2[2], yo2[2], zo2[2]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr2[1] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr2[1] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xo2[1], yo2[1], zo2[1]]
	  p2 = [0, xo2[2], yo2[2], zo2[2]]
	  p3 = [0, xo2[3], yo2[3], zo2[3]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr2[2] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr2[2] = kh / norRoof[3] * norRoof[2] + p2[2]
	  
	  # 棟端のX･Y座標の算出
	  xr1[3] = (xr1[2] + xr2[1]) / 2
	  yr1[3] = (yr1[2] + yr2[1]) / 2
	  xr1[4] = (xr1[1] + xr2[2]) / 2
	  yr1[4] = (yr1[1] + yr2[2]) / 2
	  xr2[3] = (xr1[1] + xr2[2]) / 2
	  yr2[3] = (yr1[1] + yr2[2]) / 2
      xr2[4] = (xr1[2] + xr2[1]) / 2
	  yr2[4] = (yr1[2] + yr2[1]) / 2
	  
	  # 屋根底面のモデリング
	  pts_b = plate_pts(4, xo1, yo1, zo1)
      face = entities.add_face(pts_b[3], pts_b[4], pts_b[1])
      face.material = "SlateGray"
      face = entities.add_face(pts_b[3], pts_b[1], pts_b[2])
      face.material = "SlateGray"
	  
	  pts_b = plate_pts(4, xo2, yo2, zo2)
      face = entities.add_face(pts_b[3], pts_b[4], pts_b[1])
      face.material = "SlateGray"
      face = entities.add_face(pts_b[3], pts_b[1], pts_b[2])
      face.material = "SlateGray"
	  
	  # 屋根上面のモデリング
	  pts_r = plate_pts(4, xr1, yr1, zr1)
      face = entities.add_face(pts_r[3], pts_r[4], pts_r[1])
	  face.material = "SlateGray"
      face = entities.add_face(pts_r[3], pts_r[1], pts_r[2])
      face.material = "SlateGray"
	  
	  pts_r = plate_pts(4, xr2, yr2, zr2)
      face = entities.add_face(pts_r[3], pts_r[4], pts_r[1])
      face.material = "SlateGray"
      face = entities.add_face(pts_r[3], pts_r[1], pts_r[2])
      face.material = "SlateGray"
	  
	  # 屋根側面のモデリング
	  pts_b = plate_pts(4, xo1, yo1, zo1)
	  pts_r = plate_pts(4, xr1, yr1, zr1)
	  face = entities.add_face(pts_b[1], pts_b[2], pts_r[1])
	  status = face.reverse!
      face.material = "SlateGray"
      face = entities.add_face(pts_r[2], pts_r[1], pts_b[2])
      face.material = "SlateGray"
      face = entities.add_face(pts_b[2], pts_b[3], pts_r[3])
	  status = face.reverse!
      face.material = "SlateGray"
      face = entities.add_face(pts_r[3], pts_r[2], pts_b[2])
      face.material = "SlateGray"
      face = entities.add_face(pts_b[4], pts_b[1], pts_r[4])
	  status = face.reverse!
      face.material = "SlateGray"
      face = entities.add_face(pts_r[1], pts_r[4], pts_b[1])
      face.material = "SlateGray"
	  
	  pts_b = plate_pts(4, xo2, yo2, zo2)
	  pts_r = plate_pts(4, xr2, yr2, zr2)
	  face = entities.add_face(pts_b[1], pts_b[2], pts_r[1])
	  status = face.reverse!
      face.material = "SlateGray"
      face = entities.add_face(pts_r[2], pts_r[1], pts_b[2])
      face.material = "SlateGray"
      face = entities.add_face(pts_b[2], pts_b[3], pts_r[3])
	  status = face.reverse!
      face.material = "SlateGray"
      face = entities.add_face(pts_r[3], pts_r[2], pts_b[2])
      face.material = "SlateGray"
      face = entities.add_face(pts_b[4], pts_b[1], pts_r[4])
	  status = face.reverse!
      face.material = "SlateGray"
      face = entities.add_face(pts_r[1], pts_r[4], pts_b[1])
      face.material = "SlateGray"
    end
	  
    # 寄棟屋根のモデリング
    if @input[3] == "寄棟屋根"
      # 軒下端の高さ（Ｚ座標）
	  zo = []
      zo[1] = pts_t[1][2]
      zo[2] = pts_t[2][2]
      zo[3] = pts_t[3][2]
      zo[4] = pts_t[4][2]
      # yaneatuによる垂直方向の高さ（軒側）
      yaneatu = (@input[9].to_f).m_inch
      incline = @input[4].to_f
      kh = yaneatu / Math.sqrt(1 + incline ** 2)
      
      # 軒上端の高さ（Ｚ座標）
	  zr = []
      zr[1] = zo[1] + kh
      zr[2] = zo[2] + kh
      zr[3] = zo[3] + kh
      zr[4] = zo[4] + kh
      
      # 寄棟屋根の軒上端座標の計算
      xr2 = []
      yr2 = []
      
      # 軒上端の高さ計算用の仮の高さ（Ｚ座標）
      zr_1 = []
      zr_1[1] = l_s4 * incline + zo[1]
	  zr_1[2] = l_s2 * incline + zo[2]
	  zr_1[3] = l_s2 * incline + zo[3]
	  zr_1[4] = l_s4 * incline + zo[4]
	  
	  # 平側の軒の出を計算する
	  p1 = [0, xo[4], yo[4], zr_1[4]]
	  p2 = [0, xo[1], yo[1], zo[1]]
	  p3 = [0, xo[2], yo[2], zo[2]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr2[1] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr2[1] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xo[1], yo[1], zo[1]]
	  p2 = [0, xo[2], yo[2], zo[2]]
	  p3 = [0, xo[3], yo[3], zr_1[3]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr2[2] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr2[2] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xo[2], yo[2], zr_1[2]]
	  p2 = [0, xo[3], yo[3], zo[3]]
	  p3 = [0, xo[4], yo[4], zo[4]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr2[3] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr2[3] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xo[3], yo[3], zo[3]]
	  p2 = [0, xo[4], yo[4], zo[4]]
	  p3 = [0, xo[1], yo[1], zr_1[1]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr2[4] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr2[4] = kh / norRoof[3] * norRoof[2] + p2[2]
	  
	  # 軒上端の高さ計算用の仮の高さ（Ｚ座標）
	  zr_2 = []
	  zr_2[1] = l_s1 * incline + zo[1]
	  zr_2[2] = l_s3 * incline + zo[2]
	  zr_2[3] = l_s3 * incline + zo[3]
	  zr_2[4] = l_s1 * incline + zo[4]
	  
	  # 妻側の軒の出を計算する
	  xr = []
	  yr = []
	  p1 = [0, xr2[1], yr2[1], zr_2[1]]
	  p2 = [0, xr2[2], yr2[2], zo[2]]
	  p3 = [0, xr2[3], yr2[3], zo[3]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr[2] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr[2] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xr2[2], yr2[2], zo[2]]
	  p2 = [0, xr2[3], yr2[3], zo[3]]
	  p3 = [0, xr2[4], yr2[4], zr_2[4]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr[3] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr[3] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xr2[3], yr2[3], zr_2[3]]
	  p2 = [0, xr2[4], yr2[4], zo[4]]
	  p3 = [0, xr2[1], yr2[1], zo[1]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr[4] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr[4] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xr2[4], yr2[4], zo[4]]
	  p2 = [0, xr2[1], yr2[1], zo[1]]
	  p3 = [0, xr2[2], yr2[2], zr_2[2]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr[1] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr[1] = kh / norRoof[3] * norRoof[2] + p2[2]
      
	  # 棟頂点座標の設定
	  xt2 = []
	  yt2 = []
	  xm2 = []
	  ym2 = []
	  zm2 = []
	  # 妻側の中点計算
	  xt2[1] = (xr[1] + xr[4]) / 2
	  yt2[1] = (yr[1] + yr[4]) / 2
	  xt2[2] = (xr[2] + xr[3]) / 2
	  yt2[2] = (yr[2] + yr[3]) / 2
	  # 棟頂点の座標計算
	  xm2[1] = (xt2[1] * 3 + xt2[2]) / 4
	  ym2[1] = (yt2[1] * 3 + yt2[2]) / 4
	  xm2[2] = (xt2[2] * 3 + xt2[1]) / 4
	  ym2[2] = (yt2[2] * 3 + yt2[1]) / 4
	  xm2[3] = (xt2[2] * 3 + xt2[1]) / 4
	  ym2[3] = (yt2[2] * 3 + yt2[1]) / 4
	  xm2[4] = (xt2[1] * 3 + xt2[2]) / 4
	  ym2[4] = (yt2[1] * 3 + yt2[2]) / 4
	  zm2[1] = Math.sqrt((xt2[1] - xm2[1]) ** 2 + (yt2[1] - ym2[1]) ** 2) * incline + (zr[1] + zr[4]) / 2
	  zm2[2] = Math.sqrt((xt2[2] - xm2[2]) ** 2 + (yt2[2] - ym2[2]) ** 2) * incline + (zr[2] + zr[3]) / 2
	  zm2[3] = Math.sqrt((xt2[2] - xm2[2]) ** 2 + (yt2[2] - ym2[2]) ** 2) * incline + (zr[2] + zr[3]) / 2
	  zm2[4] = Math.sqrt((xt2[1] - xm2[1]) ** 2 + (yt2[1] - ym2[1]) ** 2) * incline + (zr[1] + zr[4]) / 2
	  
	  # 屋根底面のモデリング
	  pts_b = plate_pts(4, xo, yo, zo)
      face = entities.add_face(pts_b[1], pts_b[2], pts_b[3], pts_b[4])
	  status = face.reverse!
      face.material = "SlateGray"
	  
	  # 屋根上面のモデリング
	  pts_r = plate_pts(4, xr, yr, zr)
	  pts_m = plate_pts(4, xm2, ym2, zm2)
      face = entities.add_face(pts_r[1], pts_r[2], pts_m[2])
	  face.material = "SlateGray"
	  face = entities.add_face(pts_m[2], pts_m[1], pts_r[1])
	  face.material = "SlateGray"
	  face = entities.add_face(pts_r[3], pts_r[4], pts_m[4])
	  face.material = "SlateGray"
	  face = entities.add_face(pts_m[4], pts_m[3], pts_r[3])
	  face.material = "SlateGray"
	  face = entities.add_face(pts_r[4], pts_r[1], pts_m[1])
	  face.material = "SlateGray"
	  face = entities.add_face(pts_r[2], pts_r[3], pts_m[3])
	  face.material = "SlateGray"
	  
	  # 屋根側面のモデリング
	  pts_b = plate_pts(4, xo, yo, zo)
	  pts_r = plate_pts(4, xr, yr, zr)
	  face = entities.add_face(pts_b[1], pts_b[2], pts_r[1])
	  status = face.reverse!
      face.material = "SlateGray"
      face = entities.add_face(pts_r[2], pts_r[1], pts_b[2])
	  status = face.reverse!
      face.material = "SlateGray"
	  face = entities.add_face(pts_b[2], pts_b[3], pts_r[2])
	  status = face.reverse!
      face.material = "SlateGray"
      face = entities.add_face(pts_r[3], pts_r[2], pts_b[3])
	  status = face.reverse!
      face.material = "SlateGray"
	  face = entities.add_face(pts_b[3], pts_b[4], pts_r[3])
	  status = face.reverse!
      face.material = "SlateGray"
      face = entities.add_face(pts_r[4], pts_r[3], pts_b[4])
	  status = face.reverse!
      face.material = "SlateGray"
	  face = entities.add_face(pts_b[4], pts_b[1], pts_r[4])
	  status = face.reverse!
      face.material = "SlateGray"
      face = entities.add_face(pts_r[1], pts_r[4], pts_b[1])
	  status = face.reverse!
      face.material = "SlateGray"
    end
    
    # 入母屋屋根のモデリング
    if @input[3] == "入母屋屋根"
	  # 軒下端の高さ（Ｚ座標）
	  zo = []
      zo[1] = pts_t[1][2]
      zo[2] = pts_t[2][2]
      zo[3] = pts_t[3][2]
      zo[4] = pts_t[4][2]
	  # yaneatuによる垂直方向の高さ（軒側）
      yaneatu = (@input[9].to_f).m_inch
      incline = @input[4].to_f
      kh = yaneatu / Math.sqrt(1 + incline ** 2)
	  
	  # 軒上端の高さ（Ｚ座標）
	  zr = []
      zr[1] = zo[1] + kh
      zr[2] = zo[2] + kh
      zr[3] = zo[3] + kh
      zr[4] = zo[4] + kh
      
	  # 入母屋屋根の軒上端座標の計算
      xr2 = []
      yr2 = []
      
	  # 軒上端の高さ計算用の仮の高さ（Ｚ座標）
      zr_1 = []
      zr_1[1] = l_s4 * incline + zo[1]
	  zr_1[2] = l_s2 * incline + zo[2]
	  zr_1[3] = l_s2 * incline + zo[3]
	  zr_1[4] = l_s4 * incline + zo[4]
	  
      # 平側の軒の出を計算する
	  p1 = [0, xo[4], yo[4], zr_1[4]]
	  p2 = [0, xo[1], yo[1], zo[1]]
	  p3 = [0, xo[2], yo[2], zo[2]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr2[1] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr2[1] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xo[1], yo[1], zo[1]]
	  p2 = [0, xo[2], yo[2], zo[2]]
	  p3 = [0, xo[3], yo[3], zr_1[3]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr2[2] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr2[2] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xo[2], yo[2], zr_1[2]]
	  p2 = [0, xo[3], yo[3], zo[3]]
	  p3 = [0, xo[4], yo[4], zo[4]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr2[3] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr2[3] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xo[3], yo[3], zo[3]]
	  p2 = [0, xo[4], yo[4], zo[4]]
	  p3 = [0, xo[1], yo[1], zr_1[1]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr2[4] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr2[4] = kh / norRoof[3] * norRoof[2] + p2[2]
	  
	  # 軒上端の高さ計算用の仮の高さ（Ｚ座標）
	  zr_2 = []
	  zr_2[1] = l_s1 * incline + zo[1]
	  zr_2[2] = l_s3 * incline + zo[2]
	  zr_2[3] = l_s3 * incline + zo[3]
	  zr_2[4] = l_s1 * incline + zo[4]
	  
	  # 妻側の軒の出を計算する
	  xr = []
	  yr = []
	  p1 = [0, xr2[1], yr2[1], zr_2[1]]
	  p2 = [0, xr2[2], yr2[2], zo[2]]
	  p3 = [0, xr2[3], yr2[3], zo[3]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr[2] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr[2] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xr2[2], yr2[2], zo[2]]
	  p2 = [0, xr2[3], yr2[3], zo[3]]
	  p3 = [0, xr2[4], yr2[4], zr_2[4]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr[3] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr[3] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xr2[3], yr2[3], zr_2[3]]
	  p2 = [0, xr2[4], yr2[4], zo[4]]
	  p3 = [0, xr2[1], yr2[1], zo[1]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr[4] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr[4] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xr2[4], yr2[4], zo[4]]
	  p2 = [0, xr2[1], yr2[1], zo[1]]
	  p3 = [0, xr2[2], yr2[2], zr_2[2]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr[1] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr[1] = kh / norRoof[3] * norRoof[2] + p2[2]
      
	  # 棟頂点座標の設定
	  xt2 = []
	  yt2 = []
	  xm2 = []
	  ym2 = []
	  zm2 = []
	  xm3 = []
	  ym3 = []
	  zm3 = []
	  xm4 = []
	  ym4 = []
	  zm4 = []
	  # 妻側の中点計算
	  xt2[1] = (xr[1] + xr[4]) / 2
	  yt2[1] = (yr[1] + yr[4]) / 2
	  xt2[2] = (xr[2] + xr[3]) / 2
	  yt2[2] = (yr[2] + yr[3]) / 2
	  # 仮の棟頂点の座標計算
	  xm2[1] = (xt2[1] * 3 + xt2[2] * 2) / 5
	  ym2[1] = (yt2[1] * 3 + yt2[2] * 2) / 5
	  xm2[2] = (xt2[2] * 3 + xt2[1] * 2) / 5
	  ym2[2] = (yt2[2] * 3 + yt2[1] * 2) / 5
	  xm2[3] = (xt2[2] * 3 + xt2[1] * 2) / 5
	  ym2[3] = (yt2[2] * 3 + yt2[1] * 2) / 5
	  xm2[4] = (xt2[1] * 3 + xt2[2] * 2) / 5
	  ym2[4] = (yt2[1] * 3 + yt2[2] * 2) / 5
	  zm2[1] = Math.sqrt((xt2[1] - xm2[1]) ** 2 + (yt2[1] - ym2[1]) ** 2) * incline + (zr[1] + zr[4]) / 2
	  zm2[2] = Math.sqrt((xt2[2] - xm2[2]) ** 2 + (yt2[2] - ym2[2]) ** 2) * incline + (zr[2] + zr[3]) / 2
	  zm2[3] = Math.sqrt((xt2[2] - xm2[2]) ** 2 + (yt2[2] - ym2[2]) ** 2) * incline + (zr[2] + zr[3]) / 2
	  zm2[4] = Math.sqrt((xt2[1] - xm2[1]) ** 2 + (yt2[1] - ym2[1]) ** 2) * incline + (zr[1] + zr[4]) / 2
	  # 棟頂点（破風面下両端）の座標計算
	  xm3[1] = (xm2[1] + xr[1]) / 2
	  ym3[1] = (ym2[1] + yr[1]) / 2
	  xm3[2] = (xm2[2] + xr[2]) / 2
	  ym3[2] = (ym2[2] + yr[2]) / 2
	  xm3[3] = (xm2[3] + xr[3]) / 2
	  ym3[3] = (ym2[3] + yr[3]) / 2
	  xm3[4] = (xm2[4] + xr[4]) / 2
	  ym3[4] = (ym2[4] + yr[4]) / 2
	  zm3[1] = (zm2[1] + zr[1]) / 2
	  zm3[2] = (zm2[2] + zr[2]) / 2
	  zm3[3] = (zm2[3] + zr[3]) / 2
	  zm3[4] = (zm2[4] + zr[4]) / 2
	  # 棟頂点（破風上端）の座標計算
	  xm4[1] = (xm3[1] + xm3[4]) / 2
	  xm4[2] = (xm3[2] + xm3[3]) / 2
	  xm4[3] = (xm3[2] + xm3[3]) / 2
	  xm4[4] = (xm3[1] + xm3[4]) / 2
	  ym4[1] = (ym3[1] + ym3[4]) / 2
	  ym4[2] = (ym3[2] + ym3[3]) / 2
	  ym4[3] = (ym3[2] + ym3[3]) / 2
	  ym4[4] = (ym3[1] + ym3[4]) / 2
	  zm4[1] = (xm4[1] - xm2[2]) * (zm2[1] - zm2[2]) / (xm2[1] - xm2[2]) + zm2[2]
	  zm4[2] = (xm4[2] - xm2[1]) * (zm2[2] - zm2[1]) / (xm2[2] - xm2[1]) + zm2[1]
	  zm4[3] = (xm4[3] - xm2[4]) * (zm2[3] - zm2[4]) / (xm2[3] - xm2[4]) + zm2[4]
	  zm4[4] = (xm4[4] - xm2[3]) * (zm2[4] - zm2[3]) / (xm2[4] - xm2[3]) + zm2[3]
	  
	  # 屋根底面のモデリング
	  pts_b = plate_pts(4, xo, yo, zo)
      face = entities.add_face(pts_b[1], pts_b[2], pts_b[3], pts_b[4])
	  status = face.reverse!
      face.material = "SlateGray"
	  
	  # 屋根寄棟面のモデリング
	  pts_r = plate_pts(4, xr, yr, zr)
	  pts_m = plate_pts(4, xm3, ym3, zm3)
	  face = entities.add_face(pts_r[1], pts_r[2], pts_m[2])
	  face.material = "SlateGray"
	  face = entities.add_face(pts_m[2], pts_m[1], pts_r[1])
	  face.material = "SlateGray"
	  face = entities.add_face(pts_r[3], pts_r[4], pts_m[4])
	  face.material = "SlateGray"
	  face = entities.add_face(pts_m[4], pts_m[3], pts_r[3])
	  face.material = "SlateGray"
	  face = entities.add_face(pts_r[4], pts_r[1], pts_m[1])
	  face.material = "SlateGray"
	  face = entities.add_face(pts_m[1], pts_m[4], pts_r[4])
	  face.material = "SlateGray"
	  face = entities.add_face(pts_r[2], pts_r[3], pts_m[3])
	  face.material = "SlateGray"
	  face = entities.add_face(pts_m[3], pts_m[2], pts_r[2])
	  face.material = "SlateGray"
	  
	  # 屋根切妻面のモデリング
	  pts_r = plate_pts(4, xm3, ym3, zm3)
	  pts_m = plate_pts(4, xm4, ym4, zm4)
      face = entities.add_face(pts_r[1], pts_r[2], pts_m[2])
	  face.material = "SlateGray"
	  face = entities.add_face(pts_m[2], pts_m[1], pts_r[1])
	  face.material = "SlateGray"
	  face = entities.add_face(pts_r[3], pts_r[4], pts_m[4])
	  face.material = "SlateGray"
	  face = entities.add_face(pts_m[4], pts_m[3], pts_r[3])
	  face.material = "SlateGray"
	  face = entities.add_face(pts_r[4], pts_r[1], pts_m[1])
	  face.material = "SlateGray"
	  face = entities.add_face(pts_r[2], pts_r[3], pts_m[3])
	  face.material = "SlateGray"
	  
	  # 屋根側面のモデリング
	  pts_b = plate_pts(4, xo, yo, zo)
	  pts_r = plate_pts(4, xr, yr, zr)
	  face = entities.add_face(pts_b[1], pts_b[2], pts_r[1])
	  status = face.reverse!
      face.material = "SlateGray"
      face = entities.add_face(pts_r[2], pts_r[1], pts_b[2])
	  status = face.reverse!
      face.material = "SlateGray"
	  face = entities.add_face(pts_b[2], pts_b[3], pts_r[2])
	  status = face.reverse!
      face.material = "SlateGray"
      face = entities.add_face(pts_r[3], pts_r[2], pts_b[3])
	  status = face.reverse!
      face.material = "SlateGray"
	  face = entities.add_face(pts_b[3], pts_b[4], pts_r[3])
	  status = face.reverse!
      face.material = "SlateGray"
      face = entities.add_face(pts_r[4], pts_r[3], pts_b[4])
	  status = face.reverse!
      face.material = "SlateGray"
	  face = entities.add_face(pts_b[4], pts_b[1], pts_r[4])
	  status = face.reverse!
      face.material = "SlateGray"
      face = entities.add_face(pts_r[1], pts_r[4], pts_b[1])
	  status = face.reverse!
      face.material = "SlateGray"
	end
	
    # 片流れ屋根の家型のモデリング
	if @input[3] == "片流れ屋根"
	  # 家型の上面頂点Ｚ座標の算出
	  s = []
	  s[1] = Math.sqrt((pts_t[1][0] - pts_t[2][0]) ** 2 + (pts_t[1][1] - pts_t[2][1]) ** 2)
	  s[2] = Math.sqrt((pts_t[2][0] - pts_t[3][0]) ** 2 + (pts_t[2][1] - pts_t[3][1]) ** 2)
	  s[3] = Math.sqrt((pts_t[3][0] - pts_t[4][0]) ** 2 + (pts_t[3][1] - pts_t[4][1]) ** 2)
	  s[4] = Math.sqrt((pts_t[4][0] - pts_t[1][0]) ** 2 + (pts_t[4][1] - pts_t[1][1]) ** 2)
	  
	  # 家型上面の仮の頂点座標を得る
      pts_t2 = []
      pts_t2[1] = vertex[0].position
      pts_t2[2] = vertex[1].position
      pts_t2[3] = vertex[2].position
      pts_t2[4] = vertex[3].position
	  
	  z2 = []
	  yanemuki = @input[6]
	  incline = @input[4].to_f
	  if yanemuki == "回転なし"
	    kata_high = ((incline * s[2]) + (incline * s[4])) / 2
		pts_t2[3][2] = pts_t2[3][2] + kata_high
		pts_t2[4][2] = pts_t2[4][2] + kata_high
	  elsif yanemuki == "左90°回転"
	    kata_high = ((incline * s[3]) + (incline * s[1])) / 2
		pts_t2[4][2] = pts_t2[4][2] + kata_high
		pts_t2[1][2] = pts_t2[1][2] + kata_high
	  elsif yanemuki == "180°回転"
	    kata_high = ((incline * s[4]) + (incline * s[2])) / 2
		pts_t2[1][2] = pts_t2[1][2] + kata_high
		pts_t2[2][2] = pts_t2[2][2] + kata_high
	  elsif yanemuki == "右90°回転"
	    kata_high = ((incline * s[1]) + (incline * s[3])) / 2
		pts_t2[2][2] = pts_t2[2][2] + kata_high
		pts_t2[3][2] = pts_t2[3][2] + kata_high
	  end
	  
	  # 家型上部壁面と屋根裏面のモデリング
	  if yanemuki == "回転なし"
		face = entities.add_face(pts_t[3], pts_t[4], pts_t2[3])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t2[4], pts_t2[3], pts_t[4])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t[2], pts_t[3], pts_t2[3])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t[4], pts_t[1], pts_t2[4])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t[1], pts_t[2], pts_t2[3])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t2[3], pts_t2[4], pts_t[1])
		face.material = youto_d_color(youto_d)
		edge1 = entities.add_line(pts_t[2],pts_t[3])
	    entities.erase_entities edge1
		edge2 = entities.add_line(pts_t[3],pts_t[4])
	    entities.erase_entities edge2
	    edge3 = entities.add_line(pts_t[4],pts_t[1])
	    entities.erase_entities edge3
		edge4 = entities.add_line(pts_t2[3],pts_t[4])
	    entities.erase_entities edge4
	  elsif yanemuki == "左90°回転"
		face = entities.add_face(pts_t[4], pts_t[1], pts_t2[4])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t2[1], pts_t2[4], pts_t[1])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t[1], pts_t[2], pts_t2[1])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t[3], pts_t[4], pts_t2[4])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t[2], pts_t[3], pts_t2[1])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t2[4], pts_t2[1], pts_t[3])
		face.material = youto_d_color(youto_d)
		edge1 = entities.add_line(pts_t[3],pts_t[4])
	    entities.erase_entities edge1
		edge2 = entities.add_line(pts_t[4],pts_t[1])
	    entities.erase_entities edge2
	    edge3 = entities.add_line(pts_t[1],pts_t[2])
	    entities.erase_entities edge3
		edge4 = entities.add_line(pts_t2[4],pts_t[1])
	    entities.erase_entities edge4
	  elsif yanemuki == "180°回転"
		face = entities.add_face(pts_t[1], pts_t[2], pts_t2[1])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t2[2], pts_t2[1], pts_t[2])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t[4], pts_t[1], pts_t2[1])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t[2], pts_t[3], pts_t2[2])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t[3], pts_t[4], pts_t2[1])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t2[1], pts_t2[2], pts_t[3])
		face.material = youto_d_color(youto_d)
		edge1 = entities.add_line(pts_t[4],pts_t[1])
	    entities.erase_entities edge1
		edge2 = entities.add_line(pts_t[1],pts_t[2])
	    entities.erase_entities edge2
	    edge3 = entities.add_line(pts_t[2],pts_t[3])
	    entities.erase_entities edge3
		edge4 = entities.add_line(pts_t2[1],pts_t[2])
	    entities.erase_entities edge4
	  elsif yanemuki == "右90°回転"
		face = entities.add_face(pts_t[2], pts_t[3], pts_t2[2])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t2[3], pts_t2[2], pts_t[3])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t[1], pts_t[2], pts_t2[2])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t[3], pts_t[4], pts_t2[3])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t[4], pts_t[1], pts_t2[3])
		face.material = youto_d_color(youto_d)
		face = entities.add_face(pts_t2[2], pts_t2[3], pts_t[1])
		face.material = youto_d_color(youto_d)
		edge1 = entities.add_line(pts_t[1],pts_t[2])
	    entities.erase_entities edge1
		edge2 = entities.add_line(pts_t[2],pts_t[3])
	    entities.erase_entities edge2
	    edge3 = entities.add_line(pts_t[3],pts_t[4])
	    entities.erase_entities edge3
		edge4 = entities.add_line(pts_t2[2],pts_t[3])
	    entities.erase_entities edge4
	  end
	end
	
    # 片流れ屋根のモデリング
	if @input[3] == "片流れ屋根"
	  # 片流れ屋根底面座標の高さ（Ｚ座標）
	  hisashi = (@input[7].to_f).m_inch
      incline = @input[4].to_f
      mh = hisashi * incline
	  nh = hisashi * incline
	  
	  yanemuki = @input[6]
	  zo = []
	  if yanemuki == "回転なし"
	    zo[3] = pts_t2[3][2] + mh
		zo[4] = pts_t2[4][2] + mh
		zo[1] = pts_t[1][2] - nh
		zo[2] = pts_t[2][2] - nh
	  elsif yanemuki == "左90°回転"
	    zo[4] = pts_t2[4][2] + mh
		zo[1] = pts_t2[1][2] + mh
		zo[2] = pts_t[2][2] - nh
		zo[3] = pts_t[3][2] - nh
	  elsif yanemuki == "180°回転"
	    zo[1] = pts_t2[1][2] + mh
		zo[2] = pts_t2[2][2] + mh
		zo[3] = pts_t[3][2] - nh
		zo[4] = pts_t[4][2] - nh
	  elsif yanemuki == "右90°回転"
	    zo[2] = pts_t2[2][2] + mh
		zo[3] = pts_t2[3][2] + mh
		zo[4] = pts_t[4][2] - nh
		zo[1] = pts_t[1][2] - nh
	  end
	  
	  # yaneatuによる垂直方向の高さ（棟側）
      yaneatu = (@input[9].to_f).m_inch
      rh = yaneatu * Math.sqrt(1 + incline ** 2)
	  # yaneatuによる垂直方向の高さ（軒側）
      yaneatu = (@input[9].to_f).m_inch
      kh = yaneatu / Math.sqrt(1 + incline ** 2)
	  
	  # 片流れ屋根上面座標の計算
	  xr = []
	  yr = []
	  zr = []
	  if yanemuki == "回転なし"
        zr[3] = zo[3] + rh
        zr[4] = zo[4] + rh
        zr[1] = zo[1] + kh
        zr[2] = zo[2] + kh
		p1 = [0, xo[4], yo[4], zr[4]]
	    p2 = [0, xo[1], yo[1], zo[1]]
	    p3 = [0, xo[2], yo[2], zo[2]]
	    norRoof = normal_vector(p1, p2, p3)
		xr[1] = kh / norRoof[3] * norRoof[1] + p2[1]
	    yr[1] = kh / norRoof[3] * norRoof[2] + p2[2]
	    p1 = [0, xo[1], yo[1], zo[1]]
	    p2 = [0, xo[2], yo[2], zo[2]]
	    p3 = [0, xo[3], yo[3], zr[3]]
	    norRoof = normal_vector(p1, p2, p3)
	    xr[2] = kh / norRoof[3] * norRoof[1] + p2[1]
	    yr[2] = kh / norRoof[3] * norRoof[2] + p2[2]
		xr[3] = xo[3]
		yr[3] = yo[3]
		xr[4] = xo[4]
		yr[4] = yo[4]
	  elsif yanemuki == "左90°回転"
        zr[4] = zo[4] + rh
        zr[1] = zo[1] + rh
        zr[2] = zo[2] + kh
        zr[3] = zo[3] + kh
		p1 = [0, xo[1], yo[1], zr[1]]
	    p2 = [0, xo[2], yo[2], zo[2]]
	    p3 = [0, xo[3], yo[3], zo[3]]
	    norRoof = normal_vector(p1, p2, p3)
		xr[2] = kh / norRoof[3] * norRoof[1] + p2[1]
	    yr[2] = kh / norRoof[3] * norRoof[2] + p2[2]
	    p1 = [0, xo[2], yo[2], zo[2]]
	    p2 = [0, xo[3], yo[3], zo[3]]
	    p3 = [0, xo[4], yo[4], zr[4]]
	    norRoof = normal_vector(p1, p2, p3)
	    xr[3] = kh / norRoof[3] * norRoof[1] + p2[1]
	    yr[3] = kh / norRoof[3] * norRoof[2] + p2[2]
		xr[4] = xo[4]
		yr[4] = yo[4]
		xr[1] = xo[1]
		yr[1] = yo[1]
	  elsif yanemuki == "180°回転"
        zr[1] = zo[1] + rh
        zr[2] = zo[2] + rh
        zr[3] = zo[3] + kh
        zr[4] = zo[4] + kh
	    p1 = [0, xo[2], yo[2], zo[2]]
	    p2 = [0, xo[3], yo[3], zo[3]]
	    p3 = [0, xo[4], yo[4], zr[4]]
	    norRoof = normal_vector(p1, p2, p3)
	    xr[3] = kh / norRoof[3] * norRoof[1] + p2[1]
	    yr[3] = kh / norRoof[3] * norRoof[2] + p2[2]
	    p1 = [0, xo[3], yo[3], zo[3]]
	    p2 = [0, xo[4], yo[4], zo[4]]
	    p3 = [0, xo[1], yo[1], zr[1]]
	    norRoof = normal_vector(p1, p2, p3)
	    xr[4] = kh / norRoof[3] * norRoof[1] + p2[1]
	    yr[4] = kh / norRoof[3] * norRoof[2] + p2[2]
		xr[1] = xo[1]
		yr[1] = yo[1]
		xr[2] = xo[2]
		yr[2] = yo[2]
	  elsif yanemuki == "右90°回転"
        zr[2] = zo[2] + rh
        zr[3] = zo[3] + rh
        zr[4] = zo[4] + kh
        zr[1] = zo[1] + kh
	    p1 = [0, xo[3], yo[3], zo[3]]
	    p2 = [0, xo[4], yo[4], zo[4]]
	    p3 = [0, xo[1], yo[1], zr[1]]
	    norRoof = normal_vector(p1, p2, p3)
	    xr[4] = kh / norRoof[3] * norRoof[1] + p2[1]
	    yr[4] = kh / norRoof[3] * norRoof[2] + p2[2]
		p1 = [0, xo[4], yo[4], zr[4]]
	    p2 = [0, xo[1], yo[1], zo[1]]
	    p3 = [0, xo[2], yo[2], zo[2]]
	    norRoof = normal_vector(p1, p2, p3)
		xr[1] = kh / norRoof[3] * norRoof[1] + p2[1]
	    yr[1] = kh / norRoof[3] * norRoof[2] + p2[2]
		xr[2] = xo[2]
		yr[2] = yo[2]
		xr[3] = xo[3]
		yr[3] = yo[3]
	  end

	  # 屋根底面のモデリング
	  pts_b = plate_pts(4, xo, yo, zo)
      face = entities.add_face(pts_b[1], pts_b[2], pts_b[3])
	  status = face.reverse!
      face.material = "SlateGray"
	  face = entities.add_face(pts_b[3], pts_b[4], pts_b[1])
      face.material = "SlateGray"
	  
	  # 屋根上面のモデリング
	  pts_r = plate_pts(4, xr, yr, zr)
      face = entities.add_face(pts_r[1], pts_r[2], pts_r[3])
      face.material = "SlateGray"
	  face = entities.add_face(pts_r[3], pts_r[4], pts_r[1])
      face.material = "SlateGray"
	  
	  # 屋根側面のモデリング
	  pts_b = plate_pts(4, xo, yo, zo)
	  pts_r = plate_pts(4, xr, yr, zr)
	  face = entities.add_face(pts_b[1], pts_b[2], pts_r[1])
      face.material = "SlateGray"
      face = entities.add_face(pts_r[2], pts_r[1], pts_b[2])
      face.material = "SlateGray"
	  face = entities.add_face(pts_b[2], pts_b[3], pts_r[2])
      face.material = "SlateGray"
      face = entities.add_face(pts_r[3], pts_r[2], pts_b[3])
      face.material = "SlateGray"
	  face = entities.add_face(pts_b[3], pts_b[4], pts_r[3])
      face.material = "SlateGray"
      face = entities.add_face(pts_r[4], pts_r[3], pts_b[4])
      face.material = "SlateGray"
	  face = entities.add_face(pts_b[4], pts_b[1], pts_r[4])
      face.material = "SlateGray"
      face = entities.add_face(pts_r[1], pts_r[4], pts_b[1])
      face.material = "SlateGray"
	end
    
    # 町家屋根の家型のモデリング
	if @input[3] == "町家･長屋"
	  # zt値の設定（町屋１階軒高）
	  zt = []
	  zt[1] = pts_t[1][2]
	  zt[2] = pts_t[2][2]
	  zt[3] = pts_t[3][2]
	  zt[4] = pts_t[4][2]
	  
	  # 町家２階モデルの座標設定
	  xbm = []
	  ybm = []
	  zbm = []
	  xtm = []
	  ytm = []
	  ztm = []
	  
	  # 直線S１（頂点１→２）と直線S３（頂点１→２）に平行な直線の式の切片
	  _B2 = Array.new(5){ Array.new(3) }
	  bo2 = []
	  koutai2 = (0.6).m_inch
	  matiya2 = (1.8).m_inch
	  
	  # 直線s１　－仮の切片による切片の差の比較
	  _B2[1][1] = br[1] + koutai2 * Math.sqrt(a[1] ** 2 + 1)
	  _B2[1][2] = br[1] - koutai2 * Math.sqrt(a[1] ** 2 + 1)
	  # 新しい切片の値の設定
	  if _D[1] > (_B2[1][1] - br[3]).abs
	    bo2[1] = b[1] + koutai2 * Math.sqrt(a[1] ** 2 + 1)
	  else
	    bo2[1] = b[1] - koutai2 * Math.sqrt(a[1] ** 2 + 1)
	  end
	  
	  # 直線s3　－仮の切片による切片の差の比較
	  _B2[3][1] = br[3] + koutai2 * Math.sqrt(a[3] ** 2 + 1)
	  _B2[3][2] = br[3] - koutai2 * Math.sqrt(a[3] ** 2 + 1)
	  # 新しい切片の値の設定
	  if _D[3] > (_B2[3][1] - br[1]).abs
	    bo2[3] = b[3] + koutai2 * Math.sqrt(a[3] ** 2 + 1)
	  else
	    bo2[3] = b[3] - koutai2 * Math.sqrt(a[3] ** 2 + 1)
	  end
	  
	  # 直線S２と直線S４はそのまま
	  bo2[2] = b[2]
	  bo2[4] = b[4]
	  
	  # 町家２階モデルの４頂点のX･Y座標の算出
	  for i in  1..4
	    if i == 1
		  xbm[1] = (bo2[1] - bo2[4]) / (a[4] - a[1])
	    else
		  xbm[i] = (bo2[i] - bo2[i-1]) / (a[i-1] - a[i])
	    end
		xtm[i] = xbm[i]
		ybm[i] = xbm[i] * a[i] + bo2[i]
		ytm[i] = ybm[i]
	  end
	  
	  # 町家２階モデルの４頂点のZ座標の算出
	  incline = @input[4].to_f
	  for i in 1..4
	    zbm[i] = zt[i] + koutai2 * incline
		ztm[i] = zt[i] + matiya2
	  end
	  
	  # 町家２階上面（小屋伏せ）用の座標設定
	  xm = []
	  ym = []
	  zm = []
	  xm[1] = xtm[1]
	  xm[2] = xtm[2]
	  xm[5] = xtm[3]
	  xm[6] = xtm[4]
	  xm[3] = (xm[1] + xm[6]) / 2
	  xm[4] = (xm[2] + xm[5]) / 2
	  xm[7] = (xm[2] + xm[5]) / 2
	  xm[8] = (xm[1] + xm[6]) / 2
	  ym[1] = ytm[1]
	  ym[2] = ytm[2]
	  ym[5] = ytm[3]
	  ym[6] = ytm[4]
	  ym[3] = (ym[1] + ym[6]) / 2
	  ym[4] = (ym[2] + ym[5]) / 2
	  ym[7] = (ym[2] + ym[5]) / 2
	  ym[8] = (ym[1] + ym[6]) / 2
	  zm[1] = ztm[1]
	  zm[2] = ztm[2]
	  zm[5] = ztm[3]
	  zm[6] = ztm[4]
	  
	  # ２階妻側頂点の高さ（Z座標）の計算
	  l_s2 = Math.sqrt((xm[2] - xm[5]) ** 2 + (ym[2] - ym[5]) ** 2)
	  l_s4 = Math.sqrt((xm[1] - xm[6]) ** 2 + (ym[1] - ym[6]) ** 2)
	  zm[3] = (l_s4 / 2 * incline) + ((zm[1] + zm[6]) / 2)
	  zm[4] = (l_s2 / 2 * incline) + ((zm[2] + zm[5]) / 2)
	  zm[7] = (l_s2 / 2 * incline) + ((zm[2] + zm[5]) / 2)
	  zm[8] = (l_s4 / 2 * incline) + ((zm[1] + zm[6]) / 2)
	  
	  # 町家１階上面（天井伏せ）用の座標設定
	  xk = []
	  yk = []
	  zk = []
	  xk[1] = pts_t[1][0]
	  xk[2] = pts_t[2][0]
	  xk[5] = pts_t[3][0]
	  xk[6] = pts_t[4][0]
	  xk[3] = xm[6]
	  xk[4] = xm[5]
	  xk[7] = xm[2]
	  xk[8] = xm[1]
	  yk[1] = pts_t[1][1]
	  yk[2] = pts_t[2][1]
	  yk[5] = pts_t[3][1]
	  yk[6] = pts_t[4][1]
	  yk[3] = ym[6]
	  yk[4] = ym[5]
	  yk[7] = ym[2]
	  yk[8] = ym[1]
	  zk[1] = zt[1]
	  zk[2] = zt[2]
	  zk[5] = zt[3]
	  zk[6] = zt[4]
	  zk[3] = zbm[4]
	  zk[4] = zbm[3]
	  zk[7] = zbm[2]
	  zk[8] = zbm[1]
	  
	  # １階家型壁面と天井面のモデリング
	  pts_k = plate_pts(8, xk, yk, zk)
	  
	  face = entities.add_face(pts_k[1], pts_k[2], pts_k[7])
      face.material = youto_d_color(youto_d)
	  face = entities.add_face(pts_k[7], pts_k[8], pts_k[1])
      face.material = youto_d_color(youto_d)
	  face = entities.add_face(pts_k[3], pts_k[4], pts_k[5])
      face.material = youto_d_color(youto_d)
	  face = entities.add_face(pts_k[5], pts_k[6], pts_k[3])
      face.material = youto_d_color(youto_d)
	  face = entities.add_face(pts_k[8], pts_k[7], pts_k[4])
      face.material = youto_d_color(youto_d)
	  face = entities.add_face(pts_k[4], pts_k[3], pts_k[8])
      face.material = youto_d_color(youto_d)
	  face = entities.add_face(pts_k[1], pts_k[8], pts_k[3], pts_k[6])
      face.material = youto_d_color(youto_d)
	  face = entities.add_face(pts_k[5], pts_k[4], pts_k[7], pts_k[2])
      face.material = youto_d_color(youto_d)
	  
	  edge1 = entities.add_line(pts_k[1],pts_k[7])
	  entities.erase_entities edge1
	  edge2 = entities.add_line(pts_k[5],pts_k[3])
	  entities.erase_entities edge2
	  edge3 = entities.add_line(pts_k[6],pts_k[1])
	  entities.erase_entities edge3
	  edge4 = entities.add_line(pts_k[2],pts_k[5])
	  entities.erase_entities edge4
	  edge5 = entities.add_line(pts_k[4],pts_k[8])
	  entities.erase_entities edge5
	  
	  # ２階家型のモデリング
	  pts_m = plate_pts(8, xm, ym, zm)
	  face = entities.add_face(pts_m[1], pts_m[2], pts_m[4])
      face.material = youto_d_color(youto_d)
	  face = entities.add_face(pts_m[4], pts_m[3], pts_m[1])
      face.material = youto_d_color(youto_d)
	  face = entities.add_face(pts_m[5], pts_m[6], pts_m[8])
      face.material = youto_d_color(youto_d)
	  face = entities.add_face(pts_m[8], pts_m[7], pts_m[5])
      face.material = youto_d_color(youto_d)
	  face = entities.add_face(pts_k[8], pts_k[7], pts_m[2], pts_m[1])
      face.material = youto_d_color(youto_d)
	  face = entities.add_face(pts_k[4], pts_k[3], pts_m[6], pts_m[5])
      face.material = youto_d_color(youto_d)
	  face = entities.add_face(pts_k[3], pts_k[8], pts_m[1], pts_m[3], pts_m[6])
      face.material = youto_d_color(youto_d)
	  face = entities.add_face(pts_k[7], pts_k[4], pts_m[5], pts_m[4], pts_m[2])
      face.material = youto_d_color(youto_d)
	end
	
    # 町家屋根のモデリング
	if @input[3] == "町家･長屋"
	  # ２階屋根の頂点座標の設定
	  xo1 = []
	  yo1 = []
	  zo1 = []
	  xo2 = []
	  yo2 = []
	  zo2 = []
	  xr1 = []
	  yr1 = []
	  zr1 = []
	  xr2 = []
	  yr2 = []
	  zr2 = []
	  
	  # ２階屋根軒下下端の高さ
	  hisashi = (@input[7].to_f).m_inch
	  # incline = @input[4].to_f
	  nh = hisashi * incline
	  
	  matiya2 = (1.8).m_inch
	  zo1[1] = zt[1] + matiya2 - nh
	  zo1[2] = zt[2] + matiya2 - nh
	  zo2[1] = zt[3] + matiya2 - nh
	  zo2[2] = zt[4] + matiya2 - nh
	  
	  # yaneatuによる垂直方向の高さ（軒側）
	  yaneatu = (@input[9].to_f).m_inch
	  kh = yaneatu / Math.sqrt(1 + incline ** 2)
	  # yaneatuによる垂直方向の高さ（棟側）
	  rh = yaneatu * Math.sqrt(1 + incline ** 2)
	  
	  # ２階屋根軒上端の高さ
	  zr1[1] = zo1[1] + kh
	  zr1[2] = zo1[2] + kh
	  zr2[1] = zo2[1] + kh
	  zr2[2] = zo2[2] + kh
	  
	  # ２階屋根棟頂点高さの計算
	  zo1[3] = zm[7]
	  zo1[4] = zm[8]
	  zo2[3] = zm[3]
	  zo2[4] = zm[4]
	  zr1[3] = zo1[3] + rh
	  zr1[4] = zo1[4] + rh
	  zr2[3] = zo2[3] + rh
	  zr2[4] = zo2[4] + rh
	  
	  # ２階の壁面線に平行な直線の式の切片
	  _Bm = Array.new(5){ Array.new(3) }
	  bom = []
	  _Bm2 = Array.new(5){ Array.new(3) }
	  bom2 = []
	  
	  for i in 1..4
	    if i == 1 || i == 3
		  # 仮の切片による切片の差の比較（２階屋根用）
		  _Bm2[i][1] = br[i] + (koutai2 - d[i-1]) * Math.sqrt(a[i] ** 2 + 1)
		  _Bm2[i][2] = br[i] - (koutai2 - d[i-1]) * Math.sqrt(a[i] ** 2 + 1)
		  # 新しい切片の値の設定
		  if i == 1
		    if _D[i] > (_Bm2[i][1] - br[i + 2]).abs
			  bom2[i] = b[i] + (koutai2 - d[i-1]) * Math.sqrt(a[i] ** 2 + 1)
			elsif
			  bom2[i] = b[i] - (koutai2 - d[i-1]) * Math.sqrt(a[i] ** 2 + 1)
			end
		  end
		  if i == 3
		    if _D[i] > (_Bm2[i][1] - br[i - 2]).abs
			  bom2[i] = b[i] + (koutai2 - d[i-1]) * Math.sqrt(a[i] ** 2 + 1)
			elsif
			  bom2[i] = b[i] - (koutai2 - d[i-1]) * Math.sqrt(a[i] ** 2 + 1)
			end
		  end
		  
		  # 仮の切片による切片の差の比較（１階軒庇用）
		  _Bm[i][1] = br[i] + koutai2 * Math.sqrt(a[i] ** 2 + 1)
		  _Bm[i][2] = br[i] - koutai2 * Math.sqrt(a[i] ** 2 + 1)
		  # 新しい切片の値の設定
		  if i == 1
		    if _D[i] > (_Bm[i][1] - br[i + 2]).abs
			  bom[i] = b[i] + koutai2 * Math.sqrt(a[i] ** 2 + 1)
			elsif
			  bom[i] = b[i] - koutai2 * Math.sqrt(a[i] ** 2 + 1)
			end
		  end
		  if i == 3
		    if _D[i] > (_Bm[i][1] - br[i - 2]).abs
			  bom[i] = b[i] + koutai2 * Math.sqrt(a[i] ** 2 + 1)
			elsif
			  bom[i] = b[i] - koutai2 * Math.sqrt(a[i] ** 2 + 1)
			end
		  end
		end
		
		if i == 2 || i == 4
		  # 仮の切片による切片の差の比較（２階屋根用）
		  _Bm2[i][1] = br[i] + d[i-1] * Math.sqrt(a[i] ** 2 + 1)
		  _Bm2[i][2] = br[i] - d[i-1] * Math.sqrt(a[i] ** 2 + 1)
		  # 新しい切片の値の設定
		  if i == 2
		    if _D[i] < (_Bm2[i][1] - br[i + 2]).abs
			  bom2[i] = b[i] + d[i-1] * Math.sqrt(a[i] ** 2 + 1)
			elsif
			  bom2[i] = b[i] - d[i-1] * Math.sqrt(a[i] ** 2 + 1)
			end
		  end
		  if i == 4
		    if _D[i] < (_Bm2[i][1] - br[i - 2]).abs
			  bom2[i] = b[i] + d[i-1] * Math.sqrt(a[i] ** 2 + 1)
			elsif
			  bom2[i] = b[i] - d[i-1] * Math.sqrt(a[i] ** 2 + 1)
			end
		  end
		end
	  end
	  
	  # ２階屋根４頂点のX・Y座標の算出
	  for i in 1..4
	    if i == 1
		  xo1[1] = (bom2[1] - bom2[4]) / (a[4] - a[1])
		  yo1[1] = xo1[1] * a[1] + bom2[1]
		elsif i == 2
		  xo1[2] = (bom2[2] - bom2[1]) / (a[1] - a[2])
		  yo1[2] = xo1[2] * a[2] + bom2[2]
		elsif i == 3
		  xo2[1] = (bom2[3] - bom2[2]) / (a[2] - a[3])
		  yo2[1] = xo2[1] * a[3] + bom2[3]
		elsif i == 4
		  xo2[2] = (bom2[4] - bom2[3]) / (a[3] - a[4])
		  yo2[2] = xo2[2] * a[4] + bom2[4]
		end
	  end
	  
	  # 軒頂点下端座標の計算
	  xo1[3] = (xo1[2] + xo2[1]) / 2
	  yo1[3] = (yo1[2] + yo2[1]) / 2
	  xo1[4] = (xo1[1] + xo2[2]) / 2
	  yo1[4] = (yo1[1] + yo2[2]) / 2
	  xo2[3] = (xo1[1] + xo2[2]) / 2
	  yo2[3] = (yo1[1] + yo2[2]) / 2
	  xo2[4] = (xo1[2] + xo2[1]) / 2
	  yo2[4] = (yo1[2] + yo2[1]) / 2
	  
	  # ２階屋根軒上端座標の計算
	  p1 = [0, xo1[4], yo1[4], zo1[4]]
	  p2 = [0, xo1[1], yo1[1], zo1[1]]
	  p3 = [0, xo1[2], yo1[2], zo1[2]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr1[1] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr1[1] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xo1[1], yo1[1], zo1[1]]
	  p2 = [0, xo1[2], yo1[2], zo1[2]]
	  p3 = [0, xo1[3], yo1[3], zo1[3]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr1[2] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr1[2] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xo2[4], yo2[4], zo2[4]]
	  p2 = [0, xo2[1], yo2[1], zo2[1]]
	  p3 = [0, xo2[2], yo2[2], zo2[2]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr2[1] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr2[1] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xo2[1], yo2[1], zo2[1]]
	  p2 = [0, xo2[2], yo2[2], zo2[2]]
	  p3 = [0, xo2[3], yo2[3], zo2[3]]
	  norRoof = normal_vector(p1, p2, p3)
	  xr2[2] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yr2[2] = kh / norRoof[3] * norRoof[2] + p2[2]
	  
	  # 棟頂点上端座標の計算
	  xr1[3] = (xr1[2] + xr2[1]) / 2
	  yr1[3] = (yr1[2] + yr2[1]) / 2
	  xr1[4] = (xr1[1] + xr2[2]) / 2
	  yr1[4] = (yr1[1] + yr2[2]) / 2
	  xr2[3] = (xr1[1] + xr2[2]) / 2
	  yr2[3] = (yr1[1] + yr2[2]) / 2
	  xr2[4] = (xr1[2] + xr2[1]) / 2
	  yr2[4] = (yr1[2] + yr2[1]) / 2
	  
	  # １階軒庇の頂点座標の設定
	  xu1 = []
	  yu1 = []
	  zu1 = []
	  xu2 = []
	  yu2 = []
	  zu2 = []
	  xn1 = []
	  yn1 = []
	  zn1 = []
	  xn2 = []
	  yn2 = []
	  zn2 = []
	  
	  # １階軒庇下端の頂点座標
	  xu1[1] = xo[1]
	  yu1[1] = yo[1]
	  xu1[2] = xo[2]
	  yu1[2] = yo[2]
	  xu2[1] = xo[3]
	  yu2[1] = yo[3]
	  xu2[2] = xo[4]
	  yu2[2] = yo[4]
	  zu1[1] = zt[1] - hisashi * incline
	  zu1[2] = zt[2] - hisashi * incline
	  zu2[1] = zt[3] - hisashi * incline
	  zu2[2] = zt[4] - hisashi * incline
	  
	  # １階軒庇壁面側下端の頂点座標
	  for i in 1..4
	    if i == 1
		  xu1[4] = (bom[1] - bo[4]) / (a[4] - a[1])
		  yu1[4] = xu1[4] * a[1] + bom[1]
		elsif i == 2
		  xu1[3] = (bo[2] - bom[1]) / (a[1] - a[2])
		  yu1[3] = xu1[3] * a[2] + bo[2]
		elsif i == 3
		  xu2[4] = (bom[3] - bo[2]) / (a[2] - a[3])
		  yu2[4] = xu2[4] * a[3] + bom[3]
		elsif i == 4
		  xu2[3] = (bo[4] - bom[3]) / (a[3] - a[4])
		  yu2[3] = xu2[3] * a[4] + bo[4]
		end
	  end
	  
	  zu1[4] = zt[1] + koutai2 * incline
	  zu1[3] = zt[2] + koutai2 * incline
	  zu2[4] = zt[3] + koutai2 * incline
	  zu2[3] = zt[4] + koutai2 * incline
	  
	  # １階軒庇上端座標の計算
	  p1 = [0, xu1[4], yu1[4], zu1[4]]
	  p2 = [0, xu1[1], yu1[1], zu1[1]]
	  p3 = [0, xu1[2], yu1[2], zu1[2]]
	  norRoof = normal_vector(p1, p2, p3)
	  xn1[1] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yn1[1] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xu1[1], yu1[1], zu1[1]]
	  p2 = [0, xu1[2], yu1[2], zu1[2]]
	  p3 = [0, xu1[3], yu1[3], zu1[3]]
	  norRoof = normal_vector(p1, p2, p3)
	  xn1[2] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yn1[2] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xu2[4], yu2[4], zu2[4]]
	  p2 = [0, xu2[1], yu2[1], zu2[1]]
	  p3 = [0, xu2[2], yu2[2], zu2[2]]
	  norRoof = normal_vector(p1, p2, p3)
	  xn2[1] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yn2[1] = kh / norRoof[3] * norRoof[2] + p2[2]
	  p1 = [0, xu2[1], yu2[1], zu2[1]]
	  p2 = [0, xu2[2], yu2[2], zu2[2]]
	  p3 = [0, xu2[3], yu2[3], zu2[3]]
	  norRoof = normal_vector(p1, p2, p3)
	  xn2[2] = kh / norRoof[3] * norRoof[1] + p2[1]
	  yn2[2] = kh / norRoof[3] * norRoof[2] + p2[2]
	  
	  zn1[1] = zu1[1] + kh
	  zn1[2] = zu1[2] + kh
	  zn2[1] = zu2[1] + kh
	  zn2[2] = zu2[2] + kh
	  
	  # １階軒庇壁面側上端の頂点座標
	  xn1[3] = xu1[3]
	  yn1[3] = yu1[3]
	  xn1[4] = xu1[4]
	  yn1[4] = yu1[4]
	  xn2[3] = xu2[3]
	  yn2[3] = yu2[3]
	  xn2[4] = xu2[4]
	  yn2[4] = yu2[4]
	  zn1[3] = zu1[3] + rh
	  zn1[4] = zu1[4] + rh
	  zn2[3] = zu2[3] + rh
	  zn2[4] = zu2[4] + rh
	  
	  # ２階屋根底面のモデリング
	  pts_b = plate_pts(4, xo1, yo1, zo1)
      face = entities.add_face(pts_b[1], pts_b[2], pts_b[3])
	  status = face.reverse!
      face.material = "SlateGray"
	  face = entities.add_face(pts_b[3], pts_b[4], pts_b[1])
      face.material = "SlateGray"
	  pts_b = plate_pts(4, xo2, yo2, zo2)
      face = entities.add_face(pts_b[1], pts_b[2], pts_b[3])
	  status = face.reverse!
      face.material = "SlateGray"
	  face = entities.add_face(pts_b[3], pts_b[4], pts_b[1])
      face.material = "SlateGray"
	  
	  # ２階屋根上面のモデリング
	  pts_r = plate_pts(4, xr1, yr1, zr1)
      face = entities.add_face(pts_r[1], pts_r[2], pts_r[3])
      face.material = "SlateGray"
	  face = entities.add_face(pts_r[3], pts_r[4], pts_r[1])
      face.material = "SlateGray"
	  pts_r = plate_pts(4, xr2, yr2, zr2)
      face = entities.add_face(pts_r[1], pts_r[2], pts_r[3])
      face.material = "SlateGray"
	  face = entities.add_face(pts_r[3], pts_r[4], pts_r[1])
      face.material = "SlateGray"
	  
	  # 屋根側面のモデリング
	  pts_b = plate_pts(4, xo1, yo1, zo1)
	  pts_r = plate_pts(4, xr1, yr1, zr1)
	  face = entities.add_face(pts_b[1], pts_b[2], pts_r[1])
      face.material = "SlateGray"
      face = entities.add_face(pts_r[2], pts_r[1], pts_b[2])
      face.material = "SlateGray"
      face = entities.add_face(pts_b[2], pts_b[3], pts_r[3])
      face.material = "SlateGray"
      face = entities.add_face(pts_r[3], pts_r[2], pts_b[2])
      face.material = "SlateGray"
      face = entities.add_face(pts_b[4], pts_b[1], pts_r[4])
      face.material = "SlateGray"
      face = entities.add_face(pts_r[1], pts_r[4], pts_b[1])
      face.material = "SlateGray"
	  
	  pts_b = plate_pts(4, xo2, yo2, zo2)
	  pts_r = plate_pts(4, xr2, yr2, zr2)
	  face = entities.add_face(pts_b[1], pts_b[2], pts_r[1])
      face.material = "SlateGray"
      face = entities.add_face(pts_r[2], pts_r[1], pts_b[2])
      face.material = "SlateGray"
      face = entities.add_face(pts_b[2], pts_b[3], pts_r[3])
      face.material = "SlateGray"
      face = entities.add_face(pts_r[3], pts_r[2], pts_b[2])
      face.material = "SlateGray"
      face = entities.add_face(pts_b[4], pts_b[1], pts_r[4])
      face.material = "SlateGray"
      face = entities.add_face(pts_r[1], pts_r[4], pts_b[1])
      face.material = "SlateGray"
	  
	  # １階軒庇底面のモデリング
	  pts_b = plate_pts(4, xu1, yu1, zu1)
      face = entities.add_face(pts_b[1], pts_b[2], pts_b[3])
	  status = face.reverse!
      face.material = "SlateGray"
	  face = entities.add_face(pts_b[3], pts_b[4], pts_b[1])
      face.material = "SlateGray"
	  pts_b = plate_pts(4, xu2, yu2, zu2)
      face = entities.add_face(pts_b[1], pts_b[2], pts_b[3])
	  status = face.reverse!
      face.material = "SlateGray"
	  face = entities.add_face(pts_b[3], pts_b[4], pts_b[1])
      face.material = "SlateGray"
	  
	  # １階軒庇上面のモデリング
	  pts_r = plate_pts(4, xn1, yn1, zn1)
      face = entities.add_face(pts_r[1], pts_r[2], pts_r[3])
	  # status = face.reverse!
      face.material = "SlateGray"
	  face = entities.add_face(pts_r[3], pts_r[4], pts_r[1])
      face.material = "SlateGray"
	  pts_r = plate_pts(4, xn2, yn2, zn2)
      face = entities.add_face(pts_r[1], pts_r[2], pts_r[3])
	  # status = face.reverse!
      face.material = "SlateGray"
	  face = entities.add_face(pts_r[3], pts_r[4], pts_r[1])
      face.material = "SlateGray"
	  
	  # １階軒庇側面のモデリング
	  pts_b = plate_pts(4, xu1, yu1, zu1)
	  pts_r = plate_pts(4, xn1, yn1, zn1)
	  face = entities.add_face(pts_b[1], pts_b[2], pts_r[1])
      face.material = "SlateGray"
      face = entities.add_face(pts_r[2], pts_r[1], pts_b[2])
      face.material = "SlateGray"
      face = entities.add_face(pts_b[2], pts_b[3], pts_r[3])
      face.material = "SlateGray"
      face = entities.add_face(pts_r[3], pts_r[2], pts_b[2])
      face.material = "SlateGray"
      face = entities.add_face(pts_b[4], pts_b[1], pts_r[4])
      face.material = "SlateGray"
      face = entities.add_face(pts_r[1], pts_r[4], pts_b[1])
      face.material = "SlateGray"
	  
	  pts_b = plate_pts(4, xu2, yu2, zu2)
	  pts_r = plate_pts(4, xn2, yn2, zn2)
	  face = entities.add_face(pts_b[1], pts_b[2], pts_r[1])
      face.material = "SlateGray"
      face = entities.add_face(pts_r[2], pts_r[1], pts_b[2])
      face.material = "SlateGray"
      face = entities.add_face(pts_b[2], pts_b[3], pts_r[3])
      face.material = "SlateGray"
      face = entities.add_face(pts_r[3], pts_r[2], pts_b[2])
      face.material = "SlateGray"
      face = entities.add_face(pts_b[4], pts_b[1], pts_r[4])
      face.material = "SlateGray"
      face = entities.add_face(pts_r[1], pts_r[4], pts_b[1])
      face.material = "SlateGray"
	end
  end
}
