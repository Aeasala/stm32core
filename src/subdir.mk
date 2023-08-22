# Include (all of) the source files of another subdirectory(ies).
#Utilize subdirTemplate

# notation: when a makefile is included, it will (1) appear at the end of $(MAKEFILE_LIST), and (2) run.  convenient!
thisDir = $(dir $(lastword $(MAKEFILE_LIST)))

#-include $(thisDir){folder name goes here}/subdir.mk