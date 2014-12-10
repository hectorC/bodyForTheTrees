/* Based on Advanced Tree Generator 
 * by James Noeckel http://www.openprocessing.org/sketch/8941
 */
 
public class Tree {

  float curlx = 0; 
  float curly = 0; 
  float f = sqrt(2)/2f; 
  float growth = 0; 
  float growthTarget = 0;
  float z1 = 7;
  float z2 = -7;
  float z3 = 0;
  float explode = 0;
  float rot1 = 0;
  float rot2 = 0;
  float dirZ = 1;
  float dirZ2 = 1;
  float zPos = 0;
  float delay = 10;
  
  float perlin;
  float perlin2;
  
  float a[] = new float[3];
  float b[] = new float[3];
  int spikeDir = 0;
  float spikeSpeed = 0.01;
  float spikeLimit = 180;
  
  PImage texture1;

  int curlXamnt, curlYamnt;
  
  Tree() {
    texture1 = loadImage("ink.png");
    
    // Start perlin walk at different ponints for each tree and branch
    perlin2 = random(0, 2000);
    perlin = random(0, 2000);
  }

  public void draw() { 
    
    perlin2 += 0.00215;
    z3 = 160 * (noise(perlin2) - 0.5);
    
    stroke(88);
    fill(68);
    curlx += (radians(360./height*curlXamnt)-curlx)/delay; 
    curly += (radians(360./height*curlYamnt)-curly)/delay; 
    pushMatrix();
    translate(0, height/3*2); 
    strokeWeight(0);
    
    beginShape(QUADS);
    vertex(5, 0, z3);
    vertex(-5, 0, z3);
    vertex(-5, height/2, 0);
    vertex(5, height/2, 0);
    endShape(CLOSE);
    
    strokeWeight(1);
    popMatrix();
    pushMatrix();
    translate(0, height/3*2, z3);
    branch3D(height/5, 9); 
    popMatrix();
    growth += (growthTarget/100-growth+1f);
  }

  private void branch3D(float len, int num) { 
    
    perlin += 0.000062;
    z1 = 30 * (noise(perlin) - 0.5);
    
    len *= f; 
    num -= 1; 
    if ((len > 1) && (num > 0)) 
    { 
      increaseSpike();
      fill(190);
      pushMatrix(); 
      rotate(curlx);
      beginShape(TRIANGLES);
      texture(texture1);
      vertex(a[0], a[1], a[2], 50, 50);
      vertex(len, len, z1, 50, 100);
      vertex(-len, len, 5, 75, 150);
      endShape(CLOSE);
      
      translate(explode, -len, 16); // Z spread
      branch3D(len, num); 
      popMatrix(); 

      len *= growth; 
      pushMatrix(); 
      rotate(curlx-curly + 0); 
      
      beginShape(TRIANGLES);
      texture(texture1);
      vertex(b[0], b[1], b[2], 0, 0);
      vertex(len, len, z1 * -1, 20, 0);
      vertex(-len, len, 5, 20, 20);
      endShape(CLOSE);
      
      translate(explode, -len, -16); // Z spread
      branch3D(len, num); 
      popMatrix(); 
    }
  }

  public void setCurlX(int x) {
    curlXamnt = x;
  }

  public void setCurlY(int y) {
    curlYamnt = y;
  }
  
  private void increaseSpike() {
    float increment = spikeSpeed * spikeDir;
    for (int i=0; i< a.length; i++) {
      a[i] += increment;
      b[i] += increment;
      if (a[i] > spikeLimit) a[i] = spikeLimit;
      if (b[i] > spikeLimit/2) b[i] = spikeLimit/2;
      if (a[i] < 0) a[i] = 0;
      if (b[i] < 0) b[i] = 0;
    }
  }
  
}

