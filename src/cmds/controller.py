class _Getch:
    """Gets a single character from standard input.  Does not echo to the
screen."""
    def __init__(self):
        self.impl = _GetchUnix()

    def __call__(self): return self.impl()

class _GetchUnix:
    def __init__(self):
        import tty, sys, termios

    def __call__(self):
        import sys, tty, termios
        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        try:
            tty.setraw(sys.stdin.fileno())
            ch = sys.stdin.read(1)
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
        return ch

class controller(object):

    @staticmethod
    def add_cmd(parser_sub, cmd):
        sp = parser_sub.add_parser(cmd)
        sp.add_argument('--tty', help='Location of serial connection', default = '/dev/ttyUSB1')
        sp.add_argument('--baud', help='Baud rate', default = 9600)

    def __init__(self, **kwargs):
        try:
            import serial
            
        except ImportError:
            raise Exception("Cannot import pySerial, please install")
        
        self.run(kwargs['tty'], kwargs['baud'])

    def run(self, tty, baud):

        print("Press q to quit")
        
        import serial
        
        with (serial.Serial(tty, baud)) as ser:
            
            if (not ser.is_open):
                ser.open()
                
            while True:
                getch = _Getch()
                out = getch()
                print (">>" + out)

                if out == 'q' :
                    break
                else:
                    ser.write(out)
            
        ser.close()

