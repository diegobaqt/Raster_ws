import frames.timing.*;
import frames.primitives.*;
import frames.processing.*;

// 1. Frames' objects
Scene scene;
Frame frame;
Vector v1, v2, v3;
// timing
TimingTask spinningTask;
boolean yDirection;
// scaling is a power of 2
int n = 4;

// 2. Hints
boolean triangleHint = true;
boolean gridHint = true;
boolean debug = true;

// 3. Use FX2D, JAVA2D, P2D or P3D
String renderer = P3D;

void setup() {
  //use 2^n to change the dimensions
  size(512, 512, renderer);
  scene = new Scene(this);
  if (scene.is3D())
    scene.setType(Scene.Type.ORTHOGRAPHIC);
  scene.setRadius(width/2);
  scene.fitBallInterpolation();

  // not really needed here but create a spinning task
  // just to illustrate some frames.timing features. For
  // example, to see how 3D spinning from the horizon
  // (no bias from above nor from below) induces movement
  // on the frame instance (the one used to represent
  // onscreen pixels): upwards or backwards (or to the left
  // vs to the right)?
  // Press ' ' to play it :)
  // Press 'y' to change the spinning axes defined in the
  // world system.
  spinningTask = new TimingTask() {
    public void execute() {
      spin();
    }
  };
  scene.registerTask(spinningTask);

  frame = new Frame();
  frame.setScaling(width/pow(2, n));

  // init the triangle that's gonna be rasterized
  randomizeTriangle();
}

void draw() {
  background(0);
  stroke(0, 255, 0);
  if (gridHint)
    scene.drawGrid(scene.radius(), (int)pow( 2, n));
  if (triangleHint)
    drawTriangleHint();
  pushMatrix();
  pushStyle();
  scene.applyTransformation(frame);
  triangleRaster();
  popStyle();
  popMatrix();
}

// Implement this function to rasterize the triangle.
// Coordinates are given in the frame system which has a dimension of 2^n
void triangleRaster() {
  // frame.coordinatesOf converts from world to frame
  // here we convert v1 to illustrate the idea
  if (debug) {
    pushStyle();
    stroke(255, 255, 0, 125);
    point(round(frame.coordinatesOf(v1).x()), round(frame.coordinatesOf(v1).y()));
    point(round(frame.coordinatesOf(v2).x()), round(frame.coordinatesOf(v2).y()));
    point(round(frame.coordinatesOf(v3).x()), round(frame.coordinatesOf(v3).y()));
    popStyle();    
  }
  
  int maxX = round(max(frame.coordinatesOf(v1).x(), frame.coordinatesOf(v2).x(), frame.coordinatesOf(v3).x()));
  int maxY = round(max(frame.coordinatesOf(v1).y(), frame.coordinatesOf(v2).y(), frame.coordinatesOf(v3).y()));
  int minX = round(min(frame.coordinatesOf(v1).x(), frame.coordinatesOf(v2).x(), frame.coordinatesOf(v3).x()));
  int minY = round(min(frame.coordinatesOf(v1).y(), frame.coordinatesOf(v2).y(), frame.coordinatesOf(v3).y()));
  
  // F = (v0y  - v1y)Px + (v1x - v0x)Py + (v0x*v1y - v0y*v1x) 
  // F = A01*Px + B01*Py + C01 
  float A12 = frame.coordinatesOf(v1).y() - frame.coordinatesOf(v2).y();
  float B12 = frame.coordinatesOf(v2).x() - frame.coordinatesOf(v1).x();
  float C12 = frame.coordinatesOf(v1).x()*frame.coordinatesOf(v2).y() - frame.coordinatesOf(v1).y()*frame.coordinatesOf(v2).x() ;
  
  float A23 = frame.coordinatesOf(v2).y() - frame.coordinatesOf(v3).y();
  float B23 = frame.coordinatesOf(v3).x() - frame.coordinatesOf(v2).x();
  float C23 = frame.coordinatesOf(v2).x()*frame.coordinatesOf(v3).y() - frame.coordinatesOf(v2).y()*frame.coordinatesOf(v3).x() ;
  
  float A31 = frame.coordinatesOf(v3).y() - frame.coordinatesOf(v1).y();
  float B31 = frame.coordinatesOf(v1).x() - frame.coordinatesOf(v3).x();
  float C31 = frame.coordinatesOf(v3).x()*frame.coordinatesOf(v1).y() - frame.coordinatesOf(v3).y()*frame.coordinatesOf(v1).x() ;
  
  
  boolean negative = false;
  if ((A12*frame.coordinatesOf(v3).x()+B12*frame.coordinatesOf(v3).y()+C12)<0)
    negative =true;
  
  strokeWeight(0);
  int antialiasing = 16;
  
  for (int x = minX; x <= maxX; x++){
    for (int y = minY; y <= maxY; y++){
      Vector b = new Vector(x, y);
      float RED = 0, GREEN = 0, BLUE = 0;
      for (float i = 0; i<1; i+=(float)1/antialiasing)
        for (float j = 0; j<1; j+=(float)1/antialiasing) {
          Vector p = new Vector(x+i+1/antialiasing/2, y+i+1/antialiasing/2);
          float w0 = A12*p.x()+B12*p.y()+C12;
          float w1 = A23*p.x()+B23*p.y()+C23;
          float w2 = A31*p.x()+B31*p.y()+C31;
          if ((w0 < 0 && w1 < 0 && w2 < 0 && negative) || (w0 >= 0 && w1 >= 0 && w2 >= 0)) {
            RED+=w0*255/(w0+w1+w2)/(antialiasing*antialiasing);
            GREEN+=w1*255/(w0+w1+w2)/(antialiasing*antialiasing);
            BLUE+=w2*255/(w0+w1+w2)/(antialiasing*antialiasing);
          }
      }
      fill(color(round(RED), round(GREEN), round(BLUE)));
      rect(b.x(), b.y(), 1, 1);
    }
  }
}

void randomizeTriangle() {
  int low = -width/2;
  int high = width/2;
  v1 = new Vector(random(low, high), random(low, high));
  v2 = new Vector(random(low, high), random(low, high));
  v3 = new Vector(random(low, high), random(low, high));
}

void drawTriangleHint() {
  pushStyle();
  noFill();
  strokeWeight(2);
  stroke(255, 0, 0);
  triangle(v1.x(), v1.y(), v2.x(), v2.y(), v3.x(), v3.y());
  strokeWeight(5);
  stroke(0, 255, 255);
  point(v1.x(), v1.y());
  point(v2.x(), v2.y());
  point(v3.x(), v3.y());
  popStyle();
}

void spin() {
  if (scene.is2D())
    scene.eye().rotate(new Quaternion(new Vector(0, 0, 1), PI / 100), scene.anchor());
  else
    scene.eye().rotate(new Quaternion(yDirection ? new Vector(0, 1, 0) : new Vector(1, 0, 0), PI / 100), scene.anchor());
}

void keyPressed() {
  if (key == 'g')
    gridHint = !gridHint;
  if (key == 't')
    triangleHint = !triangleHint;
  if (key == 'd')
    debug = !debug;
  if (key == '+') {
    n = n < 7 ? n+1 : 2;
    frame.setScaling(width/pow( 2, n));
  }
  if (key == '-') {
    n = n >2 ? n-1 : 7;
    frame.setScaling(width/pow( 2, n));
  }
  if (key == 'r')
    randomizeTriangle();
  if (key == ' ')
    if (spinningTask.isActive())
      spinningTask.stop();
    else
      spinningTask.run(20);
  if (key == 'y')
    yDirection = !yDirection;
}
