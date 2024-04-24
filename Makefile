poxdir ?= /opt/pox
SRC_FILES := $(filter-out $(poxdir)/ext/skeleton.py $(poxdir)/ext/README, $(wildcard $(poxdir)/ext/*))

# Complete the makefile as you prefer!
topo:
	@echo "starting the topology! (i.e., running mininet)"
	sudo python3 topology/topology.py 

app:
	@echo "starting the baseController!"
	$(poxdir)/pox.py --verbose baseController

ifeq ($(wildcard $(poxdir)/ext/baseController.py),)
app:
	sudo ln -s $(CURDIR)/applications/sdn/*.py $(poxdir)/ext
	sudo chmod -x $(poxdir)/ext/*.py
	ls $(poxdir)/ext
	@make app
endif

test:
	@echo "starting test scenarios!"
	sudo python3 topology/topology_test.py

clean:
	@echo "project files removed from pox directory!"
	sudo mn -c
# @echo "$(SRC_FILES)"
	if [ -n "$(SRC_FILES)" ]; then sudo rm -rf -v $(SRC_FILES); fi
	- find . | grep -E "(__pycache__|.pyc$$)" | xargs rm -rf
# rm -rf -v $(SRC_FILES)
# - rm -rf -v /opt/pox/ext/!(*skeleton.py|README)
# @echo $(CURDIR)
# sudo ln -s $(CURDIR)/applications/sdn/*.py $(poxdir)/ext
# sudo chmod -x $(poxdir)/ext/*.py
# ls $(poxdir)/ext
