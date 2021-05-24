package main

import (
    "bufio"
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
    "golang.org/x/crypto/ssh/terminal"
)

func getCredentials() (username string, password string, err error) {
    reader := bufio.NewReader(os.Stdin)

    fmt.Print("Please enter your Cal Poly username (without the @calpoly.edu): ")
    username, err = reader.ReadString('\n')
    if nil != err {
        // log.Fatal(err)
        return "", "", err
    }

    fmt.Print("Please enter your Cal Poly password: ")
    passwordBytes, err := terminal.ReadPassword(int(syscall.Stdin))
    if nil != err {
        // log.Fatal(err)
        return "", "", err
    }
    password = string(passwordBytes)

    fmt.Println()

    return strings.TrimSpace(username), password, nil
}

func connectToVPN(username string, password string) (process *os.Process, err error) {
    log.Println("Connecting to VPN as user '" + username + "'")

    ocCmd := exec.Command("openconnect", "--protocol=gp", "cpvpn.calpoly.edu", "--user=" + username, "--passwd-on-stdin")
    ocCmdStdin, err := ocCmd.StdinPipe()
    if err != nil {
        log.Fatal(err)
    }

    go func() {
        defer ocCmdStdin.Close()
        io.WriteString(ocCmdStdin, password)
    }()

    err = ocCmd.Start()
    if err != nil {
        log.Fatal(err)
    }

    log.Println("VPN connection initiated, waiting 3 seconds for it to become active")
    time.Sleep(3 * time.Second)

    return ocCmd.Process, nil
}

func connectToUnixServer(username string, password string) (connection *ssh.Client, err error) {
    clientConfig := &ssh.ClientConfig {
        User: username,
        Auth: []ssh.AuthMethod {
            ssh.Password(password),
        },
        HostKeyCallback: ssh.InsecureIgnoreHostKey(),
    }

    log.Println("Username: " + username)
    log.Println("Password: " + password)

    // Connect to a random random Unix server (attempt to load balance)
    // rand.Intn generates [0, 5), so use + 1 to make the range [1,5]
    unixServer := fmt.Sprintf("unix%d.csc.calpoly.edu:22", rand.Intn(5) + 1)

    log.Println("Will be using the following UNIX server: " + unixServer)

    connection, err = ssh.Dial("tcp", unixServer, clientConfig)
    if err != nil {
        log.Fatal(err)
    }

    log.Println("Connected to UNIX server: " + unixServer)

    return connection, err
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
    username, password, _ := getCredentials()
    vpnProcess, _ := connectToVPN(username, password)

    c, _ := exec.Command("ip", "route", "get", "129.65.128.83").CombinedOutput()
    fmt.Printf("%s\n", c)
    c, _ = exec.Command("ip", "route", "get", "192.168.56.1").CombinedOutput()
    fmt.Printf("%s\n", c)

    sshClient, _ := connectToUnixServer(username, password)
    // toUser, assignment, filesToHandin = processArguments()
    // syncFiles(username, filesToHandin)
    // doHandin(toUser, assignment, filesToHandin)
    // cleanupRemoteFiles(sshClient, filesToHandin)
    _ = disconnectFromUnixServer(sshClient)
    _ = disconnectFromVPN(vpnProcess)
}
