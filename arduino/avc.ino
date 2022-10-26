//Servo for ultrasonic sensor
//Ultrasonic Sensor
//Use TIP120 to switch on/off the vacuum cleaner
//4 dc motors to move the vacuum cleaner

#include <Wire.h>
#include "BluetoothSerial.h"
#include <NewPing.h>

#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif

#define SONAR_NUM 4      // Number of sensors.
#define MAX_DISTANCE 400 // Maximum distance (in cm) to ping.
#define AVC_WIDTH 30     //AVC width in cm

NewPing sonar[SONAR_NUM] = {
    // Sensor object array.
    NewPing(4, 5, MAX_DISTANCE),  // Each sensor's trigger pin, echo pin, and max distance to ping. front 0
    NewPing(6, 7, MAX_DISTANCE),  // left 1
    NewPing(8, 9, MAX_DISTANCE),  // bottom 2
    NewPing(10, 11, MAX_DISTANCE) //right 3
};

//below are the features that is going to be implemented
//- room mapping
//- auto charging

/*
 * For a room with no obstacle
 * go to an edge, 
 * find the 2 smallest distance, 
 * move LB,RB,LF or RF there until one of the distance is less than 6, 
 * then find smallest distance again and move there until that dir is less than 6
 * 
 * determine which way to start based on free distance, LB,RB,LF or RF
 * choose algo--- FB movement or RL movement
 * 
 * FB Movement based on free distance and then 2nd movement based on R or L part
 * 1. move F or B until either is less than 6,
 * 2. move L or R for distance avc width/2 i.e delay
 * 3. then go back to 1
 * 
 * always check based on R or L type if either is blocked
 * if not blocked continue else
 * cleanCnt++
 * if cleancnt == 2, stop
 * changeMode to RL Movement
 * 
 * RL Movement based on free distance and then 2nd movement based on F or B part
 * 1. move R or L until either is less than 6,
 * 2. move F or B for distance avc width/2 i.e delay
 * 3. then go back to 1
 * 
 * always check based on F or B type if either is blocked
 * if not blocked continue else
 * cleanCnt++
 * ic cleanCnt == 2, stop
 * changeMode to FB Movement
 */

#define AVC_SMALL 6

bool isFB = true;

BluetoothSerial SerialBT;
/*
 TB6612FNG Dual Motor Driver -> Arduino Mega 2560
 //PWM control
 RightFrontMotor_PWMA - 2
 LeftFrontMotor_PWMB - 3
 RightRearMotor_PWMA - 4
 LeftRearMotor_PWMB - 5
 //Control of rotation direction
 RightFrontMotor_AIN1 - 22
 RightFrontMotor_AIN2 - 23
 LeftFrontMotor_BIN1 - 24
 LeftFrontMotor_BIN2 - 25
 RightRearMotor_AIN1 - 26
 RightRearMotor_AIN2 - 27
 LeftRearMotor_BIN1 - 28
 LeftRearMotor_BIN2 - 29
 //The module and motors power supply
 STBY - Vcc
 VMOT - motor voltage (4.5 to 13.5 V) - 11.1V from LiPo battery
 Vcc - logic voltage (2.7 to 5.5) - 5V from Arduino
 GND - GND
 
 TB6612FNG Dual Motor Driver -> DC Motors
 MotorDriver1_AO1 - RightFrontMotor
 MotorDriver1_A02 - RightFrontMotor
 MotorDriver1_B01 - LeftFrontMotor
 MotorDriver1_B02 - LeftFrontMotor
 
 MotorDriver2_AO1 - RightRearMotor
 MotorDriver2_A02 - RightRearMotor
 MotorDriver2_B01 - LeftRearMotor
 MotorDriver2_B02 - LeftRearMotor
 */
#include <math.h>
/*TB6612FNG Dual Motor Driver Carrier*/
const uint8_t RightFrontMotor_PWM = 2; // pwm output
const uint8_t LeftFrontMotor_PWM = 3;  // pwm output
const uint8_t RightRearMotor_PWM = 4;  // pwm output
const uint8_t LeftRearMotor_PWM = 5;   // pwm output
//Front motors
const uint8_t RightFrontMotor_AIN1 = 22; // control Input AIN1 - right front motor
const uint8_t RightFrontMotor_AIN2 = 23; // control Input AIN2 - right front motor
const uint8_t LeftFrontMotor_BIN1 = 24;  // control Input BIN1 - left front motor
const uint8_t LeftFrontMotor_BIN2 = 25;  // control Input BIN2 - left front motor
//Rear motors
const uint8_t RightRearMotor_AIN1 = 26; // control Input AIN1 - right rear motor
const uint8_t RightRearMotor_AIN2 = 27; // control Input AIN2 - right rear motor
const uint8_t LeftRearMotor_BIN1 = 28;  // control Input BIN1 - left rear motor
const uint8_t LeftRearMotor_BIN2 = 29;  // control Input BIN2 - left rear  motor

