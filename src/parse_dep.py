import os
import re
import datetime
import ConfigParser
from collections import OrderedDict

class parse_ini(object):

    def __init__(self, file_path):
        ini_options = ["include"]

        self.parse_makefile(file_path)

        self.dep_map = self.flatten_ini_tree(self._root, (self._top + '.v'), 'deps', ini_options)
        
        self.set_files()
    
    def set_files(self):
        l = []
        for f in self.dep_map:
            l.append(self.dep_map[f]["path"] + f)
        
        self._files = l
    
    def flatten_ini_tree(self, root, section, option, ini_options):        
        config = ConfigParser.SafeConfigParser()
        hdl_dir = root + '/hdl/'
        ini_path = root + '/cfg/dep.ini'
        options_dict = {}
        return_dict = OrderedDict()
        
        if not os.path.exists(ini_path):
            raise Exception('File does not exist: ', ini_path)
        
        config.read(ini_path)

        options_dict["path"] = hdl_dir
        return_dict[section] = options_dict

        if (not config.has_section(section)):
            return return_dict

        for opt in ini_options:
            if (config.has_option(section, opt)):
                options_dict[opt] = config.get(section, opt)

        return_dict[section] = options_dict
        
        if (not config.has_option(section, option)):
            return return_dict

        deps = re.split(', | |,', config.get(section, option))
        
        for dep in deps:
            if "/" in dep:
                _root, _section = dep.split("/")
                return_dict.update(self.flatten_ini_tree(_root, _section, option, ini_options))
            else:
                
                _section = dep
                _root = root
                return_dict.update(self.flatten_ini_tree(_root, _section, option, ini_options))
        
        return return_dict
        
    def parse_makefile(self, ini):
        makefile_config = ConfigParser.ConfigParser()
        makefile_config.read(ini)
        
        try:
            self._name = makefile_config.get('Project', 'Name')
            self._root = makefile_config.get('Project', 'Root')
            self._device = makefile_config.get('Project', 'Device')
            self._footprint = makefile_config.get('Project', 'Footprint')
            self._board = makefile_config.get('Project', 'Board')
            self._top = makefile_config.get('Project', 'Top')
            self._pinmap = makefile_config.get('Project', 'Pinmap' )

        except:
            raise Exception("Settings file could not be parsed")
        

    def create_yosys(self):
        yosys =  ''
        yosys_includes = ''

        for f in self.dep_map:
            if "include" in self.dep_map[f]:
                incs = re.split(', | |,', self.dep_map[f]['include'])
                for inc in incs:
                    yosys_includes += '-I%s' % inc
                    
            yosys += ('yosys read_verilog %s %s\n' % (yosys_includes , self.dep_map[f]['path'] + f))
            
        yosys += ('yosys synth_ice40 -top %s -blif ./build/%s.blif\n') % (self._top, self._name)
            
        return yosys

    def create_iverilog(self):
        iverilog =  ''

        for f in self._files:
            iverilog += ('-l %s\n' % f)

        iverilog += '-l /usr/local/share/yosys/ice40/cells_sim.v\n'
        for f in self.dep_map:
            if "include" in self.dep_map[f]:
                incs = re.split(', | |,', self.dep_map[f]['include'])
                for inc in incs:
                    iverilog += '+incdir+' + inc + '\n'
        iverilog += '+libext+.v+.vl+.vh\n'
        iverilog += (self._root + '/sim/' + self._top + '_tb.v\n')
        return iverilog

    def create_makefile(self):
        self._time = '#Created by igloo\n#{:%d-%m-%Y %H:%M:%S}\n'.format(datetime.datetime.now())
        makefile_constants ="""%s
SHELL:=/bin/bash

PROJ         = %s
BUILD        = ./build
SCRIPTS      = ./scripts
DEVICE       = %s
FOOTPRINT    = %s
BOARD        = %s
TOP          = %s
SIM          = %s
FILES        = %s

BLIF         = $(BUILD)/$(PROJ).blif
ASC          = $(BUILD)/$(PROJ).asc
BIN          = $(BUILD)/$(PROJ).bin
PINMAP       = ./boards/$(BOARD)/%s\n""" % (self._time,
                                            self._name,
                                            self._device,
                                            self._footprint,
                                            self._board,
                                            (self._root + '/hdl/' + self._top + '.v'),
                                            (self._root + '/sim/' + self._top + '_tb.v'),
                                            (" ".join(self._files)),
                                            self._pinmap)

        makefile_bulk = """
YOSYS_FLAGS    = -Q -c $(SCRIPTS)/yosys.tcl
ARACHNE_FLAGS  = -d $(DEVICE) -P $(FOOTPRINT) -o $(ASC) -p $(PINMAP) $(BLIF)

IVERILOG_BUILD = $(BUILD)/iverilog
VVP            = $(IVERILOG_BUILD)/$(PROJ).vvp
IVERILOG_FLAGS = -Wall -c $(SCRIPTS)/iverilog.cf -o $(VVP) #-Wfloating-nets

.PHONY: all clean burn iverilog iverilog_monitor

all: $(BIN)

$(BLIF): $(FILES) 
	mkdir -p $(BUILD)
	yosys $(YOSYS_FLAGS) &> $(BUILD)/yosys.log

$(ASC): $(BLIF)
	arachne-pnr $(ARACHNE_FLAGS) &> $(BUILD)/archane-pnr.log

$(BIN): $(ASC)
	icepack $(ASC) $(BIN) &> $(BUILD)/icepack.log

burn:
	iceprog $(BIN)

iverilog: $(SIM) $(FILES)
	mkdir -p $(IVERILOG_BUILD)
	iverilog $(IVERILOG_FLAGS)

iverilog_monitor:	
	-@make iverilog
	@echo "Files watched: " $(SIM) $(FILES)
	@while [[ 1 ]]; do inotifywait -e modify $(SIM) $(FILES); make iverilog; done

clean:
	rm -rf $(BUILD)/* """

        return (makefile_constants + makefile_bulk)
