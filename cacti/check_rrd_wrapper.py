#! /usr/bin/env python
# -*- coding: UTF-8 -*-

# check_rrd_wrapper.py
# version - 0.1
# date - 06/Jun/2013
# Francisco Cabrita - <francisco.cabrita@gmail.com>

from __future__ import print_function

import os
import sys
import optparse
import subprocess
from random import choice, randrange
import re

def main():
    check_rrdpl_path = '/servers/scripts/monit/nagios/libexec/thirdparty/contrib/'
    check_rrdpl      = check_rrdpl_path + 'check_rrd.pl'

    parser = optparse.OptionParser()

    parser.add_option('-d', '--directory',    help='RRD Directory',  dest='rrd_dir', default=False, action='store')

    (opts, args) = parser.parse_args()

    mandatories = ['rrd_dir']

    for m in mandatories:
        if not opts.__dict__[m]:
            print('Mandatory options missing')
            parser.print_help()
            exit(-1)

    list = os.listdir(opts.rrd_dir)

    sample_files = []
    for f in list:
        if 'mgm' in f and 'mem_free' in f:
            sample_files.append(f)

    subset = randrange(1, len(sample_files)) 

    media = { 'OK': 0,
            'WARNING': 0,
            'CRITICAL': 0,
            'UNKNOWN': 0, }

    i = 0
    while i <= subset:
        random_index = randrange(0, len(sample_files))
        f = sample_files[random_index]

        rrd_opts = ' --ds mem_free --start -5m --end now --compute=PERCENT --clip-warn-level=01:99 --clip-crit-level=01:99'

        test_rrd = subprocess.Popen(check_rrdpl + ' -R ' + opts.rrd_dir + f + rrd_opts,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                shell=True)
        (stdout, stderr) = test_rrd.communicate()

        match = re.search(r"(\w+) (\w+)", stdout)
        status = match.group(2)

        if 'OK' in status:
            media['OK'] += 1
        elif 'WARNING' in status:
            media['WARNING'] += 1
        elif 'CRITICAL' in status:
            media['CRITICAL'] += 1
        elif ' UNKNOWN' in status:
            media['UNKNOWN'] += 1

        i+=1

    max_stat = max(media, key=media.get)

    return_msg = ''
    exit_code  = 0

    if max_stat == 'OK':
        return_msg = '0 - OK'; exit_code = 0;
    elif max_stat == 'WARNING':
        return_msg = '1 - WARNING'; exit_code = 1;
    elif max_stat == 'CRITICAL':
        return_msg = '2 - CRITICAL'; exit_code = 2;
    elif max_stat == 'UNKNOWN':
        return_msg = '3 - UNKNOWN'; exit_code = 3;

    print(return_msg)
    sys.exit(exit_code)


def which(file):
    for path in os.environ['PATH'].split(':'):
        if os.path.exists(path + '/' + file):
            return path + '/' + file
    return None

    
if __name__ == '__main__':
    main()

