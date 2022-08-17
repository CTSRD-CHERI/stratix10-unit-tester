#!/usr/bin/env python3

import subprocess as sp
import sys, os, time
import re, argparse

default_num_fpgas = 8
quartus_pgm_timeout = 60

def find_de10pro_devices():
    devices = {}
    dev = None
    jtagchain = []
    try:
        proc = sp.run(["jtagconfig"], stdout=sp.PIPE, stderr=sys.stderr, timeout=5, check=True)
    except:
        return {}
    proc_stdout = proc.stdout.decode()
    for line in proc_stdout.split('\n'):
        if(dev==None):
            d = re.match("^(\d+)[\)]\WDE10-Pro\W(\S+)", line)
            if(d != None):
                dev = "DE10-Pro "+d.group(2)
        else:
            jtag = re.match("^\W+(\S+)\W+([\w\(\)\/\.\|]+)", line)
            if(jtag==None):  # end of jtag chain
                devices[dev] = jtagchain
                dev = None
                jtagchain = []
            else:
                jtagchain.append(jtag.groups())
    return devices

def spawn_quartus_pgm(devices,sof,sequential):
    process_list = []
    no_license_env = os.environ.copy()
    no_license_env['LM_LICENSE_FILE']=''
    for d in devices.keys():
        print("usb-to-jtag=", d, " jtag =", devices[d])
        id = 0
        j=0
        for chain in devices[d]:
            j=j+1
            if(re.match("1SX280HH1",chain[1])):
                id=j
        cmd = ['quartus_pgm', '-m', 'jtag', '-c', d, '-o', 'p;%s@%d'%(sof,id)]
        print(' '.join(cmd))
        p=sp.Popen(cmd, stdout=sp.PIPE, stderr=sys.stderr, env=no_license_env)
        process_list.append(p)
        if(sequential):
            p.wait(timeout=quartus_pgm_timeout)
    return process_list

def report_process_status(devices, process_list):
    error_report = {}
    for d in devices.keys():
        error = False
        proc = process_list.pop(0)
        try:
            proc.wait(timeout=quartus_pgm_timeout)
        except:
            print("%s: ERROR: Process programming timed out"%(d))
            error = True
            proc.kill()
        else:
            report=[]
            so = proc.communicate()[0].decode()
            for l in so.split('\n'):
                error = error or re.match("\W+Error", l)
                if(   re.match("Info: Quartus Prime Programmer was", l)
                   or re.match("\W+Info: Elapsed time", l)
                   or re.match("\W+Error", l)):
                    report.append(d+": "+l)
            print('\n'.join(report))
        finally:
            error_report[d] = error
    return error_report

def main():
    global quartus_pgm_timeout
    parser = argparse.ArgumentParser(prog='progallde10pro.py',
                                     description='Program all DE10Pro FPGA boards')
    parser.add_argument('-n', '--numfpga', type=int, action='store', default=default_num_fpgas,
                        help='number of FPGAs in the system (default: %d)'%(default_num_fpgas))
    parser.add_argument('sof', type=str, action='store',
                        help='SOF file to program the FPGA')
    parser.add_argument('-s', '--sequential', action='store_true', default=False,
                        help='program FPGAs sequentially')
    parser.add_argument('-t', '--timeout', type=int, action='store', default=quartus_pgm_timeout,
                        help='quartus_pgm timeout in seconds (default=%ds)'%(quartus_pgm_timeout))
    args = parser.parse_args()
    quartus_pgm_timeout = args.timeout
    if(not(os.path.exists(args.sof))):
        print("SOF file %s does not exist"%(args.sof))
        return(1)

    devices = []
    timeout = 4
    while((len(devices)!=args.numfpga) and (timeout>0)):
        devices = find_de10pro_devices()
        timeout = timeout-1
    if(timeout==0):
        print("Found %d FPGAs but you asked to program %d. Exiting."%(len(devices),args.numfpga))
        return(1)
    if(args.sequential):
        print("Programming sequentially")
    timeout = 4
    any_errors = True
    sequential = args.sequential
    while((timeout>0) and (any_errors)):
        process_list = spawn_quartus_pgm(devices=devices,sof=args.sof,sequential=args.sequential)
        error_report = report_process_status(devices, process_list)
        any_errors = False
        for d in error_report.keys():
            if(error_report[d]):
                print("PROGRAMMING ERROR: FPGA %s failed to program, will retry"%(d))
                any_errors = True
                sequential = True
            else:
                devices.pop(d)
    if(any_errors):
        print("FATAL ERROR: failed to program one or more FPGAs")
    return 1 if any_errors else 0


if __name__ == '__main__':
    start = time.time()
    status = main()
    end = time.time()
    print("Real time: %2.3fs"%(end-start))
    sys.exit(status)
