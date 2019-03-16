import os.path
import argparse
import fileinput

if not os.path.exists("DE2Bot_Spring19"):
    exit("*** You don't have the Quartus project in this directory! ***")
if not os.path.exists("Code"):
    exit("*** Cannot find the Code directory! ***")

# Paths for finding source files and destination files
srcPath = "Code/"
destPath = "DE2Bot_Spring19/"
tmpltPath = "Templates/"

# ARGUMENT PARSING #
parser = argparse.ArgumentParser()
parser.add_argument("-v", "--verbose", help="print useful text", action="store_true")
parser.add_argument("filename", help="file containing code to run on the robot")
parser.add_argument("-t", "--template", help="use to specify a different template file from code_template")
parser.add_argument("-d", "--destination", help="use to specify a different destination file from RobotCode")
parser.add_argument("-u", "--usethis", help="add [destination].mif to SCOMP.vhd for easy compiling", action="store_true")
args = parser.parse_args()

verbose = args.verbose

source = args.filename
if not os.path.exists(srcPath + source):
    exit("*** Cannot find the specified source file! ***")

template = args.template
if template is None:
    template = "default_template.asm"
    if verbose:
        print("Using default template (default_template.asm)")
else:
    if template[-4:] != ".asm":
        template += ".asm"
if not os.path.exists(tmpltPath + template):
    exit("*** Cannot find the specified template file! ***")

destination = args.destination
if destination is None:
    destination = "RobotCode.asm"
    if verbose:
        print("Using default destination (RobotCode.asm)")
else:
    if destination[-4:] != ".asm":
        destination += ".asm"

usethis = args.usethis

# READING AND WRITING THE FILES
srcFile = open(srcPath + source)
tmpltFile = open(tmpltPath + template)
destFile = open(destPath + destination, 'w')
if verbose:
    print("Writing to " + destPath + destination)
for t in tmpltFile:
    if "~~~ ADDED CODE ~~~" in t:
        destFile.write(t)
        for s in srcFile:
            destFile.write(s)
    else:
        destFile.write(t)
srcFile.close()
tmpltFile.close()
destFile.close()

if usethis:
    if verbose:
        print("Inserting " + destination + " into SCOMP.vhd")
    scomp = destPath + "SCOMP.vhd"
    for line in fileinput.input(scomp, inplace=True):
        if line == "\n":
            print()
        else:
            if "init_file        =>" in line:
                line = "        init_file        => \"" + destination[:-4] + ".mif\","
            print(line[:-1])
    fileinput.close()
