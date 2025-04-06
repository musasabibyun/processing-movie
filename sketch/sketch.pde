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

PGraphics bg1, bg2;
boolean useFirstBackground = true;

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

  // 初期背景生成
  bg1 = createGraphics(width, height, P3D);
  bg2 = createGraphics(width, height, P3D);
  
  drawBackground(bg1);
  drawBackground(bg2);
}

void draw() {
  background(255);
  
  int elapsedTime = millis() - lastBackgroundChangeTime;

  if (!fading && elapsedTime > backgroundChangeInterval) {
    fading = true; // フェード開始
    lastBackgroundChangeTime = millis(); // 時間をリセット
  }

  // フェードが進行する
  if (fading) {
    float fadeProgress = map(elapsedTime, 0, backgroundChangeInterval, 0, 1);
    fadeAmount = constrain(fadeProgress, 0, 1);

    if (fadeAmount >= 1) {
      // フェードが終わったら背景を切り替え
      useFirstBackground = !useFirstBackground;
      drawBackground(useFirstBackground ? bg2 : bg1); // 新しい背景を生成
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
    fill(lerpColor(color(213, 33, 17), color(228, 173, 224), map(fft.getBand(0), 0, 50, 0, 1)));
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
    stroke(27, 27, 27);
    strokeWeight(random(1, 12));
    ellipse(0, 0, circleSize[i], circleSize[i]);
    popMatrix();
  }
  
  saveFrame("../frames/######.tga");
}

void drawBackground(PGraphics bg) {
  bg.beginDraw();
  bg.background(255);
  
  for (int i = 0; i < 20; i++) {
    float x = random(width);
    float y = random(height);
    float size = random(50, 300);
    float alpha = random(100, 200);
    
    // 影の描画（背景の形を少しずらして描画）
    bg.fill(50, 50, 50, alpha * 0.5);  // 影の色と透明度を設定
    bg.noStroke();
    bg.pushMatrix();
    bg.translate(x + 10, y + 10); // 少しずらして影を描く
    bg.rotate(random(TWO_PI));
    bg.beginShape();
    for (int j = 0; j < 10; j++) {
      float angle = random(TWO_PI);
      float r = size * random(0.8, 1.2);
      bg.vertex(cos(angle) * r, sin(angle) * r);
    }
    bg.endShape(CLOSE);
    bg.popMatrix();
    
    // 背景の描画
    bg.fill(lerpColor(color(220, 50, 50, int(alpha)), color(255, 182, 193, int(alpha)), random(1)));
    bg.pushMatrix();
    bg.translate(x, y);
    bg.rotate(random(TWO_PI));
    bg.beginShape();
    for (int j = 0; j < 10; j++) {
      float angle = random(TWO_PI);
      float r = size * random(0.8, 1.2);
      bg.vertex(cos(angle) * r, sin(angle) * r);
    }
    bg.endShape(CLOSE);
    bg.popMatrix();
  }
  
  bg.endDraw();
}

void stop() {
  player.close();
  minim.stop();
  super.stop();
}
