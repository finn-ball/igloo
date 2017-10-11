class echo(object):

    @staticmethod
    def add_cmd(parser_sub, cmd):
        sp = parser_sub.add_parser(cmd)
        sp.add_argument('echo', help='Send UART message', default = None)
        sp.add_argument('--tty', help='Location of serial connection', default = '/dev/ttyUSB1')
        sp.add_argument('--baud', help='Baud rate', default = 9600)
        sp.add_argument('--timeout', help ='', default = 1, type = int)
        
        
    def __init__(self, **kwargs):
        try:
            import serial
            
        except ImportError:
            raise Exception("Cannot import pySerial, please install")
            
        self.run(kwargs['echo'], kwargs['tty'], kwargs['baud'], kwargs['timeout'])
        
    def run(self, echo, tty, baud, timeout):
    
        import serial
        
        line_size = len(echo)

        print("Opening port...")
        
        with (serial.Serial(tty, baud, timeout=timeout)) as ser:

            if (not ser.is_open):
                ser.open()

            ser.write(echo)
            print("Sending message...")
            
            line = ser.read(line_size)
            ser.close()

        print ("Message recieved:\n" + line)
