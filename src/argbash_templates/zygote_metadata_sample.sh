
#######################################################################################################
#####=============================== Package/Extension Metadata ===============================#####

NAME="Something-Cool" #Package/Extension Name

CODENAME="your-unique-tag" #An Unique codename

TYPE="Package" #Specify (Package / Extension)

AUTHOR="AXON" #Your name as the Developer/Owner/Packer

VERSION="1.0" #Specify the Version of this package/extension

SHORTDESC="Bakes you a cake @_@" #Provide a short description about this package/extension

C_EXTNAME="" #For Specifing a custom name for your extension script ($NAME is used if not defined)



ARCH=""

DEPENDS=""

REPLACES=""

BREAKS=""

CONFLICTS=""

RECOMMENDS="" || SUGGESTS=""

SECTION=""

Priority=""

INSTALLED_SIZE=""

PROTECTED="" || ESSENTIAL=""

ORIGIN=""

BUGS=""

HOMEPAGE=""

TAGS=""

#####=============================== Package/Extension Metadata ===============================#####
#######################################################################################################




#------------------------------------------------------------------------------------------------------




#######################################################################################################
######=============================== Package/Extension Functions ===============================######

REQSYNC="yes" #(Deafult - yes) To make sure all your files are properly written in disk

REQREBOOT="no, no" #(Deafult - no, no [BOOTED-MODE, RECOVERY-MODE]) Require user to reboot

GEN_UNINS="no" #(Deafult - no) If you want GearLock to generate an uninstallation script itself

SHOW_PROG="yes" #(Default - yes) Whether to show extraction progress while loading the pkg/extension

DEF_HEADER="yes" #(Default - yes) Whether to use the default header which print's the info during zygote

INTERACTIVE="no, no" #(Default - no, no [INSTALL, UNINSTALL]) Additional interactivity in GXPM operation

######=============================== Package/Extension Functions ===============================######
#######################################################################################################




#------------------------------------------------------------------------------------------------------




#######################################################################################################
######======================================= CustomHeader ======================================######
                        #Do not edit this part unless you know what you're doing#
                #Set `DEF_HEADER` to `no' if you want to specify a custom zygote header#
       #Then you can use `geco` or `cat` to print your custom header below for the zygote stage#





######========================================== Header =========================================######
#######################################################################################################
