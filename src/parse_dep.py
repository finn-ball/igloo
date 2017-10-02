import os
import re
import datetime
import ConfigParser

class parse_ini(object):

    def __init__(self):
        return

    def get_top(self):
        return self._top

    def get_root(self):
        return self._root

    def set_files(self, files):
        self._files = files
    
    def find_deps(self, root, section):        
        path_ini = root + '/cfg/dep.ini' 

        if not os.path.exists(path_ini):
            raise Exception('File does not exist: ', path_ini)
        
        dep_list = []
        path_hdl = root + '/hdl/'
        config = ConfigParser.ConfigParser()
        
        dep_list.append(path_hdl + section)
        config.read(path_ini)
        
        include = config.get(section, 'include')
        include_list = re.split(',| ', include)
        
        for inc in include_list:
            if "/" in inc:
                _root, _section = inc.split("/")
                dep_list.extend(self.find_deps(_root, _section))
            else:
                if inc != "False":
                    dep_list.append(path_hdl + inc)

        return (dep_list)    
        
    def parse_makefile(self, ini):
        makefile_config = ConfigParser.ConfigParser()
        makefile_config.read(ini)
        
        try:
            self._name = makefile_config.get('Project', 'Name')
            self._root = makefile_config.get('Project', 'Root')
            self._device = makefile_config.get('Project', 'Device')
            self._footprint = makefile_config.get('Project', 'Footprint')
            self._top = makefile_config.get('Project', 'Top')
            self._pinmap = makefile_config.get('Project', 'Pinmap' )

        except:
            raise Exception("Settings file could not be parsed")
        

    def create_yosys(self):
        yosys =  ''
        for f in self._files:
            yosys += ('yosys read_verilog %s\n' % f)
            
        yosys += ('yosys synth_ice40 -top %s -blif ./build/%s.blif\n') % (self._top, self._name)
            
        return yosys

    def create_iverilog(self):
        iverilog =  ''
        for f in self._files:
            iverilog += ('-l %s\n' % f)
        
        iverilog += '-l /usr/local/share/yosys/ice40/cells_sim.v\n'
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
TOP          = %s
SIM          = %s
FILES        = %s

BLIF         = $(BUILD)/$(PROJ).blif
ASC          = $(BUILD)/$(PROJ).asc
BIN          = $(BUILD)/$(PROJ).bin
PINMAP       = ./boards/$(DEVICE)$(FOOTPRINT)/%s\n""" % (self._time,
                                                         self._name,
                                                         self._device,
                                                         self._footprint,
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
