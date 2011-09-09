int AnalogInputPin = 0; // Define analog input pin
int PowerLedPin = 2; // Power LED on digital pin 2
int calibration = -7; // Calibration offset

void setup(){
  Serial.begin(9600);
  pinMode(PowerLedPin, OUTPUT);
  digitalWrite(PowerLedPin, HIGH);
}

void loop(){
  int maxRawVoltage = maxVoltage();
  currentSensor(maxRawVoltage);
  Serial.print("\n");
  delay(1000);
}

// Find largest current value
int maxVoltage() {
  int MaxADC = 0;
  
  for (int x = 0; x < 300; x++) {
    int RawADC = analogRead(AnalogInputPin) + calibration;
    
    if (RawADC > MaxADC) {
      MaxADC = RawADC;
    }
    
    delay(2); 
  }
  
  return MaxADC;
}

// --------------------------------------------------------------------------------------------------------
// Print decimal numbers
void printDouble(double val, byte precision) {
 Serial.print (int(val));                                     // Print int part
  if( precision > 0) {                                         // Print decimal part
    Serial.print(".");
    unsigned long frac, mult = 1;
    byte padding = precision -1;
    while(precision--) mult *=10;
    if(val >= 0) frac = (val - int(val)) * mult; else frac = (int(val) - val) * mult;
    unsigned long frac1 = frac;
    while(frac1 /= 10) padding--;
    while(padding--) Serial.print("0");
    Serial.print(frac,DEC) ;
  }
}

// Read 1.1V reference against AVcc
long readInternalVcc() {
  long result;
  ADMUX = _BV(REFS0) | _BV(MUX3) | _BV(MUX2) | _BV(MUX1);
  delay(2);                                                    // Wait for Vref to settle
  ADCSRA |= _BV(ADSC);                                         // Convert
  while (bit_is_set(ADCSRA,ADSC));
  result = ADCL;
  result |= ADCH<<8;
  result = 1126400L / result;                                  // Back-calculate AVcc in mV
  return result;
}

// Calculate current with Allegro ACS714
void currentSensor(int RawADC) {
  int    Sensitivity    = 185; // mV/A 185 for 5A, 66 for 30A
  long   InternalVcc    = readInternalVcc();
  double ZeroCurrentVcc = InternalVcc / 2;
  double SensedVoltage  = (RawADC * InternalVcc) / 1024;
  double Difference     = SensedVoltage - ZeroCurrentVcc;  // actual voltage in millivolts
  double SensedCurrent  = Difference / Sensitivity; // actual current in amps
  double RMS = ((Difference * 0.7)/1000)*2;
  //Serial.print("Sensed current (A): ");
  //printDouble(SensedCurrent, 3);
  //Serial.print(" || InternalVCC (mV): ");
  //printDouble(InternalVcc, 3);
  //Serial.print(" || ZeroCurrentVCC (mV): ");
  //printDouble(ZeroCurrentVcc, 3);
  //Serial.print(" || Sensed Voltage (mV): ");
  //printDouble(SensedVoltage, 3);
  //Serial.print(" || Difference (mV): ");
  //printDouble(Difference, 3);  
  //Serial.print(" || RMS (A): ");
  printDouble(RMS, 3);  
  //return SensedCurrent;                                        // Return the Current
}
