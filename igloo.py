#!/usr/bin/env python

from src.cli import cli

from src.cmds.create import create

if __name__ == '__main__':

    print("Welcome to igloo...")

    cmds = { 'create' : create}
    
    cli = cli(cmds)
    
    cmd = cli.get_cmd()
    
    print("Finished.")
