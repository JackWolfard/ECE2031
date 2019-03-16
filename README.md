# ECE2031
Final DE2Bot Group Project

Place main code files in Code/. Code must be written in `.asm` files. Code files should only include user code.
***DO NOT EDIT `code_template.asm`.***

Download the DE2 project and name the folder DE2Bot_Spring19. This must be put in this project directory (/ECE2031/)

# "Building" the Project
**How this project works**

All user code gets written in `.asm` files in the Code/ directory.
These code files do not contain any given code (such as the movement API).
They only include user subroutines and variables.

Code from the Code/ directory will get injected into a template (which contains all given code) and is put into the Quartus project.
The new file can be compiled using SCASM and uploaded to the robot.

**How to use build.py**

**Note:** This script uses Python 3. Python 2.7 behavior is untested (and probably won't work).

To "build" the project (i.e. inject the code into the template and create a new file), run:

    python3 build.py user_code_filename.asm

This will use the default template (`code_template.asm`) and create the file `RobotCode.asm` in the DE2Bot_Spring19/ directory.
******Remember to compile the assembly with SCASM and then compile the Quartus project before uploading to the robot.***\***

`build.py` has some other useful features. To see a brief overview of them, run:

    python3 build.py -h
    
 Below are more in depth descriptions of each flag and input:
 
    usage: build.py filename [-v] [-t TEMPLATE] [-d DESTINATION] [-u]
    
 * `filename`: The name of the file containing the user code. *Do not include the path (`Code/`) with the filename.*
    The name can contain or omit `.asm`.             
 * `-v, --verbose`: Output what the script is doing.
 * `-t TEMPLATE, --template TEMPLATE`: Specify a different template than the default.
    Allows the user to create a custom template (say, with modified given code) to insert their code in.
     *Do not include the path (`Templates/)` with the filename.*
    The name can contain or omit `.asm`.
     * **Note:** Custom templates should only be used if there is a set up behavior or built-in subroutine that must be changed.
    Other user subroutines should be defined with the user code.
     * Custom templates should be a `.asm` file in the Templates/ directory.
     They must include a line that contains `~~~ ADDED CODE ~~~`.
 *  `-d DESTINATION, --destination DESTINATION`: Specify a different destination file than the default.
    Allows for multiple different user code files to exist in DE2Bot_Spring19/.
    The name can contain or omit `.asm`. You do not need to specify the path with the name.
 * `-u, --usethis`: Inserts `[destination].mif` into SCOMP.vhd as the `init_file` parameter in the memory.
    ***You still need to compile the file with SCASM and compile the Quartus project before you can upload to the robot.***
    This flag is for convenient editing and so you don't forget to change the file name before compiling.