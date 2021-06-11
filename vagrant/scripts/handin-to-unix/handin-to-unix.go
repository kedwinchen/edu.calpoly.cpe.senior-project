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

	// consider using the following instead of using fmt.Sprintf("%s/%s", basePath, fileName)
	// documentation at: https://golang.org/pkg/path/filepath/
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"github.com/pkg/sftp"
	"golang.org/x/crypto/ssh"

	// TODO: replace with "golang.org/x/term"
	"golang.org/x/crypto/ssh/terminal"
)

type HandinInfo struct {
	toUser        string
	subDirectory  string
	filesToHandin []string
}

func usage(name string) {
	fmt.Printf("%s touser [ subdirectory [ files ... ] ]\n", name)
	fmt.Println("\t (required) touser: the user to hand the files to")
	fmt.Println("\t (optional) subdirectory: usually this is the name of the assignment.")
	fmt.Println("\t\t if omitted, provides a list of available subdirectories")
	fmt.Println("\t (optional) files: a space-separated list of files to hand in (optional)")
	fmt.Println("\t\t if omitted, provides a list of files already submitted")
	fmt.Println("\t\t this option is only meaningful if a `subdirectory` is specified")
}

func processArguments(argv []string, info *HandinInfo) (err error) {
	var argc int = len(argv)
	if argc < 2 {
		usage(argv[0])
		return errors.New("not enough arguments provided")
	}

	info.toUser = argv[1] // always set this (required)

	if argc >= 3 {
		info.subDirectory = argv[2]
		log.Printf("Using subdirectory '%s' for user '%s'\n", info.subDirectory, info.toUser)

		if argc >= 4 {
			info.filesToHandin = argv[3:]
			log.Printf("Will attempt to hand in the following files: \n'%s'\n", strings.Join(info.filesToHandin, "'\n'"))
		} else {
			info.filesToHandin = nil
			log.Printf("Listing files already handed in to subdirectory '%s' for user '%s' (Not handing in any new files)\n", info.subDirectory, info.toUser)
		}
	} else {
		info.subDirectory = ""
		info.filesToHandin = nil
		log.Printf("Listing available subdirectories for user '%s'\n", info.toUser)
	}

	return nil
}

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

	// NOTE: THIS WILL BREAK if MFA becomes required for VPN login using this method
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
		// TODO: investigate if host key pinning is viable
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

func syncFiles(sshClient *ssh.Client, username string, info *HandinInfo) (syncDir string, err error) {

	if info.filesToHandin == nil {
		log.Println("Skipping file syncing (no files appear to have been provided)")
		return "", nil
	}

	// create the SFTP client using the existing connection
	sftpClient, err := sftp.NewClient(sshClient)
	if err != nil {
		log.Println("Errored in creating SFTP client")
		return "", err
	}

	// create the directory to stage uploaded files for this session
	syncDir = fmt.Sprintf("/home/%s/handin_syncDir/%s/%s/%d", username, info.toUser, info.subDirectory, time.Now().UnixNano())
	err = sftpClient.MkdirAll(syncDir)
	if err != nil {
		log.Printf("Error while creating syncing directory (named '%s') on remote\n", syncDir)
		return "", err
	}
	log.Printf("Using '%s' as the remote directory as destination to sync files", syncDir)

	// sync the files
	log.Printf("Starting file sync to '%s' on remote\n", syncDir)
	for idx, fileName := range info.filesToHandin {

		// Squash subdirectories
		var remoteFileName string = filepath.Base(fileName)
		if remoteFileName != fileName {
			info.filesToHandin[idx] = remoteFileName
		}
		remoteFileName = filepath.Join(syncDir, remoteFileName)

		remoteFile, err := sftpClient.Create(remoteFileName)
		if err != nil {
			log.Printf("Error while creating remote file '%s' in directory '%s': %s\n", fileName, syncDir, err)
		} else {
			defer remoteFile.Close()
			localFile, err := os.Open(fileName) // TODO: ensure that the file is a regular file (probably should do this before creating on remote)
			if err != nil {
				log.Printf("Could not open the local file: '%s'\n", fileName)
			}
			defer localFile.Close()
			_, err = io.Copy(remoteFile, localFile)
			if err != nil {
				log.Printf("Error encountered while coping local file '%s' to '%s' on remote: %s\n", fileName, remoteFileName, err)
			} else {
				log.Printf("OK: '%s' (local) -> '%s' (remote)\n", fileName, remoteFileName)
			}
			remoteFile.Chmod(os.FileMode(0400)) // set the remote file to read-only for archival reasons
		}
	}

	err = sftpClient.Close()
	if err != nil {
		log.Printf("Error while closing SFTP session: %s\n", err)
	}

	log.Printf("Completed file sync to '%s' on remote\n", syncDir)
	// errors while copying files are not fatal
	return syncDir, nil
}

func doHandin(sshClient *ssh.Client, syncDir string, info *HandinInfo) (err error) {
	// prepare handin argv
	var handinCmdStr string = fmt.Sprintf("handin '%s'", info.toUser)

	if len(info.subDirectory) > 0 {
		handinCmdStr += fmt.Sprintf(" '%s'", info.subDirectory)
	}

	if info.filesToHandin != nil {
		for _, fileName := range info.filesToHandin {
			handinCmdStr += fmt.Sprintf(" '%s/%s'", syncDir, fileName)
		}
	}

	// prepare the session
	cmdSession, err := sshClient.NewSession()
	if err != nil {
		log.Println("Error while creating new SSH command session (to perform actual `handin` operation)")
		return err
	}

	// do the actual handin
	log.Printf("Running the command: \n\n%s\n\n", handinCmdStr)
	cmdOutput, err := cmdSession.CombinedOutput(handinCmdStr)
	if err != nil {
		log.Printf("Error while running the command above: %s", err)
		return err
	}
	log.Printf("Output from the command:\n\n%s\n\n", string(cmdOutput))
	return nil
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
	var info HandinInfo

	if err := processArguments(os.Args, &info); err != nil {
		log.Fatalln(err)
	}

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
		// do not be Fatal, still need to clean up!
		log.Println(err)
	} else {
		// only start syncing if successfully connected to the UNIX server
		syncDir, err := syncFiles(sshClient, username, &info)
		if err != nil {
			// do not be Fatal, still need to handin clean up!
			log.Println(err)
		}

		// do handin, even if had issues during sync (hand in what we can)
		err = doHandin(sshClient, syncDir, &info)
		if err != nil {
			// do not be Fatal, still need to clean up!
			log.Println(err)
		}
	}

	err = disconnectFromUnixServer(sshClient)
	if err != nil {
		// do not be Fatal, still need to clean up!
		log.Println(err)
	}

	err = disconnectFromVPN(vpnProcess)
	if err != nil {
		log.Fatalln(err)
	}
}
