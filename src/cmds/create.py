import os
import sys
import ConfigParser

from src.parse_dep import parse_ini

class create(object):

    @staticmethod
    def add_cmd(parser_sub, cmd):
        sp = parser_sub.add_parser(cmd)
        sp.add_argument('file', help='Add a settings file', default = None)
        
    def __init__(self, **kwargs):
        ini = os.path.abspath(kwargs['file'])
        if not os.path.exists(ini):
            raise Exception('File does not exist: ', makefile_ini)
        
        self.parse_ini = parse_ini(ini)
        self.run()
        
    def run(self):
        self.write_makefile()
        self.write_yosys()
        self.write_iverilog()
        
    def write_makefile(self):
        print("Creating Makefile from provided settings...")

        makefile = open("Makefile", "w")
        try:
            makefile.write(self.parse_ini.create_makefile())
        finally:
            makefile.close()

        print("Makefile created.")

    def write_yosys(self):
        print("Creating YOSYS script from provided settings...")

        if not os.path.exists("./scripts"):
            os.makedirs("./scripts")

        yosys = open("./scripts/yosys.tcl", "w")
        try:
            yosys.write(self.parse_ini.create_yosys())
        finally:
            yosys.close()

        print("YOSYS script created.")
        
    def write_iverilog(self):
        print("Creating iverilog script from provided settings...")
        
        if not os.path.exists("./scripts"):
            os.makedirs("./scripts")
        
        iverilog = open("./scripts/iverilog.cf", "w")
        try:
            iverilog.write(self.parse_ini.create_iverilog())
        finally:
            iverilog.close()

        print("iverilog script created.")

