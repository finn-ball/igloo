import os
import sys
import ConfigParser
from collections import OrderedDict

from src.parse_dep import parse_ini

class create(object):

    @staticmethod
    def add_cmd(parser_sub, cmd):
        sp = parser_sub.add_parser(cmd)
        sp.add_argument('file', help='Add a settings file', default = None)
        
    def __init__(self, **kwargs):
        self.parse_ini = parse_ini()
        self.run(kwargs['file'])
        
    def run(self, file_path):

        makefile_ini = os.path.abspath(file_path)
        
        if not os.path.exists(makefile_ini):
            raise Exception('File does not exist: ', makefile_ini)

        self.parse_ini.parse_makefile(makefile_ini)

        root = self.parse_ini.get_root()
        top = self.parse_ini.get_top() + '.v'
        
        dep_list = OrderedDict.fromkeys(self.parse_ini.find_deps(root, top)).keys()
        self.parse_ini.set_files(dep_list)

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
        
        yosys = open("./scripts/yosys.tcl", "w")
        try:
            yosys.write(self.parse_ini.create_yosys())
        finally:
            yosys.close()

        print("YOSYS script created.")
        
    def write_iverilog(self):

        print("Creating iverilog script from provided settings...")
        
        iverilog = open("./scripts/iverilog.cf", "w")
        try:
            iverilog.write(self.parse_ini.create_iverilog())
        finally:
            iverilog.close()

        print("iverilog script created.")

