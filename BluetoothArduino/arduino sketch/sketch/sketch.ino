/*

Copyright (c) 2012-2014 RedBearLab

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

/*
 *    Chat
 *
 *    Simple chat sketch, work with the Chat iOS/Android App.
 *    Type something from the Arduino serial monitor to send
 *    to the Chat App or vice verse.
 *
 */

//"RBL_nRF8001.h/spi.h/boards.h" is needed in every new project
#include <SPI.h>
#include <EEPROM.h>
#include <boards.h>
#include <RBL_nRF8001.h>

int PhotoresistancePin = A2;
int PhotoresistanceValue = 0;
int BinaryInput = 5;
int BinaryInputValue = 0;
int ledpin = 10;
int PWMOutputValue = 0;

// interrut and debounce
int interruptLEDPin = 3;
int buttonPin = 2;
int toggleState;
int lastButtonState = 1;
long unsigned int lastPress;
volatile int buttonFlag;
int debounceTime = 20;
// Receive Data From Iphone
unsigned char buf[16] = {0};
unsigned char len = 0;
unsigned char BinaryValue;
char Com[1];
unsigned char PhotoValue;




void setup()
{  
  // Default pins set to 9 and 8 for REQN and RDYN
  // Set your REQN and RDYN here before ble_begin() if you need
  //ble_set_pins(3, 2);
  
  // Set your BLE Shield name here, max. length 10
  //ble_set_name("RedBEAR");
  pinMode(BinaryInput,INPUT);
  pinMode(ledpin,OUTPUT);
  pinMode(interruptLEDPin, OUTPUT);
  pinMode(buttonPin,INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(buttonPin),ISR_button,CHANGE);
  // Init. and start BLE library.
  ble_begin();
  
  // Enable serial debug
  Serial.begin(57600);
}


int outputValue = 0;
int index;
void loop()
{
  PhotoresistanceValue = analogRead(PhotoresistancePin);
  BinaryInputValue = digitalRead(BinaryInput);
  //debounce 
  if((millis() - lastPress) > debounceTime && buttonFlag){
    lastPress = millis();
    if(digitalRead(buttonPin) == 0 && lastButtonState == 1){
      toggleState =! toggleState;
      digitalWrite(interruptLEDPin,toggleState);
      lastButtonState = 0;
    }
    else if(digitalRead(buttonPin) == 1 && lastButtonState == 0){
      lastButtonState = 1;
    }
    buttonFlag = 0;
  }
  //over
  

 
  
  //analogWrite(LedPin,PhotoresistanceValue/4);
  if ( ble_available() )
  {
    index = 0;
    memset(Com,0,3);
    //while ( ble_available() )
    
     //int i = atoi((const char*)ble_read());
      Com[index++]=ble_read();
      //mySerial.read()
      int i = atoi(Com);
      Serial.print(i);
      PWMOutputValue = map(i,0,9,0,255);
      analogWrite(ledpin,PWMOutputValue);
      //Serial.println(ble_read());
      //delay(10);
    //Serial.println();
    
    //Serial.print(buttonState);
  }
  //while(Serial.available()){
  delay(5);
  char stepString[6];
  char stepString2[6];
  itoa(BinaryInputValue,stepString,10);
  itoa(PhotoresistanceValue,stepString2,10);
  strcat(stepString," ");
  strcat(stepString,stepString2);
 
  ble_write_bytes(stepString,strlen(stepString)+1);
  //BinaryValue = BinaryInputValue;
  //Serial.println(BinaryInputValue);
  //Serial.println(BinaryValue);
  //Serial.print(buttonState);
  
  //}
  ble_do_events();
 
}
void ISR_button()
{
  buttonFlag = 1;
}



