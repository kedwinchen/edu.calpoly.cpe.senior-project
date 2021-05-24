BIN=handin-to-unix

.PHONY: all
all: clean $(BIN)
	cp -vf $(BIN) /opt/tmp

$(BIN):
	CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' .

.PHONY: clean
clean:
	rm -vf $(BIN)
