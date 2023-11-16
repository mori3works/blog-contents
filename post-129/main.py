# -*- coding:utf-8 -*-

remote_host=    # remote host name or ip address
username=       # connection user
password=       # and its password

from mysshclient import MySSHClient


# Using ssh-agent
ssh = MySSHClient(remote_host, username=username)
motd = ssh.exec_command("")
print(motd)
hint_promptstr = ssh.exec_command("")                                                       # get prompt string by empty line
print(ssh.exec_command("sleep 3 && echo 'Hello, World!'", hint_promptstr=hint_promptstr))   # wait until promtp string appear

ssh.exit()


# Using password
ssh = MySSHClient(remote_host, username=username, password=password)
motd = ssh.exec_command("")
print(motd)
print(ssh.exec_command("sleep 5 && echo 'Hello, World!'", timeout=5.5))

ssh.exit()

