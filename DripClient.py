#!/usr/bin/python
import socket
import sys
import time
import threading
import binascii
import struct
import zlib
import random

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

# Function convertStatusToString()
# Purpose: Converts Status hex value to string.
# Input: Status hex value
# Output: String
#---------------------------------------------
def convertStatusToString(x):
    return {
        '0000' : 'OK',
        '0100' : 'BAD_CRC',
        '0200' : 'BAD_LENGTH',
        '0300' : 'BAD_IP_MSG',
        '0400' : 'NO_MATCH_UA',
        '0500' : 'BAD_TID',
        '0600' : 'NA'
        }[x]


# Function convertMsgTypeToString()
# Purpose: Converts MsgType value to string.
# Input: Number from 1-12
# Output: String
#---------------------------------------------
def convertMsgTypeToString(x):
    return {
        1 : 'RMT',
        2 : 'DIAG',
        3 : 'IP_ADDR',
        4 : 'MSP_MSG',
        5 : 'REBOOT',
        6 : 'BOOT_PARAMS',
        7 : 'FRONT_PANEL',
        8 : 'LAST_REPORT',
        9 : 'MSG_TYPE_STATS',
        10 : 'MSG_TYPE_DEBUG',
        11 : 'NEPTUNE_TEST',
        12 : 'UNSOLICITED'
    }[x]


# Function convertRemoteKey()
# Purpose: Converts int to Remote Key command.
# Input: An int from 1 to 53
# Output: A string for the key
#---------------------------------------------
def convertRemoteKey(x):
    return {
	      1: 'ARROW_RIGHT',
	      2: 'MUTE',
	      3: 'RED',
	      4: 'VOL_DOWN',
	      5: 'EXIT',
	      6: 'POWER',
	      7: 'VOL_UP',
	      8: 'GREEN',
	      9: 'DIGIT8',
	      10: 'DIGIT7',
	      11: 'CHAN_UP',
	      12: 'YELLOW',
	      13: 'PPV',
	      14: 'DIGIT9',
	      15: 'DIGIT1',
	      16: 'CHAN_DOWN',
	      17: 'DIGIT2',
	      18 :'DIGIT3',
	      19: 'BLUE',
	      20: 'OPTIONS',
	      21: 'LIST',
	      22: 'GO_BACK',
	      23: 'DIGIT4',
	      24: 'LAST_CHAN',
	      25: 'DIGIT5',
	      26: 'INTERESTS',
	      27: 'DIGIT6',
	      28: 'ENTER',
	      29: 'ARROW_LEFT',
	      30: 'GUIDE',
	      31: 'HELP',
	      32: 'ARROW_DOWN',
	      33: 'BROWSE',
	      34: 'FAVOURITES',
	      35: 'ARROW_UP',
	      36: 'DIGIT0',
	      37: 'SOURCE',
	      38: 'SELECT',
	      39: 'INFO',
	      40: 'FAST_FWD',
	      41: 'REWIND',
	      42: 'RECORD',
	      43: 'LOCKS',
	      44: 'PAUSE',
	      45: 'STOP',
	      46: 'PLAY',
	      47: 'SKIP_AHEAD',
	      48: 'SKIP_BACK',
	      49: 'ASPECT',
	      52: 'INTERACTIVE',
	      53: 'DEBUG_LOGS'
          }[x]


# Function convertDiagCommand()
# Purpose: Converts string to value.
# Input: Diag Screen Name
# Output: Diag Screen value
#---------------------------------------------
def convertDiagCommand(x):
    return {
            'A' : 1,
            'B' : 2,
            'C' : 3,
            'D' : 4,
            'D2' : 5,
            'E1' : 6,
            'E2' : 7,
            'F' : 8,
            'R' : 9,
            'A2' : 10,
            'CS' : 11,
            'D3' : 12
          }[x]

# Function convertSeaCommand()
# Purpose: Converts string to hex value.
# Input: String for the debug module.
# Output: Hex value for the debug module.
#---------------------------------------------
def convertSeaCommand(x):
    return {
            'none' : 0,
            'ts' : 0x00000001,
            'ni' : 0x00000002,   # Network Interface
            'dm' : 0x00000004,   # Demux & HAL Demux
            'sf' : 0x00000008,   # Section Filter

            'ca' : 0x00000010,   # Conditional Access
            'sp' : 0x00000020,   # Secure Processor
            'cp' : 0x00000040,   # Component Presenter
            'rm' : 0x00000080,   # Resource Manager

            'si' : 0x00000100,   # System Information
            'fm' : 0x00000200,   # File Manager
            'ut' : 0x00000400,   # Utilities
            'sys' : 0x00000800,  # System

            'mp' : 0x00001000,   # Message Parser
            'dl' : 0x00002000,   # Download
            'os' : 0x00004000,   # Operating System - RTOS
            'tu' : 0x00008000,   # Tuner

            'spi' : 0x00010000,  # Serial Peripheral Interface
            'vi' : 0x00020000,   # Video
            'au' : 0x00040000,   # Audio
            'fp' : 0x00080000,   # Front Panel

            'dvr' : 0x00100000,  # Digital Video Recording
            'cc' : 0x00200000,   # Close Captions
            'st' : 0x00400000,   # Streamer
            'sc' : 0x00800000,   # System Control

            'osd' : 0x01000000,  # On Screen Display
            'ply' : 0x02000000,  # Player
            'init' : 0x04000000, # Initialization
            'cm' : 0x08000000,   # Content Manager

            'hwc' : 0x10000000,  # Hardware Config
            'hls' : 0x20000000,  # HLS
            'all' : 0x3fffffff
          }[x]



# Function handleCommand()
# Purpose: Handles the 'wait' and 'send' commands from DRIP scripts.
#          Also handles msp, sea and ses commands.
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
     apps = map(convertSeaCommand, wordlist[1:])  # app flags list
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
     msgValues.append(convertDiagCommand(wordlist[1]))
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

   # send command
   # Note: From Drip script generated by windows Drip client program
   elif 'send' in wordlist:
     firstInt = int(wordlist[1])
     secondInt = int(wordlist[2])

     # Handle RCU Keypresses
     # e.g., send 1,33 -->  0 1 0 21 0 1 19 c4   Remote key 3
     if firstInt == 1 :  # RCU Keypress Commands
       print convertMsgTypeToString(firstInt), convertRemoteKey(secondInt)
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
       STATUS_STR = convertStatusToString(STATUS)
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
    print('Run a DRIP Script ')
    print('Useage: python DripClient.py /f filename /i ip_address /l num_loops /b binding_address /o outfn')
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

