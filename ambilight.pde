import java.awt.*;
import java.awt.image.*;
import processing.serial.*;

// using 25 RGB LEDs
//static final int led_num_x = 10;
//static final int led_num_y = 6;
//static final int leds[][] = new int[][] {
//  {4,5}, {3,5}, {2,5}, {1,5}, {0,5}, // Bottom edge, left half
//  {0,4}, {0,3}, {0,2}, {0,1}, // Left edge
//  {0,0}, {1,0}, {2,0}, {3,0}, {4,0}, {5,0}, {6,0}, {7,0}, {8,0}, {9,0}, // Top edge
//  {9,1}, {9,2}, {9,3}, {9,4}, // Right edge
//  {9,5}, {8,5}, {7,5}, {6,5}, {5,5}  // Bottom edge, right half
//
//};

static final int led_num_x = 47;
static final int led_num_y = 28;
static final int leds[][] = new int[][] {
  {23,27},{22,27},{21,27},{20,27},{19,27},{18,27},{17,27},{16,27},{15,27},{14,27},{13,27},{12,27},{11,27},{10,27},{9,27},{8,27},{7,27},{6,27},{5,27},{4,27},{3,27},{2,27},{1,27},
  {0,27},{0,26},{0,25},{0,24},{0,23},{0,22},{0,21},{0,20},{0,19},{0,18},{0,17},{0,16},{0,15},{0,14},{0,13},{0,12},{0,11},{0,10},{0,9},{0,8},{0,7},{0,6},{0,5},{0,4},{0,3},{0,2},{0,1},
  {0,0},{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{12,0},{13,0},{14,0},{15,0},{16,0},{17,0},{18,0},{19,0},{20,0},{21,0},{22,0},{23,0},{24,0},{25,0},{26,0},{27,0},{28,0},{29,0},{30,0},{31,0},{32,0},{33,0},{34,0},{35,0},{36,0},{37,0},{38,0},{39,0},{40,0},{41,0},{42,0},{43,0},{44,0},{45,0},{46,0},
  {46,0},{46,1},{46,2},{46,3},{46,4},{46,5},{46,6},{46,7},{46,8},{46,9},{46,10},{46,11},{46,12},{46,13},{46,14},{46,15},{46,16},{46,17},{46,18},{46,19},{46,20},{46,21},{46,22},{46,23},{46,24},{46,25},{46,26},{46,27},
  {46,27},{45,27},{44,27},{43,27},{42,27},{41,27},{40,27},{39,27},{38,27},{37,27},{36,27},{35,27},{34,27},{33,27},{32,27},{31,27},{30,27},{29,27},{28,27},{27,27},{26,27},{25,27},{24,27}
};


static final short fade = 70; //<>//

// Preview windows
int preview_pixel_width;
int preview_pixel_height;

int[][] pixelOffset = new int[leds.length][256];

// RGB values for each LED
short[][] ledColor = new short[leds.length][3];
short[][] prevColor = new short[leds.length][3];  
byte[] serialData  = new byte[ leds.length * 3 + 2];
int data_index = 0;

//creates object from java library that lets us take screenshots
Robot bot;
// bounds area for screen capture         
Rectangle dispBounds;
// Monitor Screen information    
GraphicsEnvironment     ge;
GraphicsConfiguration[] gc;
GraphicsDevice[]        gd;

Serial port;

void setup(){
  int[] x = new int[16];
  int[] y = new int[16];

  // ge - Grasphics Environment
  ge = GraphicsEnvironment.getLocalGraphicsEnvironment();
  // gd - Grasphics Device
  gd = ge.getScreenDevices();
  DisplayMode mode = gd[0].getDisplayMode();
  dispBounds = new Rectangle(0, 0, mode.getWidth(), mode.getHeight());

  // Preview windows
  preview_pixel_width = 768/led_num_x;
  preview_pixel_height = 432/led_num_y;

  // Preview window size
  size(768, 432);

  //standard Robot class error check
  try   {
    bot = new Robot(gd[0]);
  }
  catch (AWTException e)  {
    println("Robot class not supported by your system!");
    exit();
  }

  float range, step, start;

  for(int i=0; i<leds.length; i++) { // For each LED...

    // Precompute columns, rows of each sampled point for this LED

    // --- for columns -----
    range = (float)dispBounds.width / led_num_x;
    // we only want 256 samples, and 16*16 = 256
    step  = range / 16.0; 
    start = range * (float)leds[i][0] + step * 0.5;

    for(int col=0; col<16; col++) {
      x[col] = (int)(start + step * (float)col);
    }

    // ----- for rows -----
    range = (float)dispBounds.height / led_num_y;
    step  = range / 16.0;
    start = range * (float)leds[i][1] + step * 0.5;

    for(int row=0; row<16; row++) {
      y[row] = (int)(start + step * (float)row);
    }

    // ---- Store sample locations -----

    // Get offset to each pixel within full screen capture
    for(int row=0; row<16; row++) {
      for(int col=0; col<16; col++) {
        pixelOffset[i][row * 16 + col] = y[row] * dispBounds.width + x[col];
      }
    }

  }

  // Open serial port. this assumes the Arduino is the
  // first/only serial device on the system.  If that's not the case,
  // change "Serial.list()[0]" to the name of the port to be used:
  // you can comment it out if you only want to test it without the Arduino
  port = new Serial(this, "COM3", 115200);

  // A special header expected by the Arduino, to identify the beginning of a new bunch data.  
  serialData[0] = 'o';
  serialData[1] = 'z';
}

void draw(){
  //get screenshot into object "screenshot" of class BufferedImage
  BufferedImage screenshot = bot.createScreenCapture(dispBounds);

  // Pass all the ARGB values of every pixel into an array
  int[] screenData = ((DataBufferInt)screenshot.getRaster().getDataBuffer()).getData(); //<>//

  data_index = 2; // 0, 1 are predefined header

  for(int i=0; i<leds.length; i++) {  // For each LED...

    int r = 0;
    int g = 0;
    int b = 0;

    for(int o=0; o<256; o++)    
    {
      //ARGB variable with 32 int bytes where               
      int pixel = screenData[ pixelOffset[i][o] ];            
      r += pixel & 0x00ff0000;
      g += pixel & 0x0000ff00;
      b += pixel & 0x000000ff;
    }
    
    // Blend new pixel value with the value from the prior frame   
    ledColor[i][0] = (short)(((( r >> 24) & 0xff) * (255 - fade) + prevColor[i][0] * fade) >> 8);
    ledColor[i][1] = (short)(((( g >> 16) & 0xff) * (255 - fade) + prevColor[i][1] * fade) >> 8);
    ledColor[i][2] = (short)(((( b >>  8) & 0xff) * (255 - fade) + prevColor[i][2] * fade) >> 8);
    
    serialData[data_index++] = (byte)ledColor[i][0];
    serialData[data_index++] = (byte)ledColor[i][1];
    serialData[data_index++] = (byte)ledColor[i][2];

    float preview_pixel_left  = (float)dispBounds.width  /5 / led_num_x * leds[i][0] ;
    float preview_pixel_top    = (float)dispBounds.height /5 / led_num_y * leds[i][1] ;

    color rgb = color(ledColor[i][0], ledColor[i][1], ledColor[i][2]);
    fill(rgb);  
    rect(preview_pixel_left, preview_pixel_top, preview_pixel_width, preview_pixel_height);

  }

  if(port != null) {
    // wait for Arduino to send data
    for(;;){
      if(port.available() > 0){
        int inByte = port.read();
        if (inByte == 'y')
          break;
      }
      break;
    }
    port.write(serialData); // Issue data to Arduino //<>//
  }
  delay(100);
  // Benchmark, how are we doing?
  //println(frameRate);
  arrayCopy(ledColor, prevColor); //<>//
}