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

// 色の定数
color BLUE_COLOR = color(17, 88, 122);
color BLACK_COLOR = color(0, 0, 0);
color RED_COLOR = color(255, 0, 0);
color PINK_COLOR = color(225, 174, 199);

// 背景形状の色
color BG_RED_COLOR = color(220, 50, 50);
color BG_PINK_COLOR = color(255, 182, 193);
color BG_SHADOW_COLOR = color(50, 50, 50);

// 中央円のグラデーション色
color CENTER_RED_COLOR = color(213, 33, 17);
color CENTER_PINK_COLOR = color(228, 173, 224);

// 背景用のPGraphicsオブジェクト
PGraphics bg1, bg2;
boolean useFirstBackground = true;

// 回転可能な背景クラス
RotatingBackground background1;
RotatingBackground background2;

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
  
  // 背景の回転を更新
  background1.update();
  background2.update();
  
  // 背景を描画
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
  
  saveFrame("../frames/######.tga");
}

// 回転する背景を管理するクラス
class RotatingBackground {
  int numShapes = 20;
  BackgroundShape[] shapes;
  
  RotatingBackground(int w, int h) {
    shapes = new BackgroundShape[numShapes];
    for (int i = 0; i < numShapes; i++) {
      shapes[i] = new BackgroundShape(w, h);
    }
  }
  
  void update() {
    for (BackgroundShape shape : shapes) {
      shape.update(); // 各形状が独自の回転を更新
    }
  }
  
  void draw(PGraphics pg) {
    pg.beginDraw();
    pg.background(255);
    
    for (BackgroundShape shape : shapes) {
      shape.draw(pg);
    }
    
    pg.endDraw();
  }
}

// 個々の背景形状を表すクラス
class BackgroundShape {
  float x, y;
  float size;
  float rotation;
  float rotationSpeed; // 各形状の回転速度を追加
  color shapeColor;
  float shadowAlpha;
  PVector[] vertices; // 形状の頂点を保存
  
  BackgroundShape(int w, int h) {
    x = random(w);
    y = random(h);
    size = random(50, 300);
    rotation = random(TWO_PI);
    // -0.05〜0.05の範囲でランダムな回転速度を設定
    rotationSpeed = random(-0.05, 0.05);
    
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
    
    // 頂点を生成して保存
    vertices = new PVector[10];
    for (int i = 0; i < vertices.length; i++) {
      float angle = random(TWO_PI);
      float radius = size * random(0.8, 1.2);
      vertices[i] = new PVector(cos(angle) * radius, sin(angle) * radius);
    }
  }
  
  void update() {
    rotate(radians(rotationSpeed)); // 独自の回転速度で回転
  }
  
  void rotate(float angle) {
    rotation += angle;
    if (rotation > TWO_PI) rotation -= TWO_PI; // 角度を0〜TWO_PIの範囲に保つ
    if (rotation < 0) rotation += TWO_PI; // 負の角度の場合も正規化
  }
  
  void draw(PGraphics pg) {
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
    pg.pushMatrix();
    pg.translate(x, y);
    pg.rotate(rotation);
    drawVertices(pg);
    pg.popMatrix();
  }
  
  void drawVertices(PGraphics pg) {
    pg.beginShape();
    for (PVector v : vertices) {
      pg.vertex(v.x, v.y);
    }
    pg.endShape(CLOSE);
  }
}

void stop() {
  player.close();
  minim.stop();
  super.stop();
}
