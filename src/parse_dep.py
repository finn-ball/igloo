import os
import re
import datetime
import ConfigParser
from collections import OrderedDict

class parse_ini(object):

    def __init__(self, file_path):

        self.parse_makefile(file_path)

        self.dep_map = self.flatten_dep_tree(self._root, (self._top + '.v'))
        
        self.set_files()

    def set_files(self):

        file_l = []
        incs_l = []
        root = ""

        for k,v in self.dep_map.iteritems():
            file_l.append(k)
            for i in v:
                if isinstance(i, dict):
                    for options, j in i.iteritems():
                        if options == 'includes':
                            incs_l.append(j[0])
        
        self._files = file_l
        self._includes = set(incs_l)
        
    def flatten_dep_tree(self, root, section):
        
        config = ConfigParser.SafeConfigParser()
        ini_path = root + '/cfg/dep.ini'
        if not os.path.exists(ini_path):
            raise Exception('File does not exist: ', ini_path)

        config.read(ini_path)

        file_path = root + '/hdl/' + section
        
        return_dict = OrderedDict()
        return_dict[file_path] = OrderedDict()
        options_dict = OrderedDict()
        options_list = []
        
        if (config.has_section(section)):
            
            for option in config.options(section):
                contents = re.split(', | |,', config.get(section, option))
                incl_list = []
                for cont in contents:
                    _root = ""
                    _section = ""
                    _file_path = ""
                    
                    if "/" in cont:
                        _root, _section = cont.rsplit("/", 1)
                    else:
                        _section = cont
                        _root = root

                    if option == 'deps':
                        _file_path = _root + '/hdl/' +_section
                        return_dict[_file_path] = OrderedDict()
                        return_dict.update(self.flatten_dep_tree(_root, _section))

                    if option == 'includes':
                        incl_list.append(_root + '/include/' + _section)
                    
                if option == 'includes':
                    incl_dict = OrderedDict()
                    incl_dict['includes'] = incl_list
                    options_list.append(incl_dict)

        options_dict = OrderedDict()
        options_dict[file_path] = options_list
        
        return_dict.update(options_dict)
        
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
        
        if (self._device == 'lp384'):
            self._device_family = "384"
            
        elif (self._device == 'lp1k' or self._device == 'hx1k'):
            self._device_family = "1k"
            
        elif (self._device == 'lp8k' or self._device == 'hx8k'):
            self._device_family = "8k"
        

    def create_yosys(self):

        yosys =  ''
        for f, v in self.dep_map.iteritems():
            yosys_includes = ''
            for i in v:
                if isinstance(i, dict):
                    for options, j in i.iteritems():
                        if options == 'includes':
                            _root = ''
                            _file = ''
                            _root, _file = j[0].rsplit("/", 1)
                            yosys_includes += '-I%s' % _root

            yosys += ('yosys read_verilog -sv %s %s\n' % (yosys_includes , f))
            
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

stat: $(ASC)
	icebox_stat -v $(ASC)

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
