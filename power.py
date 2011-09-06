import serial
import json
import re
import time
from decimal import *

def pollArduino():
	''' Returns value in amps from Arduino Current Sensor'''
	ser = serial.Serial('/dev/ttyUSB0', 9600, timeout=1)

	# For reasons I'm not sure of, every other line from the Arduino is blank
	# so grab 3 lines and one of them should be okay.
	for x in range(3):
		line = ser.readline()
		if line:
			result = line.split('\n')[0]
			result = re.sub(r'[^\w]', '', result)

	ser.close()

	return Decimal(result) / 1000

def tvstatus(amps):
	''' Decide if TV power is off or on '''

	# If the Arduino reports more than 0.25 Amps, the TV is on.
	threshold = Decimal("0.25")

	if amps >= threshold:
		# TV is on
		return True
	else:
		return False


if __name__ == "__main__":
	# And lets try it out.  Every 5 seconds report the amperage.
	while True:
		try:
			amps = pollArduino()
			wattage = amps * 110

			if tvstatus(amps):
				print "TV is on (%s A, %s W)" % (amps, wattage)
			else:
				print "TV is off (%s A, %s W)" % (amps, wattage)

		except serial.serialutil.SerialException:
			print "Couldn't connect to Arduino. I'm super serial."

		time.sleep(5)
