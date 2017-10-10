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
        file_l = []
        incs_l = []
        
        for f in self.dep_map:
            file_l.append(self.dep_map[f]["path"] + f)
            if "include" in self.dep_map[f]:
                incs = re.split(', | |,', self.dep_map[f]['include'])
                for inc in incs:
                    incs_l.append(inc)
                    
        self._files = file_l
        self._includes = list(OrderedDict.fromkeys(incs_l))
    
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

        except:
            raise Exception("Settings file could not be parsed")

        self._device_family = ''
        print self._device
        
        if (self._device == 'lp384'):
            self._device_family = "384"
            
        elif (self._device == 'lp1k' or self._device == 'hx1k'):
            self._device_family = "1k"
            
        elif (self._device == 'lp8k' or self._device == 'hx8k'):
            self._device_family = "8k"
        

    def create_yosys(self):
        yosys =  ''
        
        for f in self.dep_map:
            yosys_includes = ''
            if "include" in self.dep_map[f]:
                incs = re.split(', | |,', self.dep_map[f]['include'])
                for inc in incs:
                    yosys_includes += '-I%s' % inc
                
            yosys += ('yosys read_verilog -sv %s %s\n' % (yosys_includes , self.dep_map[f]['path'] + f))
            
        yosys += ('yosys synth_ice40 -top %s -blif ./build/%s.blif\n') % (self._top, self._name)
            
        return yosys

    def create_iverilog(self):
        iverilog =  ''
        inc_list = []

        for f in self._files:
            iverilog += ('-l %s\n' % f)

        iverilog += '-l /usr/local/share/yosys/ice40/cells_sim.v\n'
        for i in self._includes:
            iverilog += '+incdir+' + i + '\n'

        iverilog += '+libext+.v+.vl+.vh\n'
        iverilog += (self._root + '/sim/' + self._top + '_tb.v\n')
        return iverilog

    def create_makefile(self):
        self._time = '#Created by igloo\n#{:%d-%m-%Y %H:%M:%S}\n'.format(datetime.datetime.now())
        makefile_constants ="""%s
SHELL:=/bin/bash

PROJ          = %s
BUILD         = ./build
SCRIPTS       = ./scripts
DEVICE_FAMILY = %s
DEVICE        = %s
FOOTPRINT     = %s
BOARD         = %s
TOP           = %s
SIM           = %s
INCLUDES      = %s
FILES         = %s

BLIF          = $(BUILD)/$(PROJ).blif
ASC           = $(BUILD)/$(PROJ).asc
BIN           = $(BUILD)/$(PROJ).bin
PINMAP        = ./boards/$(BOARD)/%s.pcf\n""" % (self._time,
                                                 self._name,
                                                 self._device_family,
                                                 self._device,
                                                 self._footprint,
                                                 self._board,
                                                 (self._root + '/hdl/' + self._top + '.v'),
                                                 (self._root + '/sim/' + self._top + '_tb.v'),
                                                 (" ".join(self._includes)),
                                                 (" ".join(self._files)),
                                                 self._name)

        makefile_bulk = """
YOSYS_FLAGS    = -Q -c $(SCRIPTS)/yosys.tcl
ARACHNE_FLAGS  = -d $(DEVICE_FAMILY) -P $(FOOTPRINT) -o $(ASC) -p $(PINMAP) $(BLIF)

ICETIME_FLAGS  = -mit -d $(DEVICE) -p $(PINMAP) 

IVERILOG_BUILD = $(BUILD)/iverilog
VVP            = $(IVERILOG_BUILD)/$(PROJ).vvp
IVERILOG_FLAGS = -Wall -c $(SCRIPTS)/iverilog.cf -o $(VVP) #-Wfloating-nets

.PHONY: all clean burn iverilog iverilog_monitor

all: $(BIN)

$(BLIF): $(FILES) 
	mkdir -p $(BUILD)/logs
	yosys $(YOSYS_FLAGS) &> $(BUILD)/logs/yosys.log

$(ASC): $(BLIF)
	arachne-pnr $(ARACHNE_FLAGS) &> $(BUILD)/logs/archane-pnr.log

$(BIN): $(ASC)
	icepack $(ASC) $(BIN) &> $(BUILD)/logs/icepack.log

burn:
	iceprog $(BIN) &> $(BUILD)/logs/icetime.log

time: $(ASC)
	icetime $(ICETIME_FLAGS) $(ASC)

iverilog: $(SIM) $(FILES)
	mkdir -p $(IVERILOG_BUILD)
	iverilog $(IVERILOG_FLAGS)

iverilog_monitor:	
	-@make iverilog
	@echo "Files watched: " $(SIM) $(FILES)
	@while [[ 1 ]]; do inotifywait -e modify $(SIM) $(FILES); make iverilog; done

gtkwave: iverilog
	vvp $(VVP)

gtkwave_monitor:
	-@make gtkwave
	@echo "Files watched: " $(SIM) $(FILES)
	@while [[ 1 ]]; do inotifywait -e modify $(SIM) $(FILES); make gtkwave; done

clean:
	rm -rf $(BUILD)/* """

        return (makefile_constants + makefile_bulk)
