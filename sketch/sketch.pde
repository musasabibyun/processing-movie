import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioPlayer player;
FFT fft;

int numCircles = 5;
float[] circleRotX;
float[] circleRotY;
float[] circleRotZ;
float[] rotationX;
float[] rotationY;
float[] rotationZ;
float[] circleSize;
boolean musicStarted = false;
int startDelay = 2500;
int startTime;
int maxCircleSize = 600;

// 背景フェード関連
int backgroundChangeInterval = 5000;
int lastBackgroundChangeTime = 0;
float fadeAmount = 0;
boolean fading = false; // フェード中かどうか

// 背景回転速度（度/フレーム）
float ROTATION_SPEED = 0.05;

// 1:52のタイムスタンプ（ミリ秒）
int ANIMATION_CHANGE_TIME = 112000; // 1:52 = 112秒
// int ANIMATION_CHANGE_TIME = 10000;

boolean animationChanged = false; // アニメーション変更フラグ

// 市松模様の点滅効果用
boolean checkerboardFlashing = false;
int flashStartTime = 0;
// 点滅パターンの設定
float flashFrequency = 0.05; // 基本の点滅確率（0-1）
float flashPulseSpeed = 0.05; // 点滅の脈動速度（値が大きいほど速く点滅）

// 色の定数
color BLUE_COLOR = color(17, 88, 122);
color BLACK_COLOR = color(0, 0, 0);
color RED_COLOR = color(255, 0, 0);
color PINK_COLOR = color(225, 174, 199);

// 背景形状の色
color BG_RED_COLOR = color(220, 50, 50);
color BG_PINK_COLOR = color(255, 182, 193);
color BG_SHADOW_COLOR = color(50, 50, 50);

// 市松模様の色
color CHECKER_WHITE = color(255, 255, 255);
color CHECKER_GRAY = color(220, 220, 220);

// 中央円のグラデーション色
color CENTER_RED_COLOR = color(213, 33, 17);
color CENTER_PINK_COLOR = color(228, 173, 224);

// 背景用のPGraphicsオブジェクト
PGraphics bg1, bg2;
boolean useFirstBackground = true;

// 回転可能な背景クラス
RotatingBackground background1;
RotatingBackground background2;
float time = 0; // アニメーション用の時間変数

// 中央に向かう形状の速度範囲
float MIN_ABSORB_SPEED = 1.5;
float MAX_ABSORB_SPEED = 10.0;

// 背景形状の数
int DEFAULT_SHAPE_COUNT = 20;  // アニメーション変更前の形状数
int INCREASED_SHAPE_COUNT = 50; // アニメーション変更後の形状数

void setup() {
  size(1920, 1080, P3D);
  frameRate(30);
  
  minim = new Minim(this);
  player = minim.loadFile("../error.wav");
  player.play();
  startTime = millis();

  fft = new FFT(player.bufferSize(), player.sampleRate());
  fft.logAverages(22, 3);

  circleRotX = new float[numCircles];
  circleRotY = new float[numCircles];
  circleRotZ = new float[numCircles];
  rotationX = new float[numCircles];
  rotationY = new float[numCircles];
  rotationZ = new float[numCircles];
  circleSize = new float[numCircles];

  for (int i = 0; i < numCircles; i++) {
    circleRotX[i] = 0;
    circleRotY[i] = 0;
    circleRotZ[i] = 0;
    rotationX[i] = 0;
    rotationY[i] = 0;
    rotationZ[i] = 0;
    circleSize[i] = 300;
  }

  // 背景オブジェクトの初期化
  background1 = new RotatingBackground(width, height);
  background2 = new RotatingBackground(width, height);
  
  // 背景生成
  bg1 = createGraphics(width, height, P3D);
  bg2 = createGraphics(width, height, P3D);
}