long pwmLvalue = 255;
long pwmRvalue = 255;
byte pwmChannel = 0;
const uint8_t MaxSpeed = 255;
const char startOfNumberDelimiter = '<';
const char endOfNumberDelimiter = '>';
const uint8_t RELAY_VAC = 6;

int distance;
long duration;

void setup()
{
  // put your setup code here, to run once:
  pinMode(RELAY_VAC, OUTPUT);
  Serial1.begin(9600); // HC-06 default baudrate: 9600

  //Setup RightFrontMotor
  pinMode(RightFrontMotor_AIN1, OUTPUT); //Initiates Motor Channel A1 pin
  pinMode(RightFrontMotor_AIN2, OUTPUT); //Initiates Motor Channel A2 pin

  //Setup LeftFrontMotor
  pinMode(LeftFrontMotor_BIN1, OUTPUT); //Initiates Motor Channel B1 pin
  pinMode(LeftFrontMotor_BIN2, OUTPUT); //Initiates Motor Channel B2 pin

  //Setup RightFrontMotor
  pinMode(RightRearMotor_AIN1, OUTPUT); //Initiates Motor Channel A1 pin
  pinMode(RightRearMotor_AIN2, OUTPUT); //Initiates Motor Channel A2 pin

  //Setup LeftFrontMotor
  pinMode(LeftRearMotor_BIN1, OUTPUT); //Initiates Motor Channel B1 pin
  pinMode(LeftRearMotor_BIN2, OUTPUT); //Initiates Motor Channel B2 pin

  ledcSetup(RightFrontMotor_PWM, 30000, 8);
  ledcSetup(LeftFrontMotor_PWM, 30000, 8);
  ledcSetup(RightRearMotor_PWM, 30000, 8);
  ledcSetup(LeftRearMotor_PWM, 30000, 8);

  // attach the channel to the GPIO to be controlled
  ledcAttachPin(RightFrontMotor_PWM, RightFrontMotor_PWM);
  ledcAttachPin(LeftFrontMotor_PWM, LeftFrontMotor_PWM);
  ledcAttachPin(RightRearMotor_PWM, RightRearMotor_PWM);
  ledcAttachPin(LeftRearMotor_PWM, LeftRearMotor_PWM);

  Wire.begin();
  Serial.begin(115200);
  SerialBT.begin("AVC-vac");
}

void loop()
{
  if (SerialBT.available())
  {
    processInput();
  }
} // void loop()

//Autonomous Operation

bool isNotNear(uint8_t pos)
{
  return sonar[pos].ping_cm() > AVC_SMALL;
}

int posSpace(uint8_t pos)
{
  return sonar[pos].ping_cm();
}

bool isR()
{
  return isNotNear(3);
}

bool isF()
{
  return isNotNear(0);
}

bool anyIsNotNear()
{
  for (uint8_t i = 0; i < SONAR_NUM; i++)
  {
    if (!isNotNear(i))
    {
      return false;
    }
  }
  return true;
}

uint8_t *getFreeSpace()
{
  static uint8_t freeSpace[4] = {0, 0, 0, 0};
  for (uint8_t i = 0; i < SONAR_NUM; i++)
  {
    freeSpace[i] = isNotNear(i) ? 1 : 0;
  }
  return freeSpace;
}

uint8_t *getSmallSpace()
{
  static uint8_t smallSpace[4] = {1, 1, 1, 1};
  unsigned int maxNo = 0;
  uint8_t maxNoIndex = 0;
  for (uint8_t i = 0; i < SONAR_NUM; i++)
  {
    if (posSpace(i) > maxNo)
    {
      maxNo = posSpace(i);
      maxNoIndex = i;
    }
  }
  smallSpace[maxNoIndex] = 0;
  maxNo = 0;
  for (uint8_t i = 0; i < SONAR_NUM; i++)
  {
    if (i == maxNoIndex)
    {
      continue;
    }
    if (posSpace(i) > maxNo)
    {
      maxNo = posSpace(i);
      maxNoIndex = i;
    }
  }
  smallSpace[maxNoIndex] = 0;
  return smallSpace;
}

