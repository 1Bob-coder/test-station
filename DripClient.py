#!/usr/bin/python
import socket
import sys
import time
import threading
import binascii
import struct
import zlib
import random
import converts


# Initialized variables
global xyz_needed
global xyz_values
global vctid_needed
global vctid_value
xyz_needed = True
xyz_values = []
vctid_needed = True
vctid_value = 0
outfname = 'none'
crc32 = [0, 0, 0, 0]  # crc32 padding of 4 bytes



# Function handleCommand()
# Purpose: Handles the 'wait' and 'send' commands from DRIP scripts.
#          Also handles diag, rmt, msp, sea and ses commands.
# Input: A string of the following form (example):
#        wait 3000  (for 3000 ms)
#        send 1 23  (for remote, DRIP key 23)
#        msp 96 00 0c 00 01 80 33 ff ff ff 01  (for fingerprint)
#        sea 00 00 08 00   (for sea 0x800)
#        ses 3   (for ses 3)
#---------------------------------------------
def handleCommand( wordStr ):
   # split the string into a list
   wordlist = wordStr.split()

   # wait command in milliseconds
   if 'wait' in wordlist:
     waitTime = float(wordlist[1])
     print "pause", waitTime, "ms"
     time.sleep(waitTime/1000.0)

   # The Drip command message is composed of the following bytes:
   # type : 16 bits (RMT, RECORD, DIAG, etc.)
   # id   : 16 bits (returned unchanged from DRIP server)
   # len  : 16 bits (length of body)
   # body : len*8 bits
   # cs   : 8 bits (simple two's complement of the sum of bytes)

   # msp command, e.g., msp:96,00,0c,00,02,80,33,ff,ff,ff,01
   # sends --> 0 4 0 0 0 f 96 00 0c 00 02 80 33 ff ff ff 01 cs
   elif 'msp' in wordlist:
     print(' '.join(wordlist))
     msgValues = [0, 0, 0, 0, 0, 0]
     msgValues[1] = 4                      # MSP_MSG

     # convert message strings to ints, skip first string in wordlist
     body = map(lambda x: int(x,16), wordlist[1:])
     msgValues[5] = len(body) + 4  # message length of body + crc32
     msgValues.extend(body)
     msgValues.extend(crc32)
     sendMsgToServer(msgValues)  # Send msg to Drip server

   # sea command, e.g., sea:sys,si,osd
   # sends --> 0 a 0 0 0 5 1 1 0 9 0 cs (len=5, type=1, body=01 00 09 00)
   elif 'sea' in wordlist:
     print(' '.join(wordlist))
     msgValues = [0, 0, 0, 0, 0, 0]
     msgValues[1] = 0xa                    # MSG_TYPE_DEBUG
     msgValues[5] = 5                      # message length of body
     msgValues.append(1)                   # message type = 1 for sea
     apps = map(converts.convertSeaCommand, wordlist[1:])  # app flags list
     res = reduce(lambda x, y: x | y, apps)       # OR all the app flags
     b = struct.unpack("4b", struct.pack("!I", res))
     msgValues.extend(map(lambda x: x & 0xff, b)) # get rid of the negative signs
     sendMsgToServer(msgValues)  # Send msg to Drip server

   # ses command, e.g., ses:3
   # sends --> 0 a 0 0 0 2 2 3 cs (len=2, type=2, body=3)
   elif 'ses' in wordlist:
     print(' '.join(wordlist))
     msgValues = [0, 0, 0, 0, 0, 0]
     msgValues[1] = 0xa                    # MSG_TYPE_DEBUG
     msgValues[5] = 2                      # message length of body
     msgValues.append(2)                   # message type = 2 for ses
     msgValues.append(int(wordlist[1]))    # severity
     sendMsgToServer(msgValues)  # Send msg to Drip server

   # diag command, e.g., diag:A,1,1
   # sends --> 0 2 0 0 0 3 1 1 1 cs (len=3, A=1, line=1, item=1)
   elif 'diag' in wordlist:
     print(' '.join(wordlist))
     msgValues = [0, 0, 0, 0, 0, 0]
     msgValues[1] = 2                      # DIAG
     msgValues[5] = len(wordlist[1:])      # message length of body
     msgValues.append(converts.convertDiagCommand(wordlist[1]))
     msgValues.extend(map(lambda x: int(x,16), wordlist[2:]))
     sendMsgToServer(msgValues)  # Send msg to Drip server

   # vco command, e.g., vco:60,66,64109,2,784
   # Where: 60     duration in seconds
   #        66     the channel being redefined
   #        64109  source ID
   #        2      transponder number
   #        784    service number
   # Note:  Immediate activation, circle test preamble included.
   #        Diag A must be called prior to get XYZ and VCT_ID values
   elif 'vco' in wordlist:
     print(' '.join(wordlist))
     msgValues = [0, 0, 0, 0, 0, 0]
     msgValues[1] = 4                      # MSP_MSG

     # convert message strings to ints, skip first string in wordlist
     body = map(lambda x: int(x), wordlist[1:])

     # The following are for VCO's with circle test, radius 0x19.
     msgValues.extend([0x92, 0x00, 0x34, 0x20, 0x16, 0x00, 0x00, 0x13, 0x0e,
         0xee, 0xee, 0xee, 0xee, 0xee, 0xee, 0xee, 0xee, 0xee, 0x01, 0x40, 0x19])
     global xyz_values
     global vctid_value
     msgValues.extend(xyz_values)                 # add the xyz_values from Diag A
     msgValues.extend([0x00, 0x00, 0x00, 0x45, 0x0e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
     msgValues.append(body[0])                    # duration
     msgValues.append((vctid_value >> 8) & 0xff)  # add the VCT_ID from Diag A
     msgValues.append(vctid_value & 0xff)
     msgValues.append((body[1] >> 8) & 0xff)      # VCN
     msgValues.append((body[1]) & 0xff)
     msgValues.append(0x40)
     msgValues.append((body[2] >> 8) & 0xff)      # source id
     msgValues.append((body[2]) & 0xff)
     msgValues.append(97)                         # satellite = 97
     msgValues.append(body[3])                    # transponder number
     msgValues.append((body[4] >> 8) & 0xff)      # service number
     msgValues.append((body[4]) & 0xff)
     msgValues.extend(crc32)
     msgValues[5] = len(msgValues)-6
     sendMsgToServer(msgValues)  # Send msg to Drip server

   # rmt command, e.g., rmt:DIGIT3
   # sends --> 0 1 0 0 0 1 12 cs (len=1, type=1, body=18)
   elif 'rmt' in wordlist:
       msgValues = [0, 0, 0, 0, 0, 0, 0]
       msgValues[1] = 1    # RMT
       msgValues[5] = 1    # body length
       msgValues[6] = converts.convertRemoteKeytoI(wordlist[1])
       sendMsgToServer(msgValues)

   # send command
   # Note: From Drip script generated by windows Drip client program
   elif 'send' in wordlist:
     firstInt = int(wordlist[1])
     secondInt = int(wordlist[2])

     # Handle RCU Keypresses
     # e.g., send 1,33 -->  0 1 0 21 0 1 19 c4   Remote key 3
     if firstInt == 1 :  # RCU Keypress Commands
       print converts.convertMsgTypeToString(firstInt), converts.convertRemoteKeytoS(secondInt)
       msgValues = [0, 0, 0, 0, 0, 0]
       msgValues[1] = 1             # RMT
       msgValues[5] = 1             # Body length = 1
       msgValues.append(secondInt)  # Body = keycode

       # Handle Unsolicited Enable message.
       # e.g., send:1,53 -->  0 c 0 16 0 1 1 dc  Unsolicited Enable
       if secondInt == 53:  # Unsolicited Message
           msgValues = [0, 0, 0, 0, 0, 0]
           msgValues[1] = 12   # UNSOLICITED
           msgValues[5] = 1    # Body length = 1
           msgValues.append(1) # Enable = 1
       sendMsgToServer(msgValues)  # Send msg to Drip server

     #  Handle the reboot command
     #  e.g., send:22,2 --> 0 5 0 17 0 0 e4  Reboot Command
     if firstInt == 22:
       msgValues = [0, 0, 0, 0, 0, 0]
       msgValues[1] = 5  # REBOOT
       sendMsgToServer(msgValues)  # Send msg to Drip server

     #  Handle the Diag Info requests
     # e.g., send:5,14 --> 0 2 0 2 0 2 1 1 f8  Diag A.1 Request
     # e.g., send:5,15 --> 0 2 0 3 0 2 1 2 f6  Diag A.2 Request
     if firstInt == 5:
       msgValues = [0, 0, 0, 0, 0, 0]
       msgValues[1] = 2        # DIAG
       msgValues[5] = 2        # Body length = 2
       msgValues.append(1)     # Diag Screen A
       if secondInt == 14:
           msgValues.append(1) # Diag screen line 1
       elif secondInt == 15:
           msgValues.append(2) # Diag screen line 2
       sendMsgToServer(msgValues)  # Send msg to Drip server
   return


# Function recvLoop()
# Purpose: Handles the recv command.  Blocking call, so in a separate task.
# Input: None
#---------------------------------------------
def recvLoop( ):
  while True:
    data = sock.recv(1024)
    TYPE = data[0:2]
    ID = data[2:4]
    STATUS = data[4:6]
    LENGTH = data[6:8]
    STATUS = STATUS.encode('hex')
    LENGTH = LENGTH.encode('hex')
    bodyLen = int(LENGTH,16)
    if bodyLen == 0:
       STATUS_STR = converts.convertStatusToString(STATUS)
       print "  >>>>", STATUS_STR
    if bodyLen > 0:
       print " ", data[8:8+bodyLen]
       # Save output to outfname, if specified.
       if outfname is not 'none':
           with open(outfname, 'a+') as f:
               f.write(data[8:8+bodyLen] + '\n')
           f.close()
       global xyz_needed
       if xyz_needed:  # Check if we need to save the xyz coordinates.
           getXYZ(data[8:8+bodyLen])
       if vctid_needed: # Check if we need to save the VCT_ID
           getVCT_ID(data[8:8+bodyLen])
  return


# Function getXYZ()
# Purpose: Looks for the XYZ coordinates in the message body and saves them if
#          found.
# Input: The received message from the Drip server.  This is a list of bytes.
#---------------------------------------------
def getXYZ( dataList ):
    line = "".join(dataList) # join list of chars into a single line
    wordstr = line.split()   # split line into list of word strings
    if 'XYZ' in wordstr:
        # Data will be of the form
        # XYZ = 0xc96 0x5f4 0xe39
        # Skip 2 values ('XYZ' and '=') and get the next 3 values.
        xyzIndex = wordstr.index('XYZ')
        tempList = map(lambda x: int(x,0), wordstr[xyzIndex+2:xyzIndex+5])
        global xyz_values
        global xyz_needed
        xyz_values = []
        for x in tempList:
            xyz_values.append((x >> 8) & 0xff)
            xyz_values.append(x & 0xff)
        print "save xyz values", map(lambda x: hex(x), xyz_values)
        xyz_needed = False
    return


# Function getVCT_ID()
# Purpose: Looks for the VCT_ID value in the message body and saves if found.
# Input: The received message from the Drip server.  This is a list of bytes.
#---------------------------------------------
def getVCT_ID( dataList ):
    line = "".join(dataList) # join all chars into a single line
    wordstr = line.split()   # split line into list of word strings
    if 'VCT_ID' in wordstr:
        global vctid_value
        global vctid_needed
        # Data will be of the form
        # VCT_ID = 4188,
        # Skip 2 values ('VCT_ID' and '=') and get the next value.
        vctidIndex = wordstr.index('VCT_ID')
        vctid_value = wordstr[vctidIndex+2:vctidIndex+3]
        vctid_value = vctid_value[0].replace(',',' ')  # get rid of any commas
        vctid_value = int(vctid_value)
        print "save vct_id value", vctid_value
        vctid_needed = False
    return


# Function sendMsgToServer()
# Purpose: Calculates the checksum and sends message to Drip server.
# Input: The list of bytes to send.
#---------------------------------------------
def sendMsgToServer( values ):
    # Calculate the checksum
    cs = reduce(lambda x,y: (x-y) & 0xff, values)
    values.append(cs)

    # Send command to DRIP Server
    arr = bytearray(values)
    sock.sendto(arr, (UDP_IP, UDP_PORT))
    return


# Main entry point
# Function: Parse a DRIP script and execute it.  Allows DRIP Scripts to be
# executed in Linux using Python.
# Inputs:  Filename of the DRIP Script
# Note:  The DRIP Script is created by the DRIP Client program.
#---------------------------------------------
length = int(len(sys.argv))
if length == 1 :
    print('Purpose: Run a DRIP Script ')
    print('         This Drip Client program can be used in automated testing.')
    print('         Note: Requires Python installed on machine.')
    print('Useage:  python DripClient.py /f filename /i ip_address /l num_loops /b binding_address /o outfn')
    print('  where filename is any DRIP script file recorded by the DRIP_Client program')
    print('        ip_address is of the form 192.168.1.56 and is the ip address of the box')
    print('        num_loops is the number of loops (1 by default)')
    print('        binding_address is the address of the NIC card, if applicable')
    print('        outfn is the output filename')


else:
    fname = ' '
    outfname = 'none'
    UDP_IP = ' '
    UDP_PORT = 5002 # number
    BIND_ADDR = ' '
    loops = 1
    x = 1
    comment = True

    while x < length:
        if sys.argv[x] == '/f' or sys.argv[x] == '/F':
            fname = sys.argv[x+1]
            print 'Filename =', fname
        if sys.argv[x] == '/i' or sys.argv[x] == '/I':
            UDP_IP = sys.argv[x+1]
            print 'IP Address =', UDP_IP
        if sys.argv[x] == '/l' or sys.argv[x] == '/L':
            loops = int(sys.argv[x+1])
            print 'Number of Loops =', loops
        if sys.argv[x] == '/b' or sys.argv[x] == '/B':
            BIND_ADDR = sys.argv[x+1]
            print 'Bind Address =', BIND_ADDR
        if sys.argv[x] == '/o' or sys.argv[x] == '/O':
            outfname = sys.argv[x+1]
            print 'Output Filename =', outfname
        x = x+1

    # Make UDP Socket.
    sock = socket.socket(socket.AF_INET, # Internet
                         socket.SOCK_DGRAM) # UDP

    # Bind if needed.
    if BIND_ADDR != ' ':
        sock.bind( (BIND_ADDR, 0) )

    # Launch recvLoop() in a separate thread because it blocks on recv().
    t = threading.Thread(target=recvLoop)
    t.daemon = True
    t.start()

    # Read DRIP test script line by line.
    while loops:
      with open(fname,'r') as f:
        for line in f:
          if '#' in line:
            if not comment:
              time.sleep(2)  # short pause before printing out the comment line
            print(line.rstrip())
            comment = True
          else:
            if comment:
               comment = False
            # Split string in the space.  Makes two strings.
            for wordstr in line.split():
               # Change separation characters into spaces.
               wordstr = wordstr.replace(':',' ')
               wordstr = wordstr.replace(',',' ')
               wordstr = wordstr.replace('.','')
               wordstr = wordstr.replace(';',' ')
               # Send to handler
               handleCommand(wordstr)
      loops = loops - 1
      print 'Loops remaining =', loops
      f.close()