void draw() {
  background(255);
  
  // 現在の経過時間を計算
  int currentTime = millis() - startTime;
  
  // 時間を更新
  time += 0.01;
  
  // 市松模様の波打つ背景を描画
  drawWavyCheckerboard();
  
  // 1:52以降のアニメーション変更
  if (currentTime >= ANIMATION_CHANGE_TIME && !animationChanged) {
    // アニメーション変更時の初期化
    animationChanged = true;
    
    // 点滅効果を開始
    checkerboardFlashing = true;
    flashStartTime = currentTime;
    
    // 形状数を増やした中央に向かうアニメーション用の新しい背景を準備
    background1 = new CenterFlowBackground(width, height, INCREASED_SHAPE_COUNT);
    background2 = new CenterFlowBackground(width, height, INCREASED_SHAPE_COUNT);
    
    // 背景を強制的に初期化
    for (BackgroundShape shape : background1.shapes) {
      shape.updateVerticesSize();
    }
    for (BackgroundShape shape : background2.shapes) {
      shape.updateVerticesSize();
    }
  }
  
  // 背景の更新
  background1.update();
  background2.update();
  
  // 背景を描画
  if (animationChanged) {
    // 1:52以降は新しいアニメーション
    background1.draw(bg1);
    image(bg1, 0, 0);
  } else {
    // 元のアニメーション（1:52まで）
    background1.draw(bg1);
    background2.draw(bg2);
    
    int elapsedTime = millis() - lastBackgroundChangeTime;

    if (!fading && elapsedTime > backgroundChangeInterval) {
      fading = true; // フェード開始
      lastBackgroundChangeTime = millis(); // 時間をリセット
      
      // バックグラウンドの切り替え時に新しい方を再生成
      if (useFirstBackground) {
        background2 = new RotatingBackground(width, height);
      } else {
        background1 = new RotatingBackground(width, height);
      }
    }

    // フェードが進行する
    if (fading) {
      float fadeProgress = map(elapsedTime, 0, backgroundChangeInterval, 0, 1);
      fadeAmount = constrain(fadeProgress, 0, 1);

      if (fadeAmount >= 1) {
        // フェードが終わったら背景を切り替え
        useFirstBackground = !useFirstBackground;
        fading = false; // フェード終了
      }
    }

    // 透明度を適用しながら2つの背景を描画
    tint(255, 255 * (1 - fadeAmount));
    image(useFirstBackground ? bg1 : bg2, 0, 0);
    
    tint(255, 255 * fadeAmount);
    image(useFirstBackground ? bg2 : bg1, 0, 0);
  }

  // 中央のオーディオビジュアライザー
  translate(width / 2, height / 2, maxCircleSize);
  scale(0.5);
  noStroke();
  
  fft.forward(player.mix);

  if (!musicStarted && millis() - startTime > startDelay) {
    musicStarted = true;
    for (int i = 0; i < numCircles; i++) {
      circleRotX[i] = random(TWO_PI);
      circleRotY[i] = random(TWO_PI);
      circleRotZ[i] = random(TWO_PI);
    }
  }
  
  if (musicStarted) {
    fill(lerpColor(CENTER_RED_COLOR, CENTER_PINK_COLOR, map(fft.getBand(0), 0, 50, 0, 1)));
    ellipse(0, 0, map(fft.getBand(0), 0, 50, 100, 400), map(fft.getBand(0), 0, 50, 100, 400));
  }
  
  noFill();
  strokeWeight(2);

  for (int i = 0; i < numCircles; i++) {
    if (musicStarted) {
      rotationX[i] += fft.getAvg(i % fft.specSize()) * 0.01;
      rotationY[i] += fft.getAvg((i + 1) % fft.specSize()) * 0.01;
      rotationZ[i] += fft.getAvg((i + 2) % fft.specSize()) * 0.01;
    }
    circleSize[i] = map(fft.getBand(i % fft.specSize()), 0, 50, 200, maxCircleSize);

    pushMatrix();
    rotateX(circleRotX[0] + rotationX[i]);
    rotateY(circleRotY[0] + rotationY[i]);
    rotateZ(circleRotZ[0] + rotationZ[i]);
    
    float colorProb = random(1);
    if (colorProb < 0.05) {
      stroke(BLACK_COLOR); // 黒色
    } else if (colorProb < 0.15) {
      stroke(RED_COLOR); // 赤色
    } else if (colorProb < 0.25) {
      stroke(BLUE_COLOR); // 青
    } else {
      stroke(PINK_COLOR); // ピンク色 (75%)
    }
    
    strokeWeight(random(1, 12));
    ellipse(0, 0, circleSize[i], circleSize[i]);
    popMatrix();
  }
  
  // saveFrame("../frames/######.tga");
}

