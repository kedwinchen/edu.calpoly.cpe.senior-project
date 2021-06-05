package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"log"
	"math/rand"
	"os"
	"os/exec"
	"strings"
	"syscall"
	"time"

	// "github.com/pkg/sftp"
	"golang.org/x/crypto/ssh"
	// TODO: replace with "golang.org/x/term"
	"golang.org/x/crypto/ssh/terminal"
)

func getCredentials() (username string, password string, err error) {
	reader := bufio.NewReader(os.Stdin)

	fmt.Print("Please enter your Cal Poly username (without the @calpoly.edu): ")
	username, err = reader.ReadString('\n')
	if nil != err {
		log.Println("error while reading username")
		return "", "", err
	}

	fmt.Print("Please enter your Cal Poly password: ")
	passwordBytes, err := terminal.ReadPassword(int(syscall.Stdin))
	if nil != err {
		log.Println("error while reading password")
		return "", "", err
	}
	password = string(passwordBytes)

	fmt.Println()

	return strings.TrimSpace(username), password, nil
}

func connectToVPN(username string, password string) (process *os.Process, err error) {
	log.Println("Connecting to VPN as user '" + username + "'")

	ocCmd := exec.Command("openconnect", "--protocol=gp", "cpvpn.calpoly.edu", "--user="+username, "--passwd-on-stdin")
	ocCmdStdin, err := ocCmd.StdinPipe()
	if err != nil {
		return nil, err
	}

	go func() {
		defer ocCmdStdin.Close()
		io.WriteString(ocCmdStdin, password)
	}()

	err = ocCmd.Start()
	if err != nil {
		return nil, err
	}

	// TODO: determine how to use a variable here
	log.Printf("VPN connection initiated, waiting 1 second(s) for it to become active")
	time.Sleep(1 * time.Second)

	return ocCmd.Process, nil
}

func connectToUnixServer(username string, password string) (connection *ssh.Client, err error) {
	clientConfig := &ssh.ClientConfig{
		User: username,
		Auth: []ssh.AuthMethod{
			ssh.Password(password),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	}

	// Connect to a random random Unix server (attempt to load balance)
	// rand.Intn generates [0, 5), so use + 1 to make the range [1,5]
	rand.Seed(time.Now().Unix()) // otherwise, always results in "unix2.csc.calpoly.edu:22"
	unixServer := fmt.Sprintf("unix%d.csc.calpoly.edu:22", rand.Intn(5)+1)

	log.Println("Will be using the following UNIX server: " + unixServer)

	connection, err = ssh.Dial("tcp", unixServer, clientConfig)
	if err != nil {
		return nil, err
	}

	log.Println("Connected to UNIX server: " + unixServer)

	return connection, nil
}

func processArguments(argv []string) (toUser string, assignment string, filesToHandin []string, err error) {
	if !(len(argv) > 4) {
		return "", "", nil, errors.New("not enough arguments provided")
	}
	toUser = argv[1]
	assignment = argv[2]
	filesToHandin = argv[3:]
	return toUser, assignment, filesToHandin, err
}

func syncFiles(username string, toUser string, assignment string, filesToHandin []string) (tmpDir string, err error) {
	return "", errors.New("not implemented")
}

func doHandin(tmpDir string, toUser string, assignment string, filesToHandin []string) (err error) {
	return errors.New("not implemented")
}

func disconnectFromUnixServer(client *ssh.Client) (err error) {
	log.Println("Disconnecting from UNIX server")
	return client.Close()
}

func disconnectFromVPN(process *os.Process) (err error) {
	log.Println("Disconnecting from Cal Poly VPN")
	return process.Kill()
}

func main() {
	username, password, err := getCredentials()
	if err != nil {
		log.Fatalln(err)
	}

	vpnProcess, err := connectToVPN(username, password)
	if err != nil {
		log.Fatalln(err)
	}

	sshClient, err := connectToUnixServer(username, password)
	if err != nil {
		log.Fatalln(err)
	}

	toUser, assignment, filesToHandin, err := processArguments(os.Args)
	if err != nil {
		log.Fatalln(err)
	}

	tmpDir, err := syncFiles(username, toUser, assignment, filesToHandin)
	if err != nil {
		log.Fatalln(err)
	}

	err = doHandin(tmpDir, toUser, assignment, filesToHandin)
	if err != nil {
		log.Fatalln(err)
	}

	err = disconnectFromUnixServer(sshClient)
	if err != nil {
		log.Fatalln(err)
	}

	err = disconnectFromVPN(vpnProcess)
	if err != nil {
		log.Fatalln(err)
	}
}
