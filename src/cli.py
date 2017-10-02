import argparse

class cli(object):
    
    def __init__(self, cmds):
        self.parser = argparse.ArgumentParser(description='A project builder for the ice40')
        parser_sub = self.parser.add_subparsers(dest = 'cmd',
                                                help = "Type the argument name with --help for more detailed help")
        
        for cmd,cls in cmds.iteritems():
            cls.add_cmd(parser_sub, cmd)
        
        self._cmds = cmds
        
    def get_cmd(self):

        arg = self.parser.parse_args()
        cmd_select = self._cmds[arg.cmd]
        
        values = vars(arg)
        
        return cmd_select(**values)

    