void chooseEdge()
{
  while (anyIsNotNear())
  {
    moveRange(getSmallSpace());
  }
  unsigned int minNo = 500;
  uint8_t minNoIndex = 0;
  for (uint8_t i = 0; i < SONAR_NUM; i++)
  {
    if (posSpace(i) < minNo)
    {
      minNo = posSpace(i);
      minNoIndex = i;
    }
  }
  while (anyIsNotNear())
  {
    movePos(minNoIndex);
  }
}

uint8_t getCmod()
{
  uint8_t cmod = 0;
  if (isFB)
  {
    cmod = isR ? 1 : 3;
  }
  else
  {
    cmod = isF ? 0 : 2;
  }
  return cmod;
}

void startClean()
{
  uint8_t cmod = getCmod();
  uint8_t cleanCnt = 0;
  uint8_t curPos = 0;
  while (cleanCnt != 4)
  {
    if (isFB)
    {
      curPos = isF ? 0 : 2;
    }
    else
    {
      curPos = isR ? 1 : 3;
    }

    while (isNotNear(curPos))
    {
      movePos(curPos);
    }
    if (posSpace(cmod) <= AVC_WIDTH / 2)
    {
      //move in such a way that it would be near the wall
      cleanCnt++;
      isFB = !isFB;
      cmod = getCmod();
    }
    else
    {
      movePos(cmod);
      delay(600); //basic conversion
    }
  }
}

void automod()
{
  chooseEdge();
  startClean();
}

void movePos(uint8_t pos)
{
  switch (pos)
  {
  case 0:
    goForward(255);
    break;
  case 1:
    moveLeft(255);
    break;
  case 2:
    goBackwad(255);
    break;
  case 3:
    moveLeft(255);
    break;
  }
}

void moveRange(uint8_t *arr)
{
  uint8_t a = pow(2, arr[0]) + pow(2, arr[1]) + pow(2, arr[2]) + pow(2, arr[3]);
  switch (a)
  {
  case 12:
    moveRightForward(255);
    break;
  case 9:
    moveLeftForward(255);
    break;
  case 3:
    moveLeftBackward(255);
    break;
  case 6:
    moveRightBackward(255);
    break;
  }
}

//manual operation

void processInput()
{
  static long receivedNumber = 0;
  static boolean negative = false;
  byte c = SerialBT.read();

  switch (c)
  {
  case endOfNumberDelimiter:
    if (negative)
      SetPWM(-receivedNumber, pwmChannel);
    else
      SetPWM(receivedNumber, pwmChannel);

    // fall through to start a new number
  case startOfNumberDelimiter:
    receivedNumber = 0;
    negative = false;
    pwmChannel = 0;
    break;

  case 'f': // Go FORWARD
    goForward(255);
    //Serial.println("forward");
    break;

  case 'b': // Go BACK
    goBackwad(255);
    //Serial.println("backward");
    break;

  case 'r':
    moveRight(255);
    break;

  case 'l':
    moveLeft(255);
    break;

  case 'i':
    turnRight(255);
    break;

  case 'j':
    turnLeft(255);
    break;

  case 'c': // Top Right
    moveRightForward(255);
    break;

  case 'd': // Top Left
    moveLeftForward(255);
    break;

  case 'e': // Bottom Right
    moveRightBackward(255);
    break;

  case 'h': // Bottom Left
    moveLeftBackward(255);
    break;

  case 's':
    hardStop();
    break;

  case 'o':
    switchVac(true);
    break;

  case 'O':
    switchVac(false);
    break;

  case 'x':
    pwmChannel = 1; // RightFrontMotor_PWM
    break;
  case 'y': // LeftFrontMotor_PWM
    pwmChannel = 2;
    break;

  case '0' ... '9':
    receivedNumber *= 10;
    receivedNumber += c - '0';
    break;

  case '-':
    negative = true;
    break;
  } // end of switch
} // void processInput ()

void motorControl(String motorStr, uint8_t mdirection, uint8_t mspeed)
{
  uint8_t IN1;
  uint8_t IN2;
  uint8_t motorPWM;
  if (motorStr == "rf")
  { //right front
    IN1 = RightFrontMotor_AIN1;
    IN2 = RightFrontMotor_AIN2;
    motorPWM = RightFrontMotor_PWM;
  }
  else if (motorStr == "lf")
  { //left front
    IN1 = LeftFrontMotor_BIN1;
    IN2 = LeftFrontMotor_BIN2;
    motorPWM = LeftFrontMotor_PWM;
  }
  else if (motorStr == "rr")
  {
    IN1 = RightRearMotor_AIN1;
    IN2 = RightRearMotor_AIN2;
    motorPWM = RightRearMotor_PWM;
  }
  else if (motorStr == "lr")
  {
    IN1 = LeftRearMotor_BIN1;
    IN2 = LeftRearMotor_BIN2;
    motorPWM = LeftRearMotor_PWM;
  }
  if (mdirection == 1)
  {
    digitalWrite(IN1, LOW);
    digitalWrite(IN2, HIGH);
  }
  else if (mdirection == -1)
  {
    digitalWrite(IN1, HIGH);
    digitalWrite(IN2, LOW);
  }
  ledcWrite(motorPWM, mspeed);
}

