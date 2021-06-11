BIN=handin

.PHONY: all
all: clean $(BIN)

$(BIN):
	CGO_ENABLED=0 GOOS=linux go build -o $(BIN) -a -ldflags '-extldflags "-static"' .

.PHONY: clean
clean:
	rm -vf $(BIN) *.sha512sum.sig

.PHONY: release
release: clean $(BIN)
	sha512sum $(BIN) | gpg --sign --sign-with '077B 2354 8CCA 36F9 A833  1803 7B86 0F92 8657 E7F0' --armor | tee $(BIN).sha512sum.sig
