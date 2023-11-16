# -*- coding:utf-8 -*-

import os, re
import time
import paramiko



class MySSHClient():
    BUFFER_SIZE = 65536
    POLLING_INTERVAL_SEC = 0.1
    TIMEOUT_SEC = 1
    #
    def __init__(
            self,
            hostname: str,
            username: str,
            password: str = None,
            privkey_file: str=None,
            privkey_password: str=None,
            input_linesep: str='\n',
            output_linesep: str='\r\n',
            timeout: float=None
        ) -> None:
        self.hostname = hostname
        self.client = paramiko.SSHClient()
        self.client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        self.input_linesep = input_linesep
        self.output_linesep = output_linesep
        self.timeout = timeout if timeout is not None else self.TIMEOUT_SEC
        self.echo_string = None
        #
        if password is not None:
            self._login_with_password(username=username, password=password)
        elif privkey_file is not None:
            self._login_with_privkey(username=username, privkey_file=privkey_file, privkey_pasword=privkey_password)
        else:
            self._login_with_sshagent(username=username)
        self.shell = self.client.invoke_shell()
        pass
    #
    def _login_with_sshagent(self, username: str):
        success = False
        for key in paramiko.agent.Agent().get_keys():
            try:
                self.client.connect(
                    self.hostname,
                    username=username,
                    pkey=key,
                    look_for_keys=False,
                    allow_agent=False
                )
                success = True
                break
            except paramiko.ssh_exception.AuthenticationException as ae:
                continue
        if success:
            pass
        else:
            raise paramiko.ssh_exception.AuthenticationException()
    #
    def _login_with_privkey(self, username: str, privkey_file: str, privkey_password: str=None):
        if privkey_password is not None:
            private_key = paramiko.RSAKey.from_private_key_file(privkey_file, privkey_password)
        else:
            private_key = paramiko.RSAKey.from_private_key_file(privkey_file)
        self.client.connect(
            self.hostname,
            username=username,
            pkey=private_key,
            look_for_keys=False,
            allow_agent=False
        )
        pass
    #
    def _login_with_password(self, username: str, password: str):
        self.client.connect(
            self.hostname,
            username=username,
            password=password,
            look_for_keys=False,
            allow_agent=False
        )
        pass
    #
    def exit(self) -> None:
        if not self.shell.closed:
            self.client.close()
        pass
    #
    def is_active(self) -> bool:
        t = self.client.get_transport()
        if t is None:
            return False
        else:
            return t.is_active()
    #
    def _receive(self, timeout: float=None) -> bytes:
        buffer = b''
        timeout = self.TIMEOUT_SEC if timeout is None else timeout
        # wait until first byte sent
        t = 0
        while not self.shell.recv_ready():
            time.sleep(self.POLLING_INTERVAL_SEC)
            t += self.POLLING_INTERVAL_SEC
            if t > timeout:
                return buffer
        # wait until timeout
        for i in range(0, int(timeout / self.POLLING_INTERVAL_SEC)):
            if self.shell.recv_ready():
                i = 0
                buffer += self.shell.recv(self.BUFFER_SIZE)
            else:
                pass
            time.sleep(self.POLLING_INTERVAL_SEC)
        #
        return buffer
    #
    def _send(self, data: bytes) -> None:
        _ = self.shell.send(data)
        pass
    #
    def receive(self, timeout: float=None, hint_promptstr: str=None) -> str:
        buffer = self._receive(timeout=max(self.TIMEOUT_SEC, timeout if timeout is not None else 0))
        if hint_promptstr is not None:
            while not buffer.decode().endswith(hint_promptstr):
                b = self._receive(timeout=timeout)
                if b != b'':
                    buffer += b
                elif timeout is not None and timeout > 0:
                    break
                else:
                    continue
        #
        data = buffer.decode()
        # trim escape sequence (https://en.wikipedia.org/wiki/ANSI_escape_code#CSIsection)
        data = re.sub(r'\x1b\[[\x30-\x3f]*[\x20-2f]*[\x40-\x7f]', '', data)
        # convert remote-linesep to os.linesep
        data = re.sub(self.output_linesep, "\n", data)
        # trim echoed string
        if self.echo_string is not None:
            if data[0:len(self.echo_string)] == self.echo_string:
                data = data[len(self.echo_string):]
        self.echo_string = None
        return data
    #
    def send(self, data: str) -> None:
        self.echo_string = data
        data = re.sub("\n", self.input_linesep, data)
        self._send(data.encode())
    #
    def exec_command(self, command: str=None, timeout: float=None, hint_promptstr: str=None) -> None:
        if not command.endswith("\n"):
            command += "\n"
        self.send(command)
        return self.receive(timeout=timeout, hint_promptstr=hint_promptstr)

