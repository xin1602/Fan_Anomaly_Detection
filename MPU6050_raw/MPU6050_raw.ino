#include<Wire.h>

unsigned long passTime = 0;
unsigned long lastTime = 0;

#define MPU_ACC_CONST 16384 // for +-2G

int16_t acc_x = 0; //暫存加速度X
int16_t acc_y = 0;
int16_t acc_z = 0;

void mpu6050_reset(byte address) {
  Wire.beginTransmission(address);
  Wire.write(0x6B); // PWR_MGMT_1
  Wire.write(0x89);
  Wire.endTransmission(true);
  delay(100);
}

void mpu6050_init(byte address) { //傳入參數是感測器I2C位置
  //設定值參考說明書42頁
  Wire.beginTransmission(address);
  Wire.write(0x6B); // PWR_MGMT_1 and PWR_MGMT_2
  Wire.write(0x09); //不用睡眠模式及循環模式；關閉溫度感測器，Clock設定X重力參照
  Wire.write(0x87); //取樣率隨便設定(因為不用循環模式)；打開加速度感測器；關閉重力感測器
  Wire.endTransmission(true);
  delay(100);

  //設定值參考說明書13頁
  //設定低通濾波21Hz
  Wire.beginTransmission(address);
  Wire.write(0x1A); // CONFIG
  Wire.write(0x04);
  Wire.endTransmission(true);

  //設定值參考說明書15頁
  //設定加速度感測範圍+-2g
  Wire.beginTransmission(address);
  Wire.write(0x1C); // ACCEL_CONFIG
  Wire.write(0x00);
  Wire.endTransmission(true);
  delay(100);
}

void mpu_read_acc(byte address, int16_t *x, int16_t *y, int16_t *z) {
  Wire.beginTransmission(address);
  Wire.write(0x3B); //加速度感測器暫存器位置
  Wire.endTransmission(false);
  Wire.requestFrom(address, 6, true); //每個數值2Byte，三軸共6Byte
  *x = (Wire.read() << 8 | Wire.read());
  *y = (Wire.read() << 8 | Wire.read());
  *z = (Wire.read() << 8 | Wire.read());
}

void setup() {
  Wire.begin();
  Wire.setClock(400000);
  Serial.begin(115200);
  delay(100);
  //mpu6050_reset(0x68);
  //mpu6050_reset(0x69);
  mpu6050_init(0x68);
//  mpu6050_init(0x69);
}



void loop() {
  passTime = micros() - lastTime;
  if (passTime >= 100000) {
    lastTime=micros();
    
    mpu_read_acc(0x68, &acc_x, &acc_y, &acc_z);
    
    Serial.print(passTime);
    Serial.print(",");
    
    
    Serial.print((float)acc_x / MPU_ACC_CONST);
    Serial.print(",");
    Serial.print((float)acc_y / MPU_ACC_CONST);
    Serial.print(",");
    Serial.print((float)acc_z / MPU_ACC_CONST);
/*    
    mpu_read_acc(0x69, &acc_x, &acc_y, &acc_z);
    
    Serial.print(",");
    Serial.print((float)acc_x / MPU_ACC_CONST);
    Serial.print(",");
    Serial.print((float)acc_y / MPU_ACC_CONST);
    Serial.print(",");
    Serial.print((float)acc_z / MPU_ACC_CONST);

*/    
    Serial.println("");
  }
}
