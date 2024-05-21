poxdir ?= /opt/pox
SRC_FILES := $(filter-out $(poxdir)/ext/skeleton.py $(poxdir)/ext/README, $(wildcard $(poxdir)/ext/*))
OUT_LOG_CTRL_PLANE="./results/output_app.txt"
OUT_LOG_TEST_RESULT="./results/output_test.txt"
# OUT_REPORT="./phase_1_report"
OUT_REPORT="./phase_2_report"

# Complete the makefile as you prefer!
topo:
	@echo "starting the topology! (i.e., running mininet)"
	sudo python3 topology/topology.py 

app:
	@echo "starting the baseController!"
	$(poxdir)/pox.py --verbose baseController 2>&1 | tee ${OUT_LOG_CTRL_PLANE} &

ifeq ($(wildcard $(poxdir)/ext/baseController.py),)
app:
	sudo ln -s $(CURDIR)/applications/sdn/*.py $(poxdir)/ext
	sudo chmod -x $(poxdir)/ext/*.py
	ls $(poxdir)/ext
	@make app
endif

test:
	@echo "starting test scenarios!"
	@make app
	sudo python3 topology/topology_test.py 2>&1 | tee ${OUT_LOG_TEST_RESULT} &

report:
	@echo "generating report!"
	echo "Test Result:\n" > ${OUT_REPORT}
	cat ${OUT_LOG_TEST_RESULT} >> ${OUT_REPORT}
	echo "\n\nController Logs:\n" >> ${OUT_REPORT} 
	cat ${OUT_LOG_CTRL_PLANE} >> ${OUT_REPORT}

clean:
	@echo "project files removed from pox directory!"
	sudo mn -c
	@-PID=$$(sudo lsof -t -i:6633); if [ -n "$$PID" ]; then sudo kill -9 $$PID; fi
# @echo "$(SRC_FILES)"
	if [ -n "$(SRC_FILES)" ]; then sudo rm -rf -v $(SRC_FILES); fi
	- find . | grep -E "(__pycache__|.pyc$$)" | sudo xargs rm -rf
# rm -rf -v $(SRC_FILES)
# - rm -rf -v /opt/pox/ext/!(*skeleton.py|README)
# @echo $(CURDIR)