#include <APA102.h>

const uint8_t dataPin = 2;
const uint8_t clockPin = 3;
APA102<dataPin, clockPin> ledStrip;

#define NUM_LED 148
#define NUM_DATA 446 // NUM_LED * 3 + 2
#define RECON_TIME 2000 // after x seconds idle time, send afk again.
byte led_color[NUM_DATA];
rgb_color colors[NUM_LED];

int index = 0;
short kleurtjesTeller = 0;
unsigned long last_afk = 0;
unsigned long cur_time = 0;

void setup() {
  pinMode(dataPin, OUTPUT);
  pinMode(clockPin, OUTPUT);

  //clean
  ledStrip.startFrame();
  for (int i = 0; i < 148; i++) {
    ledStrip.sendColor(0, 0, 0);
  }
  ledStrip.endFrame(NUM_LED);
  
  Serial.begin(115200);
  Serial.print("y"); // Send ACK string to host

  for (;;) {
    if (Serial.available() > 0) {
      // Geef het eerste lampje een kleurtje
      //  ledStrip.startFrame();
      //  for (int i = 0; i < NUM_LED; i++){
      //    ledStrip.sendColor((int)(i * 255.0/148), kleurtjesTeller, 0);
      //  }
      //  kleurtjesTeller++;
      //  ledStrip.endFrame(NUM_LED);
      
      led_color[index++] = (uint8_t)Serial.read();
      
      if (index >= NUM_DATA) {

        //Serial.write('y');
        last_afk =  millis();
        index = 0;

        if ((led_color[0] == 'o') && (led_color[1] == 'z')) {
          // update LEDs

//          ledStrip.startFrame();
//          for (int i = 0; i < NUM_LED; i++) {
//            int led_index = i * 3 + 2;
//            //color[i] = Color(led_color[led_index + 2], led_color[led_index + 1], led_color[led_index]));
//            ledStrip.sendColor(led_color[led_index], led_color[led_index + 1], led_color[led_index + 2], 1);
//          }
//          ledStrip.endFrame(NUM_LED);

            ledStrip.startFrame();  // Start het frame
            for (int i = 0; i < NUM_LED; i++) {
              int led_index = i * 3 + 2;
            //  colors[i] = rgb_color(led_color[led_index], led_color[led_index + 1], led_color[led_index + 2]);
              ledStrip.sendColor(led_color[led_index], led_color[led_index + 1], led_color[led_index + 2], 31);
            }
            ledStrip.endFrame(NUM_LED); // Eindig het frame
            //ledStrip.write(colors, NUM_LED, 5);
        }
      }
    } 
    else {
      cur_time = millis();
      if (cur_time - last_afk > RECON_TIME) {
        //Serial.write('y');
        Serial.print("ozy");
        last_afk =  cur_time;
        index = 0;
      }
    }
  }
}

void loop() {
}