void goForward(uint8_t mspeed)
{
  motorControl("rf", 1, mspeed);
  motorControl("lf", 1, mspeed);
  motorControl("rr", 1, mspeed);
  motorControl("lr", 1, mspeed);
} // void goForward(uint8_t mspeed)

void goBackwad(uint8_t mspeed)
{
  motorControl("rf", -1, mspeed);
  motorControl("lf", -1, mspeed);
  motorControl("rr", -1, mspeed);
  motorControl("lr", -1, mspeed);
} // void goBackwad(uint8_t mspeed)

void moveRight(uint8_t mspeed)
{
  motorControl("rf", -1, mspeed);
  motorControl("lf", 1, mspeed);
  motorControl("rr", 1, mspeed);
  motorControl("lr", -1, mspeed);
} // void moveRight(uint8_t mspeed)

void moveLeft(uint8_t mspeed)
{
  motorControl("rf", 1, mspeed);
  motorControl("lf", -1, mspeed);
  motorControl("rr", -1, mspeed);
  motorControl("lr", 1, mspeed);
} // void moveLeft(uint8_t mspeed)

void moveRightForward(uint8_t mspeed)
{
  motorControl("rf", 1, 0);
  motorControl("lf", 1, mspeed);
  motorControl("rr", 1, mspeed);
  motorControl("lr", 1, 0);
} // void  moveRightForward(uint8_t mspeed)

void moveRightBackward(uint8_t mspeed)
{
  motorControl("rf", -1, mspeed);
  motorControl("lf", 1, 0);
  motorControl("rr", 1, 0);
  motorControl("lr", -1, mspeed);
} // void  moveRightBackward(uint8_t mspeed)

void moveLeftForward(uint8_t mspeed)
{
  motorControl("rf", 1, mspeed);
  motorControl("lf", 1, 0);
  motorControl("rr", 1, 0);
  motorControl("lr", 1, mspeed);
} // void  moveLeftForward(uint8_t mspeed)

void moveLeftBackward(uint8_t mspeed)
{
  motorControl("rf", 1, 0);
  motorControl("lf", -1, mspeed);
  motorControl("rr", -1, mspeed);
  motorControl("lr", 1, 0);
} // void  moveLeftBackward(uint8_t mspeed)

void turnRight(uint8_t mspeed)
{
  motorControl("rf", -1, mspeed);
  motorControl("lf", 1, mspeed);
  motorControl("rr", -1, mspeed);
  motorControl("lr", 1, mspeed);
} // void turnRight(uint8_t mspeed)

void turnLeft(uint8_t mspeed)
{
  motorControl("rf", 1, mspeed);
  motorControl("lf", -1, mspeed);
  motorControl("rr", 1, mspeed);
  motorControl("lr", -1, mspeed);
} // void turnRight(uint8_t mspeed)

void stopRobot(int delay_ms)
{
  ledcWrite(RightFrontMotor_PWM, 0);
  ledcWrite(LeftFrontMotor_PWM, 0);
  ledcWrite(RightRearMotor_PWM, 0);
  ledcWrite(LeftRearMotor_PWM, 0);
  delay(delay_ms);
} // void stopRobot(int delay_ms)

void hardStop()
{
  ledcWrite(RightFrontMotor_PWM, 0);
  ledcWrite(LeftFrontMotor_PWM, 0);
  ledcWrite(RightRearMotor_PWM, 0);
  ledcWrite(LeftRearMotor_PWM, 0);
} // void stopRobot()

void switchVac(bool isOn)
{
  if (isOn)
  {
    digitalWrite(RELAY_VAC, HIGH);
  }
  else
  {
    digitalWrite(RELAY_VAC, LOW);
  }
}

void SetPWM(const long pwm_num, byte pwm_channel)
{
  if (pwm_channel == 1)
  { // DRIVE MOTOR
    ledcWrite(RightFrontMotor_PWM, pwm_num);
    pwmRvalue = pwm_num;
  }
  else if (pwm_channel == 2)
  { // STEERING MOTOR
    ledcWrite(LeftFrontMotor_PWM, pwm_num);
    pwmLvalue = pwm_num;
  }
} // void SetPWM (const long pwm_num, byte pwm_channel)