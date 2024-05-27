poxdir ?= /opt/pox/

# Complete the makefile as you prefer!
topo:
	@echo "starting the topology! (i.e., running mininet)"

app:
	@echo "starting the baseController!"

test:
	@echo "starting test scenarios!"

clean:
	@echo "project files removed from pox directory!"
	sudo mn --link=tc --topo=mytopo
	sudo killall click || true
	sudo kill $(shell sudo lsof -t -i:8080)