// 波打つ市松模様の背景を描画する関数
void drawWavyCheckerboard() {
  int cellSize = 80; // 市松模様の1マスのサイズ
  
  // 市松模様のマスを描画
  noStroke();
  for (int x = 0; x < width; x += cellSize) {
    for (int y = 0; y < height; y += cellSize) {
      // 中心からの距離を計算
      float distX = x - width/2;
      float distY = y - height/2;
      float dist = sqrt(distX*distX + distY*distY);
      
      // 同心円状の波を作成（時間とともに外側に広がる）
      float wavePhase = dist * 0.05 - time * 2;
      float waveAmplitude = 8.0;
      float wave = sin(wavePhase) * waveAmplitude;
      
      // 中心からの方向に基づいて波の効果を適用
      float angle = atan2(distY, distX);
      float posX = x + cos(angle) * wave;
      float posY = y + sin(angle) * wave;
      
      // 点滅効果が有効な場合、ランダムに青色のマスを表示
      boolean isFlashing = false;
      if (checkerboardFlashing) {
        // 時間に基づく波のような点滅パターンを生成（脈動効果）
        float timeFactor = (millis() - startTime - flashStartTime) * 0.001; // 秒単位
        
        // sin関数を使って脈動効果を作成（0.2〜0.6の範囲で点滅確率が変動）
        float pulseEffect = sin(timeFactor * flashPulseSpeed) * 0.5 + 0.5; // 0〜1の範囲
        float currentFlashFreq = flashFrequency * (0.4 + pulseEffect * 0.6); // 基本値の40%〜100%
        
        // セルごとにランダムな確率で点滅（位置によって確率を変える）
        float distFactor = 1.0 - (dist(x, y, width/2, height/2) / (width * 0.7));
        distFactor = constrain(distFactor, 0, 1);
        
        // 中心に近いほど点滅しやすくする
        isFlashing = random(1) < (currentFlashFreq * (0.5 + distFactor * 0.5));
      }
      
      // 色を選択
      if (isFlashing) {
        // 点滅時は青色
        fill(BLUE_COLOR);
      } else {
        // 通常の市松模様
        if ((int)(x/cellSize + y/cellSize) % 2 == 0) {
          fill(CHECKER_WHITE);
        } else {
          fill(CHECKER_GRAY);
        }
      }
      
      // マスを描画
      rect(posX, posY, cellSize, cellSize);
    }
  }
}

// RotatingBackgroundクラスを修正して、形状数を指定できるようにする
class RotatingBackground {
  int numShapes = DEFAULT_SHAPE_COUNT; // デフォルトの形状数
  BackgroundShape[] shapes;
  
  // 形状数を指定せずにコンストラクタを呼ぶとデフォルト値を使用
  RotatingBackground(int w, int h) {
    this(w, h, DEFAULT_SHAPE_COUNT); // 定数を使用
  }
  
  // 形状数を指定できるコンストラクタを追加
  RotatingBackground(int w, int h, int shapeCount) {
    numShapes = shapeCount;
    shapes = new BackgroundShape[numShapes];
    for (int i = 0; i < numShapes; i++) {
      shapes[i] = createShape(w, h);
    }
  }
  
  // サブクラスでオーバーライド可能な形状生成メソッド
  BackgroundShape createShape(int w, int h) {
    return new BackgroundShape(w, h);
  }
  
  void update() {
    for (BackgroundShape shape : shapes) {
      shape.update(); // 各形状が独自の回転を更新
    }
  }
  
