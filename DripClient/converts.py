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


# Function convertRemoteKeytoS()
# Purpose: Converts int to Remote Key command.
# Input: An int from 1 to 53
# Output: A string for the key
#---------------------------------------------
def convertRemoteKeytoS(x):
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
            21: 'LIST',      # PVR key
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
            52: 'INTERACTIVE',   # MENU key
            53: 'DEBUG_LOGS'
          }[x]


# Function convertRemoteKeytoI()
# Purpose: Converts Rmt command string to int.
# Input: A string for the keypress
# Output: An int
#---------------------------------------------
def convertRemoteKeytoI(x):
    return {
            'ARROW_RIGHT': 1,
            'MUTE': 2,
            'RED': 3,
            'VOL_DOWN': 4,
            'EXIT': 5,
            'POWER': 6,
            'VOL_UP': 7,
            'GREEN': 8,
            'DIGIT8': 9,
            'DIGIT7': 10,
            'CHAN_UP': 11,
            'YELLOW': 12,
            'PPV': 13,
            'DIGIT9': 14,
            'DIGIT1': 15,
            'CHAN_DOWN': 16,
            'DIGIT2': 17,
            'DIGIT3': 18,
            'BLUE': 19,
            'OPTIONS': 20,
            'LIST': 21,         # PVR key
            'GO_BACK': 22,
            'DIGIT4': 23,
            'LAST_CHAN': 24,
            'DIGIT5': 25,
            'INTERESTS': 26,
            'DIGIT6': 27,
            'ENTER': 28,
            'ARROW_LEFT': 29,
            'GUIDE': 30,
            'HELP': 31,
            'ARROW_DOWN': 32,
            'BROWSE': 33,
            'FAVOURITES': 34,
            'ARROW_UP': 35,
            'DIGIT0': 36,
            'SOURCE': 37,
            'SELECT': 38,
            'INFO': 39,
            'FAST_FWD': 40,
            'REWIND': 41,
            'RECORD': 42,
            'LOCKS': 43,
            'PAUSE': 44,
            'STOP': 45,
            'PLAY': 46,
            'SKIP_AHEAD': 47,
            'SKIP_BACK': 48,
            'ASPECT': 49,
            'INTERACTIVE': 52,    # MENU key
            'DEBUG_LOGS': 53
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

