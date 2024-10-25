- [Checking DNS Records](#checking-dns-records)
  - [A Record](#a-record)
  - [AAA Record](#aaa-record)
- [Checking if SSH is available](#checking-if-ssh-is-available)

## Checking DNS Records

### A Record

```
dig EXAMPLE.COM +noall +answer -t A
```

### AAA Record

```
dig EXAMPLE.COM +noall +answer -t AAAA
```

### Checking if SSH is available

```
nc -zv <server_ip_or_hostname> 22
```