  void draw(PGraphics pg) {
    pg.beginDraw();
    pg.background(255, 200); // 背景を半透明に変更して下の市松模様が見えるようにする
    
    for (BackgroundShape shape : shapes) {
      shape.draw(pg);
    }
    
    pg.endDraw();
  }
}

void stop() {
  player.close();
  minim.stop();
  super.stop();
}

// 個々の背景形状を表すクラス
class BackgroundShape {
  float x, y;
  float size;
  float rotation;
  float rotationSpeed;
  float moveSpeed;
  float initialSize;
  color shapeColor;
  float shadowAlpha;
  PVector[] originalVertices; // 元の形状を保存
  PVector[] vertices; // 現在のスケールで使用する頂点
  
  BackgroundShape(int w, int h) {
    x = random(w);
    y = random(h);
    size = random(50, 300);
    initialSize = size; // 初期サイズを保存
    rotation = random(TWO_PI);
    rotationSpeed = random(-0.2, 0.2); // 回転速度を強化
    
    float alpha = random(100, 200);
    
    // 一定の確率で青を混ぜる
    if (random(100) < 5) {
      shapeColor = color(red(BLUE_COLOR), green(BLUE_COLOR), blue(BLUE_COLOR), alpha);
    } else {
      // 通常はピンク/赤系のグラデーションから選択
      color redWithAlpha = color(red(BG_RED_COLOR), green(BG_RED_COLOR), blue(BG_RED_COLOR), alpha);
      color pinkWithAlpha = color(red(BG_PINK_COLOR), green(BG_PINK_COLOR), blue(BG_PINK_COLOR), alpha);
      shapeColor = lerpColor(redWithAlpha, pinkWithAlpha, random(1));
    }
    
    shadowAlpha = alpha * 0.5;
    
    // 頂点を生成して保存（単位サイズ1.0で正規化）
    originalVertices = new PVector[10];
    vertices = new PVector[10];
    for (int i = 0; i < vertices.length; i++) {
      float angle = random(TWO_PI);
      float radius = random(0.8, 1.2); // 単位半径に対する変動
      originalVertices[i] = new PVector(cos(angle) * radius, sin(angle) * radius);
      vertices[i] = new PVector(originalVertices[i].x, originalVertices[i].y); // コピーを作成
    }
    
    // 初期サイズに合わせて頂点を更新
    updateVerticesSize();
  }
  
  // サイズが変更されたときに頂点を更新
  void updateVerticesSize() {
    for (int i = 0; i < vertices.length; i++) {
      vertices[i].x = originalVertices[i].x * size;
      vertices[i].y = originalVertices[i].y * size;
    }
  }
  
  void update() {
    rotate(radians(rotationSpeed)); // 回転を更新
    updateVerticesSize(); // サイズに応じて頂点を更新
  }
  
  void rotate(float angle) {
    rotation += angle;
    if (rotation > TWO_PI) rotation -= TWO_PI;
    if (rotation < 0) rotation += TWO_PI;
  }
  
  void draw(PGraphics pg) {
    // もし形状のサイズが極めて小さい場合はスキップ（最適化）
    if (size < 2) return;
    
    // 影の描画
    pg.fill(BG_SHADOW_COLOR, shadowAlpha);
    pg.noStroke();
    pg.pushMatrix();
    pg.translate(x + 10, y + 10); // 少しずらして影を描く
    pg.rotate(rotation);
    drawVertices(pg);
    pg.popMatrix();
    
    // 形状の描画
    pg.fill(shapeColor);
    
    // 目立たせるためにストロークを追加（オプション）
    if (size > 100) {
      pg.stroke(0, 30); // 薄い黒色の輪郭
      pg.strokeWeight(2);
    } else {
      pg.noStroke();
    }
    
    pg.pushMatrix();
    pg.translate(x, y);
    pg.rotate(rotation); // 回転を適用
    drawVertices(pg);
    pg.popMatrix();
  }
  
  void drawVertices(PGraphics pg) {
    pg.beginShape();
    for (PVector v : vertices) { // 現在のスケールの頂点を使用
      pg.vertex(v.x, v.y);
    }
    pg.endShape(CLOSE);
  }
}

// 中央に向かって流れるアニメーションの背景クラス
class CenterFlowBackground extends RotatingBackground {
  
  CenterFlowBackground(int w, int h) {
    super(w, h);
    // 画面の外側から形状を開始するように初期化
    resetShapesPositions();
  }
  
  // 形状数を指定できるコンストラクタを追加
  CenterFlowBackground(int w, int h, int shapeCount) {
    super(w, h, shapeCount);
    // 画面の外側から形状を開始するように初期化
    resetShapesPositions();
  }
  
  void resetShapesPositions() {
    for (int i = 0; i < shapes.length; i++) {
      // 画面の外側にランダムに配置
      float angle = random(TWO_PI);
      float distance = random(width * 0.7, width * 1.2);
      
      shapes[i].x = width/2 + cos(angle) * distance;
      shapes[i].y = height/2 + sin(angle) * distance;
      
      // 移動速度を形状ごとに設定（多様性を持たせるために広い範囲）
      shapes[i].moveSpeed = random(MIN_ABSORB_SPEED, MAX_ABSORB_SPEED);
      
      // 回転速度を強化
      shapes[i].rotationSpeed = random(-0.2, 0.2);
      
      // 初期サイズを大きめに設定
      shapes[i].initialSize = random(150, 450);
      shapes[i].size = shapes[i].initialSize;
      
      // サイズ変更を適用
      shapes[i].updateVerticesSize();
    }
  }

  // 各形状を更新（回転と移動）
  void update() {
    for (BackgroundShape shape : shapes) {
      // 回転処理の強化 - 回転速度を増加
      float rotationAmount = radians(shape.rotationSpeed * 3); // 回転速度を3倍に
      shape.rotate(rotationAmount);
      
      // 中央までの距離を計算
      float distX = width/2 - shape.x;
      float distY = height/2 - shape.y;
      float distToCenter = sqrt(distX*distX + distY*distY);
      
      // 中央への移動方向を計算
      if (distToCenter > 0) {
        float dirX = distX / distToCenter;
        float dirY = distY / distToCenter;
        
        // 移動速度を適用
        shape.x += dirX * shape.moveSpeed;
        shape.y += dirY * shape.moveSpeed;
        
        // 最大距離を計算（画面対角線の半分より少し大きめ）
        float maxDist = sqrt(width*width + height*height) * 0.6;
        
        // サイズを距離に応じて調整（中央に近いほど小さく）
        float scaleFactor = map(distToCenter, 0, maxDist, 0.2, 1.0);
        scaleFactor = constrain(scaleFactor, 0.0, 1.0); // 0〜1の範囲に制限
        shape.size = shape.initialSize * scaleFactor;
      }
      
      // サイズ変更を頂点に適用
      shape.updateVerticesSize();
      
      // 中央に到達したら画面外に戻す
      if (distToCenter < 15) {
        float angle = random(TWO_PI);
        float distance = width * (0.8 + random(0.5)); // 画面外へ
        
        shape.x = width/2 + cos(angle) * distance;
        shape.y = height/2 + sin(angle) * distance;
        shape.size = shape.initialSize; // サイズをリセット
        
        // 回転速度をランダムに再設定（常に新しい回転を適用）
        shape.rotationSpeed = random(-0.2, 0.2);
        
        shape.updateVerticesSize(); // 頂点を更新
      }
    }
  }
  
  // 形状生成をオーバーライド
  BackgroundShape createShape(int w, int h) {
    BackgroundShape shape = new BackgroundShape(w, h);
    // 移動速度と初期サイズを設定
    shape.moveSpeed = random(MIN_ABSORB_SPEED, MAX_ABSORB_SPEED);
    shape.initialSize = shape.size;
    return shape;
  }
}
